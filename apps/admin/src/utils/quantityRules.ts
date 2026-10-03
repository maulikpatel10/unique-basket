/**
 * Product-level purchase quantity rules (D-012), mirroring backend/src/utils/quantity.ts.
 * The backend is authoritative; this only gives the admin early feedback.
 */
export type ProductUnit = 'KG' | 'GRAM' | 'PIECE' | 'PACK' | 'DOZEN';

// PIECE / PACK / DOZEN / GRAM: whole numbers; KG: up to 3 decimals (D-012).
const UNIT_DECIMALS: Record<ProductUnit, number> = { KG: 3, GRAM: 0, PIECE: 0, PACK: 0, DOZEN: 0 };

export interface QuantityConfigInput {
  minQuantity: string;
  maxQuantity: string;
  quantityStep: string;
}

export type QuantityConfigErrors = Partial<Record<keyof QuantityConfigInput, string>>;

const FIELDS: [keyof QuantityConfigInput, string][] = [
  ['minQuantity', 'Minimum quantity'],
  ['maxQuantity', 'Maximum quantity'],
  ['quantityStep', 'Quantity step'],
];

const toMilli = (value: number) => Math.round(value * 1000);

const decimalsOf = (text: string) => (text.includes('.') ? text.split('.')[1].length : 0);

/** True when no quantity rule fields were entered (product keeps its unconfigured behaviour). */
export const isQuantityConfigEmpty = (input: QuantityConfigInput) =>
  FIELDS.every(([key]) => input[key].trim() === '');

/** Validates the three rule fields for a unit. Returns per-field errors (empty when valid). */
export function validateQuantityConfig(unit: ProductUnit, input: QuantityConfigInput): QuantityConfigErrors {
  const errors: QuantityConfigErrors = {};
  if (isQuantityConfigEmpty(input)) return errors;

  const values: Partial<Record<keyof QuantityConfigInput, number>> = {};
  const allowed = UNIT_DECIMALS[unit];

  for (const [key, label] of FIELDS) {
    const text = input[key].trim();
    if (text === '') {
      errors[key] = `${label} is required when quantity rules are set`;
      continue;
    }
    if (!/^\d+(\.\d+)?$/.test(text) || Number(text) <= 0) {
      errors[key] = `${label} must be greater than 0`;
      continue;
    }
    if (decimalsOf(text) > allowed) {
      errors[key] = allowed === 0 ? `${label} must be a whole number for ${unit}` : `${label} allows at most ${allowed} decimals for ${unit}`;
      continue;
    }
    values[key] = Number(text);
  }
  if (Object.keys(errors).length > 0) return errors;

  const min = values.minQuantity!;
  const max = values.maxQuantity!;
  const step = values.quantityStep!;
  if (max < min) {
    errors.maxQuantity = 'Maximum must be greater than or equal to minimum';
    return errors;
  }
  const range = toMilli(max) - toMilli(min);
  if (range > 0 && toMilli(step) > range) {
    errors.quantityStep = 'Step cannot be larger than the range between minimum and maximum';
  } else if (range % toMilli(step) !== 0) {
    errors.maxQuantity = 'Maximum must be reachable from minimum in whole steps';
  }
  return errors;
}

/** Request body fields for the rule: numbers, or null for all three to clear/leave unconfigured. */
export function quantityConfigPayload(input: QuantityConfigInput) {
  if (isQuantityConfigEmpty(input)) return { minQuantity: null, maxQuantity: null, quantityStep: null };
  return {
    minQuantity: Number(input.minQuantity),
    maxQuantity: Number(input.maxQuantity),
    quantityStep: Number(input.quantityStep),
  };
}

const fmt = (value: string | number) => String(Number(value));

/** Short summary for tables, e.g. "1–10 KG · step 0.25". */
export function describeQuantityRule(
  unit: ProductUnit,
  rule: { minQuantity: string | number | null; maxQuantity: string | number | null; quantityStep: string | number | null },
): string | null {
  if (rule.minQuantity == null || rule.maxQuantity == null || rule.quantityStep == null) return null;
  return `${fmt(rule.minQuantity)}–${fmt(rule.maxQuantity)} ${unit} · step ${fmt(rule.quantityStep)}`;
}
