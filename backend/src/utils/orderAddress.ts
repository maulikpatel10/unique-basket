import { Prisma, UserAddress } from '@prisma/client';

/** P1-02: immutable copy of a delivery address stored on the order at checkout. */
export function snapshotDeliveryAddress(address: UserAddress): Prisma.InputJsonObject {
  return {
    id: address.id,
    title: address.title,
    addressLine: address.addressLine,
    city: address.city,
    state: address.state,
    pincode: address.pincode,
    latitude: Number(address.latitude),
    longitude: Number(address.longitude),
  };
}

/**
 * Returns the order with `address` populated from the snapshot when the live address
 * row no longer exists (deleted after the order was placed). Response shape is unchanged.
 */
export function withDeliveryAddress<T extends { address?: unknown; deliveryAddressSnapshot?: unknown }>(order: T): T {
  if (!order.address && order.deliveryAddressSnapshot) {
    return { ...order, address: order.deliveryAddressSnapshot };
  }
  return order;
}
