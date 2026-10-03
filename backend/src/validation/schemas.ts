import { ProductUnit } from '@prisma/client';
import { normalizeIndianPhone } from '../utils/phone';
import { Parser, Schema, v } from './validator';

/**
 * Request body schemas (P2-01). Error codes and messages are the ones each
 * endpoint already returned, so client contracts are unchanged.
 * Business rules that need the database (pincode serviceability, stock,
 * product quantity rules, address ownership) stay in the controllers/services.
 */

const INVALID_PHONE = {
  errorCode: 'INVALID_PHONE_FORMAT',
  message: 'Invalid mobile number. Please enter a valid 10-digit Indian mobile number.',
};

/** Indian mobile number normalised to +91XXXXXXXXXX (D-008). */
const indianPhone = (missing?: { errorCode: string; message: string }): Parser<string> => (value) => {
  if (missing && (value === undefined || value === null || value === '')) return { ok: false, issue: missing };
  const phone = normalizeIndianPhone(value);
  return phone ? { ok: true, value: phone } : { ok: false, issue: INVALID_PHONE };
};

const COORDINATES = { errorCode: 'INVALID_COORDINATES', message: 'Invalid coordinate parameters.' };

// ---------- Auth ----------

export const sendOtpSchema = {
  phone: indianPhone(),
} satisfies Schema;

const VERIFY_MISSING = { errorCode: 'MISSING_PARAMETERS', message: 'Phone number and OTP are required.' };
export const verifyOtpSchema = {
  // Both fields are required before the phone format is checked (existing order of checks).
  otp: ((value) =>
    value === undefined || value === null || value === ''
      ? { ok: false, issue: VERIFY_MISSING }
      : { ok: true, value: String(value) }) as Parser<string>,
  phone: indianPhone(VERIFY_MISSING),
} satisfies Schema;

// ---------- Customer profile ----------

const GENDERS: Record<string, string> = {
  MALE: 'Male',
  FEMALE: 'Female',
  OTHER: 'Other',
  PREFER_NOT_TO_SAY: 'Prefer not to say',
  'PREFER NOT TO SAY': 'Prefer not to say',
};

const INVALID_DOB = (message: string) => ({ ok: false as const, issue: { errorCode: 'INVALID_DOB', message } });

/** YYYY-MM-DD (or ISO 8601) → UTC midnight Date; null/'' clears; absent → undefined. */
const dateOfBirth: Parser<Date | null | undefined> = (value) => {
  if (value === undefined) return { ok: true, value: undefined };
  if (value === null || value === '') return { ok: true, value: null };
  if (typeof value !== 'string') return INVALID_DOB('Date of birth must be a string or null.');
  const match = value.trim().match(/^(\d{4})-(\d{2})-(\d{2})/);
  if (!match) return INVALID_DOB('Invalid date of birth format. Expected YYYY-MM-DD or ISO 8601 string.');
  const [year, month, day] = [Number(match[1]), Number(match[2]), Number(match[3])];
  if (month < 1 || month > 12 || day < 1 || day > 31 || year < 1900) return INVALID_DOB('Invalid date of birth value.');
  const date = new Date(Date.UTC(year, month - 1, day));
  if (isNaN(date.getTime())) return INVALID_DOB('Invalid date of birth.');
  if (date.getTime() > Date.now()) {
    return { ok: false, issue: { errorCode: 'FUTURE_DOB', message: 'Date of birth cannot be in the future.' } };
  }
  return { ok: true, value: date };
};

/** Gender label (case-insensitive key or exact label); null/'' clears; absent → undefined. */
const gender: Parser<string | null | undefined> = (value) => {
  if (value === undefined) return { ok: true, value: undefined };
  if (value === null || value === '') return { ok: true, value: null };
  if (typeof value !== 'string') {
    return { ok: false, issue: { errorCode: 'INVALID_GENDER', message: 'Gender must be a string or null.' } };
  }
  const trimmed = value.trim();
  const label = GENDERS[trimmed.toUpperCase()] ?? Object.values(GENDERS).find((g) => g === trimmed);
  return label
    ? { ok: true, value: label }
    : {
        ok: false,
        issue: {
          errorCode: 'INVALID_GENDER',
          message: 'Invalid gender value. Allowed values: Male, Female, Other, Prefer not to say.',
        },
      };
};

export const updateProfileSchema = {
  name: v.optionalString({
    errorCode: 'INVALID_NAME',
    message: 'Name cannot be empty.',
    max: { length: 100, errorCode: 'NAME_TOO_LONG', message: 'Name cannot exceed 100 characters.' },
  }),
  email: v.nullableString({
    errorCode: 'INVALID_EMAIL',
    message: 'Invalid email address format.',
    pattern: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
  }),
  dob: dateOfBirth,
  gender,
} satisfies Schema;

// ---------- Customer addresses ----------

const ADDRESS_LINE = { errorCode: 'MISSING_ADDRESS_LINE', message: 'Address line is required.' };
const PINCODE = { errorCode: 'INVALID_PINCODE', message: 'A valid 6-digit pincode is required.', pattern: /^\d{6}$/ };
const addressText = (field: string) => v.optionalText({ errorCode: 'VALIDATION_ERROR', message: `${field} must be text.`, maxLength: 255 });

