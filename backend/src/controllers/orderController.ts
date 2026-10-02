import { Response, NextFunction } from 'express';
import { prisma } from '../config/db';
import { AuthenticatedRequest } from '../middlewares/authMiddleware';
import { calculateHaversineDistance } from '../utils/distance';
import { razorpay } from '../config/razorpay';
import { FulfillmentType, PaymentMethod, PaymentStatus, OrderStatus } from '@prisma/client';
import { NotificationService } from '../services/notificationService';
import { generateNextOrderNumber } from '../utils/orderNumber';
import { AppError } from '../utils/errors';
import { claimOrderStatus, restoreOrderStock, ORDER_STATUS_CHANGED } from '../services/inventoryService';
import { getParam } from '../utils/request';

export class OrderController {
  /**
   * Transactional Order Creation and Checkout.
   */
  static async createOrder(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    const userId = req.user?.id;
    if (!userId) {
      res.status(401).json({
        success: false,
        message: 'Unauthorized.',
        errorCode: 'UNAUTHORIZED',
      });
      return;
    }

    const { fulfillmentType, addressId, storeId, paymentMethod, items } = req.body;

    if (!fulfillmentType || !paymentMethod || !items || !Array.isArray(items) || items.length === 0) {
      res.status(400).json({
        success: false,
        message: 'Fulfillment type, payment method, and items are required.',
        errorCode: 'MISSING_PARAMETERS',
      });
      return;
    }

    if (paymentMethod !== 'COD' && paymentMethod !== 'ONLINE') {
      res.status(400).json({
        success: false,
        message: 'Payment method must be COD or ONLINE.',
        errorCode: 'INVALID_PAYMENT_METHOD',
      });
      return;
    }

    try {
      // Execute entire order creation within a database transaction
      const result = await prisma.$transaction(async (tx) => {
        let assignedStoreId = storeId;
        let calculatedDeliveryFee = 0.00;

        // 1. Load system configurations
        const deliverySettings = await tx.deliverySettings.findFirst();
        const configDeliveryFee = deliverySettings ? Number(deliverySettings.deliveryFee) : 30.00;
        const configFreeThreshold = deliverySettings ? Number(deliverySettings.freeDeliveryThreshold) : 499.00;
        const configMinDeliveryOrder = deliverySettings ? Number(deliverySettings.minimumOrderAmount) : 199.00;
        const configCodCharge = deliverySettings ? Number(deliverySettings.codCharge) : 20.00;
        const configMinCodOrder = deliverySettings ? Number(deliverySettings.minimumCodOrderAmount) : 100.00;
        const configMaxCodOrder = deliverySettings ? Number(deliverySettings.maximumCodOrderAmount) : 5000.00;

        // 2. Fulfillment checks
        if (fulfillmentType === 'DELIVERY') {
          // Check if delivery is enabled
          if (deliverySettings && deliverySettings.deliveryEnabled === false) {
            throw new Error('DELIVERY_DISABLED');
          }

          if (!addressId) {
            throw new AppError(400, 'MISSING_ADDRESS_ID', 'Address ID is required for delivery fulfillment.');
          }

          // Fetch Address coordinates
          const address = await tx.userAddress.findUnique({
            where: { id: addressId },
          });

          if (!address || address.userId !== userId) {
            throw new AppError(404, 'ADDRESS_NOT_FOUND', 'Delivery address not found.');
          }

          const clientLat = Number(address.latitude);
          const clientLng = Number(address.longitude);

          // Find active stores
          const activeStores = await tx.store.findMany({
            where: { isActive: true },
          });

          // Calculate proximity and find nearest eligible store
          let nearestStore = null;
          let minDistance = Infinity;

          for (const store of activeStores) {
            const distance = calculateHaversineDistance(
              clientLat,
              clientLng,
              Number(store.latitude),
              Number(store.longitude)
            );

            if (distance <= Number(store.deliveryRadiusKm)) {
              if (distance < minDistance) {
                minDistance = distance;
                nearestStore = store;
              }
            }
          }

          if (!nearestStore) {
            // Throw unique error text to signal out of bounds location to client
            throw new Error('NO_DELIVERY_AVAILABLE');
          }

          assignedStoreId = nearestStore.id;
        } else if (fulfillmentType === 'PICKUP') {
          if (!assignedStoreId) {
            throw new AppError(400, 'MISSING_STORE_ID', 'Store ID is required for pickup fulfillment.');
          }

          const store = await tx.store.findUnique({
            where: { id: assignedStoreId },
          });

          if (!store || !store.isActive) {
            throw new AppError(400, 'STORE_UNAVAILABLE', 'Selected store is inactive or unavailable.');
          }
        } else {
          throw new AppError(400, 'INVALID_FULFILLMENT_TYPE', 'Invalid fulfillment type.');
        }

        // 3. Process products & inventories
        let subtotal = 0.00;
        const orderItemsToCreate = [];

        for (const item of items) {
          const { productId, quantity } = item;
          const qtyVal = parseFloat(quantity);

          if (isNaN(qtyVal) || qtyVal <= 0) {
            throw new AppError(400, 'INVALID_QUANTITY', 'Quantity must be a positive decimal.');
          }

          // Get global product details
          const product = await tx.product.findUnique({
            where: { id: productId },
            include: { category: true },
          });

          if (!product || !product.isActive || !product.category.isActive) {
            throw new AppError(400, 'PRODUCT_UNAVAILABLE', `Product with ID ${productId} is not available.`);
          }

          // Load current inventory to perform CAS update and transaction log
          const currentInv = await tx.storeInventory.findUnique({
            where: {
              storeId_productId: { storeId: assignedStoreId, productId },
            },
          });

          const prevStock = currentInv ? Number(currentInv.stockQuantity) : 0;

          if (!currentInv || !currentInv.isAvailable || prevStock < qtyVal) {
            throw new Error(`INSUFFICIENT_STOCK:${product.name}:${prevStock}:${product.unit}`);
          }

          const newStock = prevStock - qtyVal;

          const updateCount = await tx.storeInventory.updateMany({
            where: {
              storeId: assignedStoreId,
              productId,
              isAvailable: true,
              stockQuantity: prevStock, // CAS check
            },
            data: {
              stockQuantity: newStock,
            },
          });

          if (updateCount.count === 0) {
            throw new AppError(409, 'CONCURRENCY_ERROR', 'Stock changed while placing the order. Please try again.');
          }

          // Create inventory transaction record
          await tx.inventoryTransaction.create({
            data: {
              storeId: assignedStoreId,
              productId,
              previousQuantity: prevStock,
              changeQuantity: -qtyVal,
              newQuantity: newStock,
              type: 'ORDER_DEDUCTION',
              reason: 'Checkout stock deduction',
            },
          });

          const itemPrice = Number(product.price);
          const totalItemPrice = parseFloat((qtyVal * itemPrice).toFixed(2));
          subtotal = parseFloat((subtotal + totalItemPrice).toFixed(2));

          orderItemsToCreate.push({
            productId,
            productName: product.name,
            unit: product.unit,
            quantity: qtyVal,
            unitPrice: itemPrice,
            totalPrice: totalItemPrice,
          });
        }

        // 4. Validate Delivery minimum order amount & Calculate Delivery Fee
        if (fulfillmentType === 'DELIVERY') {
          if (subtotal < configMinDeliveryOrder) {
            throw new Error(`MINIMUM_DELIVERY_AMOUNT_NOT_MET:${configMinDeliveryOrder}`);
          }

          if (subtotal >= configFreeThreshold) {
            calculatedDeliveryFee = 0.00;
          } else {
            calculatedDeliveryFee = configDeliveryFee;
          }
        } else if (fulfillmentType === 'PICKUP') {
          calculatedDeliveryFee = 0.00;
        }

        // 5. Validate COD & Calculate COD charge
        let calculatedCodCharge = 0.00;
        if (paymentMethod === 'COD') {
          if (deliverySettings && !deliverySettings.codEnabled) {
            throw new Error('COD_DISABLED');
          }

          if (fulfillmentType === 'PICKUP' && deliverySettings && !deliverySettings.pickupCodEnabled) {
            throw new Error('PICKUP_COD_DISABLED');
          }

          if (subtotal < configMinCodOrder) {
            throw new Error(`MINIMUM_COD_AMOUNT_NOT_MET:${configMinCodOrder}`);
          }

          if (subtotal > configMaxCodOrder) {
            throw new Error(`MAXIMUM_COD_AMOUNT_EXCEEDED:${configMaxCodOrder}`);
          }

          calculatedCodCharge = configCodCharge;
        } else if (paymentMethod === 'ONLINE') {
          calculatedCodCharge = 0.00;
        }

        const grandTotal = parseFloat((subtotal + calculatedDeliveryFee + calculatedCodCharge).toFixed(2));

        // 6. Generate standardized Order Number (Format: #UB-DDMMYY-XXX)
        const orderNumber = await generateNextOrderNumber(tx);

        // 7. Create Order record
        const order = await tx.order.create({
          data: {
            orderNumber,
            userId,
            storeId: assignedStoreId,
            fulfillmentType: fulfillmentType as FulfillmentType,
            addressId: fulfillmentType === 'DELIVERY' ? addressId : null,
            subtotal,
            deliveryFee: calculatedDeliveryFee,
            codCharge: calculatedCodCharge,
            total: grandTotal,
            paymentMethod: paymentMethod as PaymentMethod,
            paymentStatus: PaymentStatus.PENDING,
            orderStatus: OrderStatus.PLACED,
          },
        });

        // Create Order Items
        await tx.orderItem.createMany({
          data: orderItemsToCreate.map((item) => ({
            orderId: order.id,
            productId: item.productId,
            productName: item.productName,
            unit: item.unit,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            totalPrice: item.totalPrice,
          })),
        });

        // 8. Initialize Razorpay Order if payment mode is ONLINE
        let razorpayOrder = null;
        if (paymentMethod === 'ONLINE') {
          // Amount in paisa
          const amountInPaisa = Math.round(grandTotal * 100);

          try {
            razorpayOrder = await razorpay.orders.create({
              amount: amountInPaisa,
              currency: 'INR',
              receipt: order.id,
            });

            // Save pending payment details linked to order
            await tx.payment.create({
              data: {
                orderId: order.id,
                razorpayOrderId: razorpayOrder.id,
                amount: grandTotal,
                status: 'created',
              },
            });
          } catch (rpErr) {
            console.error('Razorpay Order Creation Failed:', rpErr);
            throw new Error('RAZORPAY_INITIALIZATION_FAILED');
          }
        }

        // 9. Delete user cart items since they have checked out
        await tx.cartItem.deleteMany({
          where: { userId },
        });

        // 10. Write audit log
        await tx.auditLog.create({
          data: {
            action: 'CREATE_ORDER',
            details: `Created order: ${orderNumber} for user ID: ${userId}, total: ${grandTotal}`,
          },
        });

        return { order, razorpayOrder };
      });

      // Asynchronously trigger notification dispatch to assigned store managers
      NotificationService.sendToStoreManagers(
        result.order.storeId,
        'New Order Received',
        `Order ${result.order.orderNumber} for ₹${result.order.total} requires processing.`,
        { orderId: result.order.id, orderNumber: result.order.orderNumber }
      ).catch((err) => console.error('Error sending order notification to managers:', err));

      res.status(201).json({
        success: true,
        message: 'Order created successfully.',
        data: {
          order: {
            id: result.order.id,
            orderNumber: result.order.orderNumber,
            fulfillmentType: result.order.fulfillmentType,
            subtotal: Number(result.order.subtotal),
            deliveryFee: Number(result.order.deliveryFee),
            codCharge: Number(result.order.codCharge),
            total: Number(result.order.total),
            paymentMethod: result.order.paymentMethod,
            paymentStatus: result.order.paymentStatus,
            orderStatus: result.order.orderStatus,
          },
          razorpayOrder: result.razorpayOrder,
        },
      });
    } catch (error: any) {
      if (error.message === 'DELIVERY_DISABLED') {
        res.status(400).json({
          success: false,
          message: 'Delivery orders are currently unavailable.',
          errorCode: 'DELIVERY_DISABLED',
        });
        return;
      }

      if (error.message.startsWith('MINIMUM_DELIVERY_AMOUNT_NOT_MET')) {
        const minAmt = error.message.split(':')[1] || '199';
        res.status(400).json({
          success: false,
          message: `Minimum delivery order amount is ₹${minAmt}.`,
          errorCode: 'MINIMUM_DELIVERY_AMOUNT_NOT_MET',
        });
        return;
      }

      if (error.message === 'COD_DISABLED') {
        res.status(400).json({
          success: false,
          message: 'Cash on Delivery is currently unavailable.',
          errorCode: 'COD_DISABLED',
        });
        return;
      }

      if (error.message === 'PICKUP_COD_DISABLED') {
        res.status(400).json({
          success: false,
          message: 'Cash on Delivery is not available for pickup orders.',
          errorCode: 'PICKUP_COD_DISABLED',
        });
        return;
      }

      if (error.message.startsWith('MINIMUM_COD_AMOUNT_NOT_MET')) {
        const minCod = error.message.split(':')[1] || '100';
        res.status(400).json({
          success: false,
          message: `COD is available only for orders of ₹${minCod} or more.`,
          errorCode: 'MINIMUM_COD_AMOUNT_NOT_MET',
        });
        return;
      }

      if (error.message.startsWith('MAXIMUM_COD_AMOUNT_EXCEEDED')) {
        const maxCod = error.message.split(':')[1] || '5000';
        res.status(400).json({
          success: false,
          message: `COD is available only for orders up to ₹${Number(maxCod).toLocaleString('en-IN')}.`,
          errorCode: 'MAXIMUM_COD_AMOUNT_EXCEEDED',
        });
        return;
      }

      if (error.message === 'NO_DELIVERY_AVAILABLE') {
        res.status(400).json({
          success: false,
          message: 'No delivery available at your location.',
          errorCode: 'NO_DELIVERY_AVAILABLE',
        });
        return;
      }

      if (error.message.startsWith('INSUFFICIENT_STOCK')) {
        const parts = error.message.split(':');
        res.status(400).json({
          success: false,
          message: `Insufficient stock for product ${parts[1]}. Only ${parts[2]} ${parts[3]} available.`,
          errorCode: 'INSUFFICIENT_STOCK',
        });
        return;
      }

      if (error.message === 'RAZORPAY_INITIALIZATION_FAILED') {
        res.status(500).json({
          success: false,
          message: 'Failed to initialize payment gateway. Please try again.',
          errorCode: 'PAYMENT_GATEWAY_ERROR',
        });
        return;
      }

      next(error);
    }
  }

