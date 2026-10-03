import { OrderStatus, ProductUnit } from '@prisma/client';
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

// =====================================================================
// Admin endpoints (P2-01 part 2)
// =====================================================================

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const strictBoolean = (issue: { errorCode: string; message: string }) => v.optionalBoolean(issue);

// ---------- Admin auth ----------

const CREDENTIALS = { errorCode: 'MISSING_CREDENTIALS', message: 'Email and password are required.' };
export const adminLoginSchema = {
  email: v.requiredString(CREDENTIALS),
  // Passwords are not trimmed: accept any non-empty string as given.
  password: ((value) =>
    typeof value === 'string' && value.length > 0 ? { ok: true, value } : { ok: false, issue: CREDENTIALS }) as Parser<string>,
} satisfies Schema;

// ---------- Orders ----------

const ORDER_STATUSES = Object.values(OrderStatus);
const INVALID_STATUS = { errorCode: 'INVALID_STATUS', message: 'Invalid order status value provided.' };
export const updateOrderStatusSchema = {
  status: v.oneOf(ORDER_STATUSES, { ...INVALID_STATUS, required: INVALID_STATUS }) as Parser<OrderStatus>,
} satisfies Schema;

const PICKUP_MISSING = { errorCode: 'MISSING_PARAMETERS', message: 'Order number and registered mobile number are required.' };
export const verifyPickupSchema = {
  orderNumber: v.requiredString(PICKUP_MISSING),
  // Normalised to +91XXXXXXXXXX when possible (D-008); otherwise matched as entered.
  phone: ((value) => {
    if (typeof value !== 'string' || !value.trim()) return { ok: false, issue: PICKUP_MISSING };
    return { ok: true, value: normalizeIndianPhone(value) ?? value.trim() };
  }) as Parser<string>,
} satisfies Schema;

// ---------- Fare & COD settings ----------

const INVALID_SETTINGS = { errorCode: 'INVALID_SETTINGS_VALUES', message: 'Invalid numerical values provided in settings.' };
// Negative values and the COD range are cross-field rules checked in the controller (existing precedence).
const settingsAmount = () => v.number(INVALID_SETTINGS);
export const updateFareCodSettingsSchema = {
  deliveryFee: settingsAmount(),
  freeDeliveryThreshold: settingsAmount(),
  minimumOrderAmount: settingsAmount(),
  codCharge: settingsAmount(),
  minimumCodOrderAmount: settingsAmount(),
  maximumCodOrderAmount: settingsAmount(),
  deliveryEnabled: strictBoolean(INVALID_SETTINGS),
  codEnabled: strictBoolean(INVALID_SETTINGS),
  pickupCodEnabled: strictBoolean(INVALID_SETTINGS),
} satisfies Schema;

// ---------- Store managers ----------

const MANAGER_MISSING = { errorCode: 'MISSING_PARAMETERS', message: 'All fields (name, email, password, storeId) are required.' };
const MANAGER_EMAIL = { errorCode: 'INVALID_EMAIL', message: 'Invalid email format.', pattern: EMAIL_PATTERN };
const password = (missing?: { errorCode: string; message: string }): Parser<string | undefined> => (value) => {
  if (value === undefined || value === null || value === '') {
    return missing ? { ok: false, issue: missing } : { ok: true, value: undefined };
  }
  return typeof value === 'string' ? { ok: true, value } : { ok: false, issue: INVALID_VALUES };
};

export const createManagerSchema = {
  name: v.requiredString(MANAGER_MISSING),
  email: v.requiredString({ ...MANAGER_EMAIL, missing: MANAGER_MISSING }),
  password: password(MANAGER_MISSING) as Parser<string>,
  storeId: v.requiredString(MANAGER_MISSING),
  isActive: strictBoolean(INVALID_VALUES),
} satisfies Schema;

export const updateManagerSchema = {
  name: v.optionalString(INVALID_VALUES),
  email: v.optionalString(MANAGER_EMAIL),
  password: password(),
  storeId: v.optionalString(INVALID_VALUES),
  isActive: strictBoolean(INVALID_VALUES),
} satisfies Schema;

// ---------- Customers ----------

const CUSTOMER_STATUS = { errorCode: 'INVALID_PARAMETERS', message: 'isActive boolean parameter is required.' };
export const updateCustomerStatusSchema = {
  isActive: ((value) =>
    typeof value === 'boolean' ? { ok: true, value } : { ok: false, issue: CUSTOMER_STATUS }) as Parser<boolean>,
} satisfies Schema;

// ---------- Stores ----------

const STORE_MISSING = { errorCode: 'MISSING_PARAMETERS', message: 'All fields are required, including coordinate values.' };
const STORE_PINCODE = { errorCode: 'INVALID_PINCODE', message: 'Pincode must be exactly 6 digits.', pattern: /^\d{6}$/ };
// Store contact numbers are not customer accounts (D-008 does not apply); same E.164 shape the admin form checks.
const STORE_PHONE = { errorCode: 'VALIDATION_ERROR', message: 'Invalid store phone number.', pattern: /^\+?[1-9][\d\s\-()]{1,20}$/ };
const STORE_EMAIL = { errorCode: 'INVALID_EMAIL', message: 'Invalid email format.', pattern: EMAIL_PATTERN };
const STORE_RADIUS = { errorCode: 'VALIDATION_ERROR', message: 'Delivery radius must be a positive number.', positive: true };
const storeText = (missing?: typeof STORE_MISSING) =>
  missing ? v.requiredString({ ...INVALID_VALUES, missing }) : v.optionalString(INVALID_VALUES);

