import { Response, NextFunction } from 'express';
import { prisma } from '../config/db';
import { AuthenticatedRequest } from '../middlewares/authMiddleware';
import { PaymentStatus } from '@prisma/client';
import { getParam } from '../utils/request';

const ALLOWED_PAYMENT_STATUSES: PaymentStatus[] = [
  PaymentStatus.PENDING,
  PaymentStatus.PAID,
  PaymentStatus.FAILED,
];

export class AdminPaymentController {
  /**
   * List payments with search, filter, and server-side pagination.
   * Super Admin sees all stores. Store Manager sees only their assigned store.
   */
  static async getPayments(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const { role, storeId: managerStoreId } = req.user!;
      const {
        storeId: queryStoreId,
        paymentMethod,
        paymentStatus,
        search,
        page: queryPage,
        limit: queryLimit,
      } = req.query;

      // Build order-level where clause for store isolation
      const orderWhere: any = {};

      if (role === 'STORE_MANAGER') {
        orderWhere.storeId = managerStoreId;
      } else if (role === 'SUPER_ADMIN' && queryStoreId) {
        orderWhere.storeId = queryStoreId as string;
      }

      if (paymentMethod) {
        orderWhere.paymentMethod = paymentMethod as any;
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
        orderWhere.paymentStatus = paymentStatus as PaymentStatus;
      }

      if (search && typeof search === 'string' && search.trim()) {
        const s = search.trim();
        orderWhere.OR = [
          { orderNumber: { contains: s, mode: 'insensitive' } },
          { user: { name: { contains: s, mode: 'insensitive' } } },
          { user: { phone: { contains: s, mode: 'insensitive' } } },
        ];
      }

      const page = queryPage ? parseInt(queryPage as string) : 1;
      const limit = queryLimit ? parseInt(queryLimit as string) : 10;
      const skip = (page - 1) * limit;

      const totalCount = await prisma.order.count({ where: orderWhere });

      const orders = await prisma.order.findMany({
        where: orderWhere,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        select: {
          id: true,
          orderNumber: true,
          createdAt: true,
          updatedAt: true,
          fulfillmentType: true,
          paymentMethod: true,
          paymentStatus: true,
          orderStatus: true,
          subtotal: true,
          deliveryFee: true,
          discount: true,
          total: true,
          user: { select: { id: true, name: true, phone: true, email: true } },
          store: { select: { id: true, name: true, storeId: true } },
          payments: {
            select: {
              id: true,
              razorpayOrderId: true,
              razorpayPaymentId: true,
              amount: true,
              status: true,
              createdAt: true,
            },
          },
        },
      });

      res.status(200).json({
        success: true,
        data: {
          payments: orders,
          pagination: {
            total: totalCount,
            page,
            limit,
            totalPages: Math.ceil(totalCount / limit),
          },
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Fetch complete payment details for a specific order.
   * Enforces store isolation for Store Managers.
   */
  static async getPaymentDetails(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = getParam(req, 'id');
      const { role, storeId: managerStoreId } = req.user!;

      const order = await prisma.order.findUnique({
        where: { id },
        include: {
          user: { select: { id: true, name: true, phone: true, email: true } },
          store: { select: { id: true, name: true, storeId: true, address: true } },
          address: true,
          payments: true,
        },
      });

      if (!order) {
        res.status(404).json({
          success: false,
          message: 'Order / payment not found.',
          errorCode: 'PAYMENT_NOT_FOUND',
        });
        return;
      }

      // Enforce store isolation
      if (role === 'STORE_MANAGER' && order.storeId !== managerStoreId) {
        res.status(403).json({
          success: false,
          message: 'Access Denied. You are not authorized to view payment details for another store.',
          errorCode: 'STORE_ACCESS_FORBIDDEN',
        });
        return;
      }

      // Build safe payment response — never expose secrets
      const safePayments = order.payments.map((p) => ({
        id: p.id,
        razorpayOrderId: p.razorpayOrderId,
        razorpayPaymentId: p.razorpayPaymentId,
        // Signature is stored but never surfaced in API responses
        amount: p.amount,
        gatewayStatus: p.status,
        createdAt: p.createdAt,
      }));

      res.status(200).json({
        success: true,
        data: {
          id: order.id,
          orderNumber: order.orderNumber,
          createdAt: order.createdAt,
          updatedAt: order.updatedAt,
          fulfillmentType: order.fulfillmentType,
          orderStatus: order.orderStatus,
          paymentMethod: order.paymentMethod,
          paymentStatus: order.paymentStatus,
          subtotal: order.subtotal,
          deliveryFee: order.deliveryFee,
          discount: order.discount,
          total: order.total,
          user: order.user,
          store: order.store,
          deliveryAddress: order.address ?? order.deliveryAddressSnapshot ?? null,
          razorpayTransactions: safePayments,
          isCOD: order.paymentMethod === 'COD',
        },
      });
    } catch (error) {
      next(error);
    }
  }
}