const addressFields = {
  title: addressText('Title'),
  city: addressText('City'),
  state: addressText('State'),
  latitude: v.number({ ...COORDINATES, min: -90, max: 90 }),
  longitude: v.number({ ...COORDINATES, min: -180, max: 180 }),
  isDefault: v.optionalBoolean({ errorCode: 'VALIDATION_ERROR', message: 'isDefault must be true or false.' }),
};

export const addAddressSchema = {
  addressLine: v.requiredString(ADDRESS_LINE),
  pincode: v.requiredString(PINCODE),
  ...addressFields,
} satisfies Schema;

export const updateAddressSchema = {
  addressLine: v.optionalString({ errorCode: 'MISSING_ADDRESS_LINE', message: 'Address line cannot be empty.' }),
  pincode: v.optionalString(PINCODE),
  ...addressFields,
} satisfies Schema;

// ---------- Cart ----------

const CART_ADD_MISSING = { errorCode: 'MISSING_PARAMETERS', message: 'Product ID and quantity are required.' };
export const addCartItemSchema = {
  productId: v.requiredString(CART_ADD_MISSING),
  quantity: v.number({
    errorCode: 'INVALID_QUANTITY',
    message: 'Quantity must be a positive decimal number.',
    positive: true,
    required: CART_ADD_MISSING,
  }) as Parser<number>,
} satisfies Schema;

export const updateCartItemSchema = {
  // 0 or a negative number removes the line (existing contract); non-numeric values are rejected.
  quantity: v.number({
    errorCode: 'INVALID_QUANTITY',
    message: 'Quantity must be a number.',
    required: { errorCode: 'MISSING_PARAMETERS', message: 'Quantity is required.' },
  }) as Parser<number>,
} satisfies Schema;

// ---------- Orders ----------

const ORDER_MISSING = {
  errorCode: 'MISSING_PARAMETERS',
  message: 'Fulfillment type, payment method, and items are required.',
};

export const createOrderSchema = {
  // Check order mirrors the previous controller: required fields → payment method;
  // an unknown fulfillmentType is still rejected inside the order transaction (INVALID_FULFILLMENT_TYPE).
  fulfillmentType: v.requiredString(ORDER_MISSING),
  items: v.nonEmptyArray(
    {
      productId: v.requiredString({ errorCode: 'MISSING_PARAMETERS', message: 'Each item requires a productId and quantity.' }),
      quantity: v.number({
        errorCode: 'INVALID_QUANTITY',
        message: 'Quantity must be a positive decimal.',
        positive: true,
        required: { errorCode: 'MISSING_PARAMETERS', message: 'Each item requires a productId and quantity.' },
      }) as Parser<number>,
    },
    ORDER_MISSING,
  ),
  paymentMethod: v.oneOf(['COD', 'ONLINE'] as const, {
    errorCode: 'INVALID_PAYMENT_METHOD',
    message: 'Payment method must be COD or ONLINE.',
    required: ORDER_MISSING,
  }) as Parser<'COD' | 'ONLINE'>,
  addressId: v.optionalString({ errorCode: 'MISSING_ADDRESS_ID', message: 'Address ID is required for delivery fulfillment.' }),
  storeId: v.optionalString({ errorCode: 'MISSING_STORE_ID', message: 'Store ID is required for pickup fulfillment.' }),
} satisfies Schema;

// ---------- Products (admin) ----------

const PRODUCT_MISSING = { errorCode: 'MISSING_PARAMETERS', message: 'Product name, categoryId, unit, and price are required.' };
const PRODUCT_UNITS = Object.values(ProductUnit);
const INVALID_VALUES = { errorCode: 'VALIDATION_ERROR', message: 'Request contains invalid values.' };

const productShared = {
  description: v.optionalText({ ...INVALID_VALUES }),
  imageUrl: v.optionalText({ ...INVALID_VALUES }),
  mrp: v.number({ ...INVALID_VALUES, positive: true, nullable: true }),
  isActive: v.optionalBoolean(INVALID_VALUES),
  // Quantity rules are validated against the unit by parseQuantityConfig (D-012).
  minQuantity: v.any(),
  maxQuantity: v.any(),
  quantityStep: v.any(),
};

export const createProductSchema = {
  name: v.requiredString({ ...PRODUCT_MISSING, max: { length: 100, ...INVALID_VALUES } }),
  categoryId: v.requiredString(PRODUCT_MISSING),
  unit: v.oneOf(PRODUCT_UNITS, { ...INVALID_VALUES, required: PRODUCT_MISSING }) as Parser<ProductUnit>,
  price: v.number({ ...INVALID_VALUES, positive: true, required: PRODUCT_MISSING }) as Parser<number>,
  ...productShared,
} satisfies Schema;

export const updateProductSchema = {
  name: v.optionalString({ ...INVALID_VALUES, max: { length: 100, ...INVALID_VALUES } }),
  categoryId: v.optionalString(INVALID_VALUES),
  unit: v.oneOf(PRODUCT_UNITS, INVALID_VALUES),
  price: v.number({ ...INVALID_VALUES, positive: true }),
  ...productShared,
} satisfies Schema;
