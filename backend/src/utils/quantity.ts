import { ProductUnit } from '@prisma/client';

/** DB column precision for quantities: Decimal(10, 3). */
export const MAX_QUANTITY_DECIMALS = 3;
export const MAX_QUANTITY = 9999999.999;

/** Units that must be ordered in whole numbers (D-007: PIECE products must not accept fractions). */
const WHOLE_NUMBER_UNITS: ProductUnit[] = [ProductUnit.PIECE];

/**
 * Validates a positive quantity for a product unit.
 * Returns an error message, or null when valid.
 * Step sizes / limits for non-PIECE units are undecided (P4-08) and not enforced here.
 */
export function validateQuantityForUnit(unit: ProductUnit, quantity: number): string | null {
  if (!Number.isFinite(quantity) || quantity <= 0) {
    return 'Quantity must be a positive number.';
  }
  if (quantity > MAX_QUANTITY) {
    return `Quantity cannot exceed ${MAX_QUANTITY}.`;
  }
  const [, decimals = ''] = quantity.toString().split('.');
  if (decimals.length > MAX_QUANTITY_DECIMALS || quantity.toString().includes('e')) {
    return `Quantity cannot have more than ${MAX_QUANTITY_DECIMALS} decimal places.`;
  }
  if (WHOLE_NUMBER_UNITS.includes(unit) && !Number.isInteger(quantity)) {
    return `Quantity for ${unit} products must be a whole number.`;
  }
  return null;
}