  /**
   * Fetch customer order history.
   */
  static async getOrders(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user?.id;
      
      const orders = await prisma.order.findMany({
        where: { userId },
        include: {
          store: {
            select: { name: true, storeId: true },
          },
          items: {
            include: {
              product: {
                select: { name: true, unit: true, imageUrl: true },
              },
            },
          },
        },
        orderBy: { createdAt: 'desc' },
      });

      res.status(200).json({
        success: true,
        data: orders,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Fetch specific order details.
   */
  static async getOrderById(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = getParam(req, 'id');
      const userId = req.user?.id;

      const order = await prisma.order.findUnique({
        where: { id },
        include: {
          store: {
            select: { name: true, address: true, storeId: true },
          },
          items: {
            include: {
              product: {
                select: { name: true, unit: true, imageUrl: true },
              },
            },
          },
          address: true,
        },
      });

      if (!order || (req.user?.role === 'customer' && order.userId !== userId)) {
        res.status(404).json({
          success: false,
          message: 'Order not found.',
          errorCode: 'ORDER_NOT_FOUND',
        });
        return;
      }

      // Enforce store isolation for Store Managers
      if (req.user?.role === 'STORE_MANAGER' && order.storeId !== req.user.storeId) {
        res.status(403).json({
          success: false,
          message: 'Access Denied. You do not have permissions to view orders for another store.',
          errorCode: 'STORE_ACCESS_FORBIDDEN',
        });
        return;
      }

      res.status(200).json({
        success: true,
        data: order,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Cancel Order.
   */
  static async cancelOrder(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = getParam(req, 'id');
      const userId = req.user?.id;

      const order = await prisma.order.findUnique({
        where: { id },
      });

      if (!order || (req.user?.role === 'customer' && order.userId !== userId)) {
        res.status(404).json({
          success: false,
          message: 'Order not found.',
          errorCode: 'ORDER_NOT_FOUND',
        });
        return;
      }

      // Customers can only cancel if status is PLACED
      if (req.user?.role === 'customer' && order.orderStatus !== OrderStatus.PLACED) {
        res.status(400).json({
          success: false,
          message: 'Cannot cancel order once it has been confirmed or prepared.',
          errorCode: 'INVALID_ORDER_STATE_FOR_CANCELLATION',
        });
        return;
      }

      // Perform cancellation in transaction to restore inventory stock
      if (order.orderStatus === OrderStatus.CANCELLED) {
        res.status(400).json({
          success: false,
          message: 'Order is already cancelled.',
          errorCode: 'ORDER_ALREADY_CANCELLED',
        });
        return;
      }

      const cancelledOrder = await prisma.$transaction(async (tx) => {
        // P0-06: claim the cancellation first so concurrent requests cannot restore stock twice
        const updated = await claimOrderStatus(tx, id, order.orderStatus, OrderStatus.CANCELLED);

        await restoreOrderStock(tx, {
          orderId: id,
          storeId: order.storeId,
          reason: `Order cancellation restore for order: ${order.orderNumber}`,
          performedByAdminId: req.user?.role === 'SUPER_ADMIN' || req.user?.role === 'STORE_MANAGER' ? req.user.id : null,
        });

        // Log audit
        await tx.auditLog.create({
          data: {
            action: 'CANCEL_ORDER',
            details: `Cancelled order: ${order.orderNumber}, restored inventory.`,
          },
        });

        return updated;
      });

      // Asynchronously notify user of order cancellation
      NotificationService.sendToUser(
        order.userId,
        'Order Cancelled',
        `Your order ${order.orderNumber} has been successfully cancelled.`,
        { orderId: order.id, status: 'CANCELLED' }
      ).catch((err) => console.error('Error sending cancellation notification to customer:', err));

      res.status(200).json({
        success: true,
        message: 'Order cancelled successfully.',
        data: cancelledOrder,
      });
    } catch (error: any) {
      if (error?.message === ORDER_STATUS_CHANGED) {
        res.status(409).json({
          success: false,
          message: 'Order status was changed by another request. Please refresh and try again.',
          errorCode: 'ORDER_STATUS_CONFLICT',
        });
        return;
      }
      next(error);
    }
  }
}
