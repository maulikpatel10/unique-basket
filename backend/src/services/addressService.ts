import { Prisma } from '@prisma/client';
import { prisma } from '../config/db';
import { AppError } from '../utils/errors';
import { requireServiceablePincode } from './serviceabilityService';

type Tx = Prisma.TransactionClient;

/**
 * Customer address book (P2-01 service extraction).
 * Invariant: a customer with addresses has exactly one default address.
 * Every flow that changes the default runs in one transaction.
 */

// Rajkot centre — existing fallback when the app sends no coordinates (P1-01, blocked on P4-04/P4-05).
const FALLBACK_LATITUDE = 22.3039;
const FALLBACK_LONGITUDE = 70.8022;

const ADDRESS_NOT_FOUND = () => new AppError(404, 'ADDRESS_NOT_FOUND', 'Address not found.');

export interface NewAddress {
  title?: string | null;
  addressLine: string;
  city?: string | null;
  state?: string | null;
  pincode: string;
  latitude?: number | null;
  longitude?: number | null;
  isDefault?: boolean;
}

export type AddressChanges = Partial<NewAddress>;

export async function listAddresses(userId: string) {
  return prisma.userAddress.findMany({ where: { userId }, orderBy: { createdAt: 'desc' } });
}

async function findOwnedAddress(tx: Tx | typeof prisma, userId: string, id: string) {
  const address = await tx.userAddress.findFirst({ where: { id, userId } });
  if (!address) throw ADDRESS_NOT_FOUND();
  return address;
}

/** Creates an address in a serviceable pincode. The first address becomes the default. */
export async function createAddress(userId: string, input: NewAddress) {
  return prisma.$transaction(async (tx) => {
    const supported = await requireServiceablePincode(tx, input.pincode);

    const existingCount = await tx.userAddress.count({ where: { userId } });
    const makeDefault = input.isDefault ?? existingCount === 0;
    if (makeDefault && existingCount > 0) {
      await tx.userAddress.updateMany({ where: { userId }, data: { isDefault: false } });
    }

    return tx.userAddress.create({
      data: {
        userId,
        title: input.title || 'Home',
        addressLine: input.addressLine,
        city: input.city || supported.city,
        state: input.state || supported.state,
        pincode: input.pincode,
        latitude: input.latitude ?? FALLBACK_LATITUDE,
        longitude: input.longitude ?? FALLBACK_LONGITUDE,
        isDefault: makeDefault,
      },
    });
  });
}

/** Updates an owned address; a new pincode must be serviceable. */
export async function updateAddress(userId: string, id: string, changes: AddressChanges) {
  return prisma.$transaction(async (tx) => {
    await findOwnedAddress(tx, userId, id);
    if (changes.pincode !== undefined) await requireServiceablePincode(tx, changes.pincode);

    if (changes.isDefault === true) {
      await tx.userAddress.updateMany({ where: { userId, NOT: { id } }, data: { isDefault: false } });
    }

    return tx.userAddress.update({
      where: { id },
      data: {
        // null/empty title/city/state are ignored rather than clearing required columns
        ...(changes.title ? { title: changes.title } : {}),
        ...(changes.addressLine !== undefined ? { addressLine: changes.addressLine } : {}),
        ...(changes.city ? { city: changes.city } : {}),
        ...(changes.state ? { state: changes.state } : {}),
        ...(changes.pincode !== undefined ? { pincode: changes.pincode } : {}),
        ...(changes.latitude != null ? { latitude: changes.latitude } : {}),
        ...(changes.longitude != null ? { longitude: changes.longitude } : {}),
        ...(changes.isDefault !== undefined ? { isDefault: changes.isDefault } : {}),
      },
    });
  });
}

/** Makes an owned address the only default. */
export async function setDefaultAddress(userId: string, id: string) {
  return prisma.$transaction(async (tx) => {
    await findOwnedAddress(tx, userId, id);
    await tx.userAddress.updateMany({ where: { userId, NOT: { id } }, data: { isDefault: false } });
    return tx.userAddress.update({ where: { id }, data: { isDefault: true } });
  });
}

/** Deletes an owned address; if it was the default, the newest remaining address becomes default. */
export async function deleteAddress(userId: string, id: string) {
  await prisma.$transaction(async (tx) => {
    const existing = await findOwnedAddress(tx, userId, id);
    await tx.userAddress.delete({ where: { id } });

    if (existing.isDefault) {
      const remaining = await tx.userAddress.findMany({ where: { userId }, orderBy: { createdAt: 'desc' } });
      if (remaining.length > 0 && !remaining.some((a) => a.isDefault)) {
        await tx.userAddress.update({ where: { id: remaining[0].id }, data: { isDefault: true } });
      }
    }
  });
}
