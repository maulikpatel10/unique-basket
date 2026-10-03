import { FulfillmentType, OrderStatus, PaymentMethod, PaymentStatus, Prisma } from '@prisma/client';
import { prisma } from '../config/db';
import { AppError } from '../utils/errors';
import { withDeliveryAddress } from '../utils/orderAddress';
import { claimOrderStatus, restoreOrderStock, ORDER_STATUS_CHANGED } from './inventoryService';
import { NotificationService } from './notificationService';

/**
 * Admin / store-manager order operations (P2-01 service extraction).
 * Store isolation: a STORE_MANAGER only sees and changes orders of their own store.
 * Errors are AppErrors with the stable codes the admin panel already handles.
 */

export interface AdminActor {
  id?: string;
  role: string;
  storeId?: string;
}

/** 403 STORE_ACCESS_FORBIDDEN when a store manager touches another store's order. */
export function assertStoreAccess(actor: AdminActor, orderStoreId: string, message: string): void {
  if (actor.role === 'STORE_MANAGER' && orderStoreId !== actor.storeId) {
    throw new AppError(403, 'STORE_ACCESS_FORBIDDEN', message);
  }
}

const ORDER_NOT_FOUND = () => new AppError(404, 'ORDER_NOT_FOUND', 'Order not found.');
const STATUS_CONFLICT = (message: string) => new AppError(409, 'ORDER_STATUS_CONFLICT', message);

// ---------- Listing & details ----------

const FILTERABLE_PAYMENT_STATUSES: PaymentStatus[] = [PaymentStatus.PENDING, PaymentStatus.PAID, PaymentStatus.FAILED];

export interface AdminOrderQuery {
  storeId?: string;
  status?: string;
  fulfillment?: string;
  paymentStatus?: string;
  search?: string;
  page?: string;
  limit?: string;
}

/** Builds the Prisma filter for the admin order list, scoped to the manager's store. */
export function buildAdminOrderFilter(actor: AdminActor, query: AdminOrderQuery): Prisma.OrderWhereInput {
  const where: Prisma.OrderWhereInput = {};

  const storeId = actor.role === 'STORE_MANAGER' ? actor.storeId : actor.role === 'SUPER_ADMIN' ? query.storeId : undefined;
  if (storeId) where.storeId = storeId;
  if (query.status) where.orderStatus = query.status as OrderStatus;
  if (query.fulfillment) where.fulfillmentType = query.fulfillment as FulfillmentType;
  if (query.paymentStatus) {
    if (!FILTERABLE_PAYMENT_STATUSES.includes(query.paymentStatus as PaymentStatus)) {
      throw new AppError(
        400,
        'INVALID_PAYMENT_STATUS',
        'Invalid payment status filter. Supported statuses are PENDING, PAID, and FAILED.',
      );
    }
    where.paymentStatus = query.paymentStatus as PaymentStatus;
  }

  const search = query.search?.trim();
  if (search) {
    where.OR = [
      { orderNumber: { contains: search, mode: 'insensitive' } },
      { user: { name: { contains: search, mode: 'insensitive' } } },
      { user: { phone: { contains: search, mode: 'insensitive' } } },
    ];
  }
  return where;
}

/**
 * Admin order list. With `page`/`limit` returns `{ orders, pagination }` (default limit 10),
 * otherwise a plain array (existing contract).
 */
export async function listAdminOrders(actor: AdminActor, query: AdminOrderQuery) {
  const where = buildAdminOrderFilter(actor, query);
  const paginate = Boolean(query.page || query.limit);
  const page = query.page ? parseInt(query.page) : 1;
  const limit = query.limit ? parseInt(query.limit) : 10;

  const [total, orders] = await Promise.all([
    prisma.order.count({ where }),
    prisma.order.findMany({
      where,
      skip: paginate ? (page - 1) * limit : undefined,
      take: paginate ? limit : undefined,
      include: {
        user: { select: { id: true, name: true, phone: true, email: true } },
        store: { select: { id: true, name: true, storeId: true } },
      },
      orderBy: { createdAt: 'desc' },
    }),
  ]);

  if (!paginate) return orders;
  return { orders, pagination: { total, page, limit, totalPages: Math.ceil(total / limit) } };
}