export const createStoreSchema = {
  storeId: storeText(STORE_MISSING) as Parser<string>,
  name: storeText(STORE_MISSING) as Parser<string>,
  address: storeText(STORE_MISSING) as Parser<string>,
  city: storeText(STORE_MISSING) as Parser<string>,
  state: storeText(STORE_MISSING) as Parser<string>,
  pincode: v.requiredString({ ...STORE_PINCODE, missing: STORE_MISSING }),
  latitude: v.number({ ...COORDINATES, min: -90, max: 90, required: STORE_MISSING }) as Parser<number>,
  longitude: v.number({ ...COORDINATES, min: -180, max: 180, required: STORE_MISSING }) as Parser<number>,
  deliveryRadiusKm: v.number({ ...STORE_RADIUS, required: STORE_MISSING }) as Parser<number>,
  phone: v.requiredString({ ...STORE_PHONE, missing: STORE_MISSING }),
  openingTime: storeText(STORE_MISSING) as Parser<string>,
  closingTime: storeText(STORE_MISSING) as Parser<string>,
  email: v.nullableString(STORE_EMAIL),
} satisfies Schema;

export const updateStoreSchema = {
  name: storeText(),
  address: storeText(),
  city: storeText(),
  state: storeText(),
  pincode: v.optionalString(STORE_PINCODE),
  latitude: v.number({ ...COORDINATES, min: -90, max: 90 }),
  longitude: v.number({ ...COORDINATES, min: -180, max: 180 }),
  deliveryRadiusKm: v.number(STORE_RADIUS),
  phone: v.optionalString(STORE_PHONE),
  openingTime: storeText(),
  closingTime: storeText(),
  email: v.nullableString(STORE_EMAIL),
  isActive: strictBoolean(INVALID_VALUES),
} satisfies Schema;

// ---------- Banners ----------

const displayOrder = v.number({ errorCode: 'VALIDATION_ERROR', message: 'Display order must be a whole number.', min: 0 });
const wholeDisplayOrder: Parser<number | null | undefined> = (value) => {
  const result = displayOrder(value);
  if (result.ok && typeof result.value === 'number' && !Number.isInteger(result.value)) {
    return { ok: false, issue: { errorCode: 'VALIDATION_ERROR', message: 'Display order must be a whole number.' } };
  }
  return result;
};

const BANNER_IMAGE = { errorCode: 'IMAGE_URL_REQUIRED', message: 'Banner image URL is required.' };
export const createBannerSchema = {
  title: v.optionalText(INVALID_VALUES),
  imageUrl: v.requiredString(BANNER_IMAGE),
  displayOrder: wholeDisplayOrder,
  isActive: strictBoolean(INVALID_VALUES),
} satisfies Schema;

export const updateBannerSchema = {
  title: v.optionalText(INVALID_VALUES),
  imageUrl: v.optionalString({ errorCode: 'IMAGE_URL_REQUIRED', message: 'Banner image URL cannot be empty.' }),
  displayOrder: wholeDisplayOrder,
  isActive: strictBoolean(INVALID_VALUES),
} satisfies Schema;

// ---------- Supported pincodes ----------

const PINCODE_FORMAT = { errorCode: 'INVALID_PINCODE_FORMAT', message: 'A valid 6-digit numeric pincode is required.', pattern: /^\d{6}$/ };
export const createPincodeSchema = {
  pincode: v.requiredString(PINCODE_FORMAT),
  city: v.optionalText(INVALID_VALUES),
  state: v.optionalText(INVALID_VALUES),
  isActive: strictBoolean(INVALID_VALUES),
} satisfies Schema;

export const updatePincodeSchema = {
  pincode: v.optionalString(PINCODE_FORMAT),
  city: v.optionalText(INVALID_VALUES),
  state: v.optionalText(INVALID_VALUES),
  isActive: strictBoolean(INVALID_VALUES),
} satisfies Schema;

export const togglePincodeStatusSchema = {
  isActive: strictBoolean(INVALID_VALUES),
} satisfies Schema;

// ---------- Categories ----------

export const createCategorySchema = {
  name: v.requiredString({ ...INVALID_VALUES, missing: { errorCode: 'MISSING_PARAMETERS', message: 'Category name is required.' }, max: { length: 100, ...INVALID_VALUES } }),
  description: v.optionalText(INVALID_VALUES),
  imageUrl: v.optionalText(INVALID_VALUES),
  displayOrder: wholeDisplayOrder,
} satisfies Schema;

export const updateCategorySchema = {
  name: v.optionalString({ ...INVALID_VALUES, max: { length: 100, ...INVALID_VALUES } }),
  description: v.optionalText(INVALID_VALUES),
  imageUrl: v.optionalText(INVALID_VALUES),
  displayOrder: wholeDisplayOrder,
  isActive: strictBoolean(INVALID_VALUES),
} satisfies Schema;

// ---------- Store inventory ----------

export const updateStoreInventorySchema = {
  adjustmentType: v.oneOf(['ADD', 'REMOVE', 'SET'] as const, { errorCode: 'INVALID_ADJUSTMENT_TYPE', message: 'Invalid adjustment type.' }),
  // Required when adjustmentType is set (checked in the controller, existing message).
  quantity: v.number({ errorCode: 'INVALID_QUANTITY', message: 'Quantity must be a positive number.', min: 0 }),
  stockQuantity: v.number({ errorCode: 'INVALID_QUANTITY', message: 'Stock Quantity must be a number.' }),
  lowStockThreshold: v.number({ ...INVALID_VALUES, min: 0 }),
  isAvailable: strictBoolean(INVALID_VALUES),
  reason: v.optionalText({ ...INVALID_VALUES, maxLength: 500 }),
} satisfies Schema;
