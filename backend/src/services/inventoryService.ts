import { OrderStatus, PaymentStatus, Prisma } from '@prisma/client';

type Tx = Prisma.TransactionClient;

/**
 * Thrown when an order's status changed between validation and update (concurrent request).
 */
export const ORDER_STATUS_CHANGED = 'ORDER_STATUS_CHANGED';

/**
 * Atomically moves an order from `expectedStatus` to `nextStatus`.
 * Only one concurrent caller can win; others get ORDER_STATUS_CHANGED.
 */
export async function claimOrderStatus(
  tx: Tx,
  orderId: string,
  expectedStatus: OrderStatus,
  nextStatus: OrderStatus,
  paymentStatus?: PaymentStatus
) {
  const { count } = await tx.order.updateMany({
    where: { id: orderId, orderStatus: expectedStatus },
    data: {
      orderStatus: nextStatus,
      ...(paymentStatus ? { paymentStatus } : {}),
      updatedAt: new Date(),
    },
  });

  if (count === 0) {
    throw new Error(ORDER_STATUS_CHANGED);
  }

  return tx.order.findUniqueOrThrow({ where: { id: orderId } });
}

/**
 * Restores stock for every item of an order using atomic increments
 * (safe against concurrent checkouts/adjustments) and logs each change.
 * Creates the inventory row if it no longer exists.
 */
export async function restoreOrderStock(
  tx: Tx,
  params: {
    orderId: string;
    storeId: string;
    reason: string;
    performedByAdminId?: string | null;
  }
): Promise<void> {
  const items = await tx.orderItem.findMany({ where: { orderId: params.orderId } });

  for (const item of items) {
    const qty = Number(item.quantity);

    const inventory = await tx.storeInventory.upsert({
      where: { storeId_productId: { storeId: params.storeId, productId: item.productId } },
      update: { stockQuantity: { increment: qty } },
      create: { storeId: params.storeId, productId: item.productId, stockQuantity: qty },
    });

    const newStock = Number(inventory.stockQuantity);
    const prevStock = parseFloat((newStock - qty).toFixed(3));

    await tx.inventoryTransaction.create({
      data: {
        storeId: params.storeId,
        productId: item.productId,
        previousQuantity: prevStock,
        changeQuantity: qty,
        newQuantity: newStock,
        type: 'ORDER_CANCELLATION_RESTORE',
        reason: params.reason,
        performedByAdminId: params.performedByAdminId ?? null,
      },
    });
  }
}

/**
 * Locks a store inventory row for the rest of the transaction (no-op if it does not exist).
 */
export async function lockInventoryRow(tx: Tx, storeId: string, productId: string): Promise<void> {
  await tx.$queryRaw`
    SELECT 1 FROM "store_inventory"
    WHERE "store_id" = ${storeId}::uuid AND "product_id" = ${productId}::uuid
    FOR UPDATE
  `;
}