/** Full order (customer, store, address snapshot, items, payments) with store isolation. */
export async function getAdminOrderDetails(actor: AdminActor, id: string) {
  const order = await prisma.order.findUnique({
    where: { id },
    include: {
      user: { select: { id: true, name: true, phone: true, email: true } },
      store: { select: { id: true, name: true, storeId: true, address: true, phone: true } },
      address: true,
      items: { include: { product: { select: { name: true, unit: true, imageUrl: true } } } },
      payments: true,
    },
  });
  if (!order) throw ORDER_NOT_FOUND();
  assertStoreAccess(actor, order.storeId, 'Access Denied. You do not have permissions to view orders for another store.');
  return withDeliveryAddress(order);
}

// ---------- Status changes ----------

/** Admin status machine (current implementation; the lifecycle itself is pending owner review, P-012). */
export const VALID_TRANSITIONS: Record<OrderStatus, OrderStatus[]> = {
  [OrderStatus.PLACED]: [OrderStatus.CONFIRMED, OrderStatus.CANCELLED],
  [OrderStatus.CONFIRMED]: [OrderStatus.PREPARING, OrderStatus.CANCELLED],
  [OrderStatus.PREPARING]: [OrderStatus.READY_FOR_PICKUP, OrderStatus.OUT_FOR_DELIVERY, OrderStatus.CANCELLED],
  [OrderStatus.READY_FOR_PICKUP]: [OrderStatus.OUT_FOR_DELIVERY, OrderStatus.PICKED_UP, OrderStatus.CANCELLED],
  [OrderStatus.OUT_FOR_DELIVERY]: [OrderStatus.DELIVERED, OrderStatus.CANCELLED],
  [OrderStatus.DELIVERED]: [],
  [OrderStatus.PICKED_UP]: [],
  [OrderStatus.CANCELLED]: [],
};

const DELIVERY_ONLY_STATUSES: OrderStatus[] = [OrderStatus.OUT_FOR_DELIVERY, OrderStatus.DELIVERED];

export interface StatusRuleOrder {
  orderStatus: OrderStatus;
  fulfillmentType: FulfillmentType | string;
  paymentMethod: PaymentMethod | string;
  paymentStatus: PaymentStatus;
}

/**
 * Pure status rules for an admin status change (no-op when the status is unchanged):
 * - transition must be allowed by VALID_TRANSITIONS
 * - PICKED_UP only via pickup verification (D-006)
 * - OUT_FOR_DELIVERY / DELIVERED not valid for PICKUP orders (P0-05)
 * - unpaid ONLINE orders can only be cancelled (D-005)
 */
export function assertStatusTransition(order: StatusRuleOrder, next: OrderStatus): void {
  if (order.orderStatus === next) return;

  if (!(VALID_TRANSITIONS[order.orderStatus] || []).includes(next)) {
    throw new AppError(400, 'INVALID_STATUS_TRANSITION', `Invalid order status transition from ${order.orderStatus} to ${next}.`);
  }
  if (next === OrderStatus.PICKED_UP) {
    throw new AppError(400, 'PICKUP_VERIFICATION_REQUIRED', 'Pickup orders must be completed via pickup verification.');
  }
  if (order.fulfillmentType === 'PICKUP' && DELIVERY_ONLY_STATUSES.includes(next)) {
    throw new AppError(400, 'INVALID_STATUS_FOR_FULFILLMENT', `Status ${next} is not valid for a PICKUP order.`);
  }
  if (order.paymentMethod === 'ONLINE' && order.paymentStatus !== PaymentStatus.PAID && next !== OrderStatus.CANCELLED) {
    throw new AppError(
      400,
      'ONLINE_PAYMENT_PENDING',
      'Online payment is not completed. Unpaid online orders can only be cancelled.',
    );
  }
}

/**
 * Changes an order's status: rules → atomic claim (P0-06) → stock restore on cancellation →
 * audit log. Marks COD orders PAID on delivery (P0-05). Notifies the customer after commit.
 */
