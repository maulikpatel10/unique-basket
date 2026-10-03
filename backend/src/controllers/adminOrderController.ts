import { Response, NextFunction } from 'express';
import { prisma } from '../config/db';
import { AuthenticatedRequest } from '../middlewares/authMiddleware';
import { OrderStatus, PaymentStatus } from '@prisma/client';
import { NotificationService } from '../services/notificationService';
import { withDeliveryAddress } from '../utils/orderAddress';
import { claimOrderStatus, restoreOrderStock, ORDER_STATUS_CHANGED } from '../services/inventoryService';
import { getParam } from '../utils/request';
import { validatedBody } from '../middlewares/validate';
import { updateOrderStatusSchema, verifyPickupSchema } from '../validation/schemas';

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
        data: withDeliveryAddress(order),
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
      // validateBody(updateOrderStatusSchema): status is a known OrderStatus
      const { status } = validatedBody(res, updateOrderStatusSchema);
      const { role, storeId: managerStoreId } = req.user!;

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

      if (order.orderStatus !== status) {
        // P0-05 / D-006: pickup completion must go through pickup verification (order number + phone)
        if (status === OrderStatus.PICKED_UP) {
          res.status(400).json({
            success: false,
            message: 'Pickup orders must be completed via pickup verification.',
            errorCode: 'PICKUP_VERIFICATION_REQUIRED',
          });
          return;
        }

        // P0-05: transitions must match the fulfillment type
        const deliveryOnlyStatuses: OrderStatus[] = [OrderStatus.OUT_FOR_DELIVERY, OrderStatus.DELIVERED];
        if (order.fulfillmentType === 'PICKUP' && deliveryOnlyStatuses.includes(status as OrderStatus)) {
          res.status(400).json({
            success: false,
            message: `Status ${status} is not valid for a PICKUP order.`,
            errorCode: 'INVALID_STATUS_FOR_FULFILLMENT',
          });
          return;
        }

        // P0-05 / D-005: unpaid ONLINE orders may only be cancelled
        if (
          order.paymentMethod === 'ONLINE' &&
          order.paymentStatus !== PaymentStatus.PAID &&
          status !== OrderStatus.CANCELLED
        ) {
          res.status(400).json({
            success: false,
            message: 'Online payment is not completed. Unpaid online orders can only be cancelled.',
            errorCode: 'ONLINE_PAYMENT_PENDING',
          });
          return;
        }
      }

      // Perform update in transaction
      const updated = await prisma.$transaction(async (tx) => {
        // P0-05: completing an order marks payment PAID only for COD (cash collected on delivery)
        let paymentStatusUpdate: PaymentStatus | undefined = undefined;
        if (status === OrderStatus.DELIVERED && order.paymentMethod === 'COD') {
          paymentStatusUpdate = PaymentStatus.PAID;
        }

        // P0-06: claim the status change first (only one concurrent request can win),
        // so stock is never restored twice for the same cancellation.
        const orderUpdate = await claimOrderStatus(
          tx,
          id,
          order.orderStatus,
          status as OrderStatus,
          paymentStatusUpdate
        );

        // If cancelling order, restore inventory stock atomically and log transaction
        if (status === OrderStatus.CANCELLED && order.orderStatus !== OrderStatus.CANCELLED) {
          await restoreOrderStock(tx, {
            orderId: id,
            storeId: order.storeId,
            reason: `Admin order cancellation for order: ${order.orderNumber}`,
            performedByAdminId: req.user?.id,
          });
        }

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

  /**
   * Verification & Handover for Store Pickup Orders.
   * Search by Order ID (orderNumber) + Registered Mobile Number.
   * Enforces store isolation checks for Store Managers.
   */
  static async verifyPickup(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      // validateBody(verifyPickupSchema): phone normalised to +91XXXXXXXXXX when valid (D-008)
      const { orderNumber, phone: registeredPhone } = validatedBody(res, verifyPickupSchema);
      const { role, storeId: managerStoreId } = req.user!;

      const order = await prisma.order.findFirst({
        where: {
          orderNumber,
          user: { phone: registeredPhone },
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

      // P0-04: Handover is allowed only once the order is READY_FOR_PICKUP
      if (order.orderStatus !== OrderStatus.READY_FOR_PICKUP) {
        res.status(400).json({
          success: false,
          message: `Cannot handover order in status ${order.orderStatus}. Order must be READY_FOR_PICKUP.`,
          errorCode: 'ORDER_NOT_READY_FOR_PICKUP',
        });
        return;
      }

      // Mark order as PICKED_UP and update payment status for COD orders
      const updated = await prisma.$transaction(async (tx) => {
        // Conditional update guards against concurrent status changes (e.g. cancellation)
        const { count } = await tx.order.updateMany({
          where: { id: order.id, orderStatus: OrderStatus.READY_FOR_PICKUP },
          data: {
            orderStatus: OrderStatus.PICKED_UP,
            paymentStatus: PaymentStatus.PAID, // Sets COD to PAID, keeps ONLINE as PAID
            updatedAt: new Date(),
          },
        });

        if (count === 0) {
          throw new Error('PICKUP_STATUS_CHANGED');
        }

        const orderUpdate = await tx.order.findUniqueOrThrow({
          where: { id: order.id },
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
    } catch (error: any) {
      if (error?.message === 'PICKUP_STATUS_CHANGED') {
        res.status(409).json({
          success: false,
          message: 'Order status changed during handover. Please refresh and try again.',
          errorCode: 'ORDER_STATUS_CONFLICT',
        });
        return;
      }
      next(error);
    }
  }
}
