import { Response, NextFunction } from 'express';
import { prisma } from '../config/db';
import { AuthenticatedRequest } from '../middlewares/authMiddleware';
import { OrderStatus, PaymentStatus } from '@prisma/client';
import { NotificationService } from '../services/notificationService';
import { getParam } from '../utils/request';

const ALLOWED_PAYMENT_STATUSES: PaymentStatus[] = [
  PaymentStatus.PENDING,
  PaymentStatus.PAID,
  PaymentStatus.FAILED,
];

export class AdminOrderController {
  /**
   * Fetch Orders list for Admin Dashboard with search, filter, and pagination.
   * Super Admin sees all stores (filterable by storeId).
   * Store Manager sees ONLY their assigned store ID.
   */
  static async getOrders(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const { role, storeId: managerStoreId } = req.user!;
      const {
        storeId: queryStoreId,
        status,
        fulfillment,
        paymentStatus,
        search,
        page: queryPage,
        limit: queryLimit,
      } = req.query;

      let targetStoreId: string | undefined = undefined;

      if (role === 'STORE_MANAGER') {
        targetStoreId = managerStoreId;
      } else if (role === 'SUPER_ADMIN') {
        targetStoreId = queryStoreId ? (queryStoreId as string) : undefined;
      }

      const whereClause: any = {};

      if (targetStoreId) {
        whereClause.storeId = targetStoreId;
      }
      if (status) {
        whereClause.orderStatus = status as OrderStatus;
      }
      if (fulfillment) {
        whereClause.fulfillmentType = fulfillment as any;
      }
      if (paymentStatus) {
        if (!ALLOWED_PAYMENT_STATUSES.includes(paymentStatus as PaymentStatus)) {
          res.status(400).json({
            success: false,
            message: 'Invalid payment status filter. Supported statuses are PENDING, PAID, and FAILED.',
            errorCode: 'INVALID_PAYMENT_STATUS',
          });
          return;
        }
        whereClause.paymentStatus = paymentStatus as PaymentStatus;
      }

      if (search && typeof search === 'string' && search.trim()) {
        const searchStr = search.trim();
        whereClause.OR = [
          { orderNumber: { contains: searchStr, mode: 'insensitive' } },
          { user: { name: { contains: searchStr, mode: 'insensitive' } } },
          { user: { phone: { contains: searchStr, mode: 'insensitive' } } },
        ];
      }

      const page = queryPage ? parseInt(queryPage as string) : 1;
      const limit = queryLimit ? parseInt(queryLimit as string) : 10;
      const skip = (page - 1) * limit;

      const totalCount = await prisma.order.count({ where: whereClause });

      const orders = await prisma.order.findMany({
        where: whereClause,
        skip: queryPage || queryLimit ? skip : undefined,
        take: queryPage || queryLimit ? limit : undefined,
        include: {
          user: {
            select: { id: true, name: true, phone: true, email: true },
          },
          store: {
            select: { id: true, name: true, storeId: true },
          },
        },
        orderBy: { createdAt: 'desc' },
      });

      if (queryPage || queryLimit) {
        res.status(200).json({
          success: true,
          data: {
            orders,
            pagination: {
              total: totalCount,
              page,
              limit,
              totalPages: Math.ceil(totalCount / limit),
            },
          },
        });
      } else {
        res.status(200).json({
          success: true,
          data: orders,
        });
      }
    } catch (error) {
      next(error);
    }
  }

  /**
   * Fetch complete order details for Admin panel view.
   * Enforces store isolation checks for Store Managers.
   */
  static async getOrderDetails(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = getParam(req, 'id');
      const { role, storeId: managerStoreId } = req.user!;

      const order = await prisma.order.findUnique({
        where: { id },
        include: {
          user: { select: { id: true, name: true, phone: true, email: true } },
          store: { select: { id: true, name: true, storeId: true, address: true, phone: true } },
          address: true,
          items: {
            include: {
              product: { select: { name: true, unit: true, imageUrl: true } },
            },
          },
          payments: true,
        },
      });

      if (!order) {
        res.status(404).json({
          success: false,
          message: 'Order not found.',
          errorCode: 'ORDER_NOT_FOUND',
        });
        return;
      }

      if (role === 'STORE_MANAGER' && order.storeId !== managerStoreId) {
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
   * Update Order Status endpoint.
   * Validates state machine transitions and enforces store isolation checks for Store Managers.
   */
  static async updateOrderStatus(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = getParam(req, 'id');
      const { status } = req.body;
      const { role, storeId: managerStoreId } = req.user!;

      if (!status || !Object.values(OrderStatus).includes(status)) {
        res.status(400).json({
          success: false,
          message: 'Invalid order status value provided.',
          errorCode: 'INVALID_STATUS',
        });
        return;
      }

      const order = await prisma.order.findUnique({
        where: { id },
      });

      if (!order) {
        res.status(404).json({
          success: false,
          message: 'Order not found.',
          errorCode: 'ORDER_NOT_FOUND',
        });
        return;
      }

      // Enforce store-level isolation check
      if (role === 'STORE_MANAGER' && order.storeId !== managerStoreId) {
        res.status(403).json({
          success: false,
          message: 'Access Denied. You are not authorized to update status for another store\'s orders.',
          errorCode: 'STORE_ACCESS_FORBIDDEN',
        });
        return;
      }

      // Enforce state transition safety
      const VALID_TRANSITIONS: Record<OrderStatus, OrderStatus[]> = {
        [OrderStatus.PLACED]: [OrderStatus.CONFIRMED, OrderStatus.CANCELLED],
        [OrderStatus.CONFIRMED]: [OrderStatus.PREPARING, OrderStatus.CANCELLED],
        [OrderStatus.PREPARING]: [OrderStatus.READY_FOR_PICKUP, OrderStatus.OUT_FOR_DELIVERY, OrderStatus.CANCELLED],
        [OrderStatus.READY_FOR_PICKUP]: [OrderStatus.OUT_FOR_DELIVERY, OrderStatus.PICKED_UP, OrderStatus.CANCELLED],
        [OrderStatus.OUT_FOR_DELIVERY]: [OrderStatus.DELIVERED, OrderStatus.CANCELLED],
        [OrderStatus.DELIVERED]: [],
        [OrderStatus.PICKED_UP]: [],
        [OrderStatus.CANCELLED]: [],
      };

      if (order.orderStatus !== status) {
        const allowed = VALID_TRANSITIONS[order.orderStatus] || [];
        if (!allowed.includes(status as OrderStatus)) {
          res.status(400).json({
            success: false,
            message: `Invalid order status transition from ${order.orderStatus} to ${status}.`,
            errorCode: 'INVALID_STATUS_TRANSITION',
          });
          return;
        }
      }

      // Perform update in transaction
      const updated = await prisma.$transaction(async (tx) => {
        let paymentStatusUpdate: PaymentStatus | undefined = undefined;
        if (status === OrderStatus.DELIVERED || status === OrderStatus.PICKED_UP) {
          paymentStatusUpdate = PaymentStatus.PAID;
        }

        // If cancelling order, restore inventory stock and log transaction
        if (status === OrderStatus.CANCELLED) {
          const items = await tx.orderItem.findMany({ where: { orderId: id } });
          for (const item of items) {
            const currentInv = await tx.storeInventory.findUnique({
              where: { storeId_productId: { storeId: order.storeId, productId: item.productId } },
            });
            const prevStock = currentInv ? Number(currentInv.stockQuantity) : 0;
            const newStock = prevStock + Number(item.quantity);

            await tx.storeInventory.update({
              where: { storeId_productId: { storeId: order.storeId, productId: item.productId } },
              data: { stockQuantity: newStock },
            });

            await tx.inventoryTransaction.create({
              data: {
                storeId: order.storeId,
                productId: item.productId,
                previousQuantity: prevStock,
                changeQuantity: Number(item.quantity),
                newQuantity: newStock,
                type: 'ORDER_CANCELLATION_RESTORE',
                reason: `Admin order cancellation for order: ${order.orderNumber}`,
                performedByAdminId: req.user?.id,
              },
            });
          }
        }

        const orderUpdate = await tx.order.update({
          where: { id },
          data: {
            orderStatus: status as OrderStatus,
            paymentStatus: paymentStatusUpdate,
            updatedAt: new Date(),
          },
        });

        await tx.auditLog.create({
          data: {
            adminUserId: req.user?.id,
            action: 'UPDATE_ORDER_STATUS',
            details: `Updated order status of ${order.orderNumber} to ${status}`,
          },
        });

        return orderUpdate;
      });

      // Asynchronously trigger customer notification on order status change
      NotificationService.sendToUser(
        updated.userId,
        'Order Status Update',
        `Your order ${order.orderNumber} has been updated to: ${status}.`,
        { orderId: updated.id, status: updated.orderStatus }
      ).catch((err) => console.error('Error sending status update notification to customer:', err));

      res.status(200).json({
        success: true,
        message: 'Order status updated successfully.',
        data: updated,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Verification & Handover for Store Pickup Orders.
   * Search by Order ID (orderNumber) + Registered Mobile Number.
   * Enforces store isolation checks for Store Managers.
   */
  static async verifyPickup(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const { orderNumber, phone } = req.body;
      const { role, storeId: managerStoreId } = req.user!;

      if (!orderNumber || !phone) {
        res.status(400).json({
          success: false,
          message: 'Order number and registered mobile number are required.',
          errorCode: 'MISSING_PARAMETERS',
        });
        return;
      }

      const order = await prisma.order.findFirst({
        where: {
          orderNumber,
          user: { phone },
          fulfillmentType: 'PICKUP',
        },
        include: {
          user: { select: { name: true, phone: true } },
          items: {
            include: {
              product: { select: { name: true, unit: true } },
            },
          },
        },
      });

      if (!order) {
        res.status(404).json({
          success: false,
          message: 'Order not found or registered mobile number mismatch.',
          errorCode: 'PICKUP_ORDER_NOT_FOUND',
        });
        return;
      }

      // Enforce store-level isolation check
      if (role === 'STORE_MANAGER' && order.storeId !== managerStoreId) {
        res.status(403).json({
          success: false,
          message: 'Access Denied. You are not authorized to verify pickup orders for another store.',
          errorCode: 'STORE_ACCESS_FORBIDDEN',
        });
        return;
      }

      // If online order has pending/unpaid payment, block handover
      if (order.paymentMethod === 'ONLINE' && order.paymentStatus !== PaymentStatus.PAID) {
        res.status(400).json({
          success: false,
          message: 'Cannot handover order. Online payment is pending or has failed.',
          errorCode: 'ONLINE_PAYMENT_PENDING',
        });
        return;
      }

      // Mark order as PICKED_UP and update payment status for COD orders
      const updated = await prisma.$transaction(async (tx) => {
        const orderUpdate = await tx.order.update({
          where: { id: order.id },
          data: {
            orderStatus: OrderStatus.PICKED_UP,
            paymentStatus: PaymentStatus.PAID, // Sets COD to PAID, keeps ONLINE as PAID
            updatedAt: new Date(),
          },
        });

        // Write audit log inside transaction with cash collection details
        const auditDetails = order.paymentMethod === 'COD'
          ? `Collected cash and verified pickup handover for COD order: ${order.orderNumber}`
          : `Handover verified and marked PICKED_UP for prepaid online order: ${order.orderNumber}`;

        await tx.auditLog.create({
          data: {
            adminUserId: req.user?.id,
            action: 'VERIFY_PICKUP_HANDOVER',
            details: auditDetails,
          },
        });

        return orderUpdate;
      });

      // Asynchronously trigger customer notification on successful pickup handover
      NotificationService.sendToUser(
        order.userId,
        'Order Handover Verified',
        `Your order ${order.orderNumber} has been successfully verified and picked up.`,
        { orderId: order.id, status: 'PICKED_UP' }
      ).catch((err) => console.error('Error sending pickup handover notification to customer:', err));

      res.status(200).json({
        success: true,
        message: 'Handover verified. Order status updated to PICKED_UP.',
        data: {
          id: order.id,
          orderNumber: order.orderNumber,
          customerName: order.user.name || 'User',
          phone: order.user.phone,
          items: order.items.map(item => ({
            name: item.product.name,
            quantity: Number(item.quantity),
            unit: item.product.unit,
          })),
          subtotal: Number(order.subtotal),
          total: Number(order.total),
          orderStatus: updated.orderStatus,
          paymentStatus: updated.paymentStatus,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Fetch current delivery and COD configurations.
   */
  static async getDeliverySettings(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const settings = await prisma.deliverySettings.findFirst();
      res.status(200).json({
        success: true,
        data: settings || { deliveryFee: 30.00, freeDeliveryThreshold: 499.00, codEnabled: true },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Update system-wide delivery fees, thresholds, and COD payment availability.
   * Super Admin only.
   */
  static async updateDeliverySettings(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const { deliveryFee, freeDeliveryThreshold, codEnabled } = req.body;

      const current = await prisma.deliverySettings.findFirst();

      const updated = await prisma.deliverySettings.upsert({
        where: {
          id: current?.id || '00000000-0000-0000-0000-000000000000',
        },
        update: {
          deliveryFee: deliveryFee !== undefined ? parseFloat(deliveryFee) : undefined,
          freeDeliveryThreshold: freeDeliveryThreshold !== undefined ? parseFloat(freeDeliveryThreshold) : undefined,
          codEnabled: codEnabled !== undefined ? !!codEnabled : undefined,
        },
        create: {
          deliveryFee: deliveryFee !== undefined ? parseFloat(deliveryFee) : 30.00,
          freeDeliveryThreshold: freeDeliveryThreshold !== undefined ? parseFloat(freeDeliveryThreshold) : 499.00,
          codEnabled: codEnabled !== undefined ? !!codEnabled : true,
        },
      });

      // Write Audit Log
      await prisma.auditLog.create({
        data: {
          adminUserId: req.user?.id,
          action: 'UPDATE_SYSTEM_SETTINGS',
          details: `Updated delivery configuration to fee: ${deliveryFee}, threshold: ${freeDeliveryThreshold}, codEnabled: ${codEnabled}`,
        },
      });

      res.status(200).json({
        success: true,
        message: 'System configurations updated successfully.',
        data: updated,
      });
    } catch (error) {
      next(error);
    }
  }
}