export async function changeOrderStatus(actor: AdminActor, id: string, next: OrderStatus) {
  const order = await prisma.order.findUnique({ where: { id } });
  if (!order) throw ORDER_NOT_FOUND();
  assertStoreAccess(actor, order.storeId, "Access Denied. You are not authorized to update status for another store's orders.");
  assertStatusTransition(order, next);

  let updated;
  try {
    updated = await prisma.$transaction(async (tx) => {
      const paymentStatusUpdate =
        next === OrderStatus.DELIVERED && order.paymentMethod === 'COD' ? PaymentStatus.PAID : undefined;

      // Only one concurrent request can win the claim, so stock is never restored twice.
      const result = await claimOrderStatus(tx, id, order.orderStatus, next, paymentStatusUpdate);

      if (next === OrderStatus.CANCELLED && order.orderStatus !== OrderStatus.CANCELLED) {
        await restoreOrderStock(tx, {
          orderId: id,
          storeId: order.storeId,
          reason: `Admin order cancellation for order: ${order.orderNumber}`,
          performedByAdminId: actor.id,
        });
      }

      await tx.auditLog.create({
        data: {
          adminUserId: actor.id,
          action: 'UPDATE_ORDER_STATUS',
          details: `Updated order status of ${order.orderNumber} to ${next}`,
        },
      });
      return result;
    });
  } catch (error) {
    if ((error as Error)?.message === ORDER_STATUS_CHANGED) {
      throw STATUS_CONFLICT('Order status was changed by another request. Please refresh and try again.');
    }
    throw error;
  }

  NotificationService.sendToUser(
    updated.userId,
    'Order Status Update',
    `Your order ${order.orderNumber} has been updated to: ${next}.`,
    { orderId: updated.id, status: updated.orderStatus },
  ).catch((err) => console.error('Error sending status update notification to customer:', err));

  return updated;
}

// ---------- Pickup handover (D-006) ----------

/**
 * Verifies a pickup by order number + registered phone and hands the order over:
 * READY_FOR_PICKUP → PICKED_UP, payment PAID (cash collected for COD). Unpaid ONLINE orders are blocked.
 */
export async function verifyPickupHandover(actor: AdminActor, orderNumber: string, registeredPhone: string) {
  const order = await prisma.order.findFirst({
    where: { orderNumber, user: { phone: registeredPhone }, fulfillmentType: 'PICKUP' },
    include: {
      user: { select: { name: true, phone: true } },
      items: { include: { product: { select: { name: true, unit: true } } } },
    },
  });
  if (!order) {
    throw new AppError(404, 'PICKUP_ORDER_NOT_FOUND', 'Order not found or registered mobile number mismatch.');
  }
  assertStoreAccess(actor, order.storeId, 'Access Denied. You are not authorized to verify pickup orders for another store.');

  if (order.paymentMethod === 'ONLINE' && order.paymentStatus !== PaymentStatus.PAID) {
    throw new AppError(400, 'ONLINE_PAYMENT_PENDING', 'Cannot handover order. Online payment is pending or has failed.');
  }
  if (order.orderStatus !== OrderStatus.READY_FOR_PICKUP) {
    throw new AppError(
      400,
      'ORDER_NOT_READY_FOR_PICKUP',
      `Cannot handover order in status ${order.orderStatus}. Order must be READY_FOR_PICKUP.`,
    );
  }

  const updated = await prisma.$transaction(async (tx) => {
    // Conditional update guards against concurrent status changes (e.g. cancellation)
    const { count } = await tx.order.updateMany({
      where: { id: order.id, orderStatus: OrderStatus.READY_FOR_PICKUP },
      data: { orderStatus: OrderStatus.PICKED_UP, paymentStatus: PaymentStatus.PAID, updatedAt: new Date() },
    });
    if (count === 0) throw STATUS_CONFLICT('Order status changed during handover. Please refresh and try again.');

    await tx.auditLog.create({
      data: {
        adminUserId: actor.id,
        action: 'VERIFY_PICKUP_HANDOVER',
        details:
          order.paymentMethod === 'COD'
            ? `Collected cash and verified pickup handover for COD order: ${order.orderNumber}`
            : `Handover verified and marked PICKED_UP for prepaid online order: ${order.orderNumber}`,
      },
    });
    return tx.order.findUniqueOrThrow({ where: { id: order.id } });
  });

  NotificationService.sendToUser(
    order.userId,
    'Order Handover Verified',
    `Your order ${order.orderNumber} has been successfully verified and picked up.`,
    { orderId: order.id, status: 'PICKED_UP' },
  ).catch((err) => console.error('Error sending pickup handover notification to customer:', err));

  return {
    id: order.id,
    orderNumber: order.orderNumber,
    customerName: order.user.name || 'User',
    phone: order.user.phone,
    items: order.items.map((item) => ({ name: item.product.name, quantity: Number(item.quantity), unit: item.product.unit })),
    subtotal: Number(order.subtotal),
    total: Number(order.total),
    orderStatus: updated.orderStatus,
    paymentStatus: updated.paymentStatus,
  };
}
