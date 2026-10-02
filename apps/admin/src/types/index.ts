export type AdminRole = 'SUPER_ADMIN' | 'STORE_MANAGER';

export interface AdminUser {
  id: string;
  email: string;
  name: string;
  role: AdminRole;
  isActive: boolean;
  storeId?: string; // Present if role is STORE_MANAGER
}

export interface Store {
  id: string;
  storeId: string;
  name: string;
  address: string;
  city: string;
  state: string;
  pincode: string;
  latitude: number;
  longitude: number;
  deliveryRadiusKm: number;
  phone: string;
  email?: string;
  openingTime: string;
  closingTime: string;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export type ProductUnit = 'KG' | 'GRAM' | 'PIECE' | 'PACK' | 'DOZEN';

export interface Product {
  id: string;
  name: string;
  description?: string;
  categoryId: string;
  categoryName?: string;
  unit: ProductUnit;
  price: number;
  mrp?: number;
  isActive: boolean;
}

export interface Category {
  id: string;
  name: string;
  imageUrl?: string;
  displayOrder: number;
  isActive: boolean;
}

export interface StoreInventoryItem {
  id: string;
  name: string;
  description?: string;
  categoryId: string;
  categoryName: string;
  unit: ProductUnit;
  price: number;
  mrp?: number;
  stockQuantity: number;
  lowStockThreshold: number;
  isAvailable: boolean;
}

export type FulfillmentType = 'DELIVERY' | 'PICKUP';
export type PaymentMethod = 'COD' | 'ONLINE';
export type PaymentStatus = 'PENDING' | 'PAID' | 'FAILED';
export type OrderStatus =
  | 'PLACED'
  | 'CONFIRMED'
  | 'PREPARING'
  | 'READY_FOR_PICKUP'
  | 'PICKED_UP'
  | 'OUT_FOR_DELIVERY'
  | 'DELIVERED'
  | 'CANCELLED';

export interface Order {
  id: string;
  orderNumber: string;
  userId: string;
  fulfillmentType: FulfillmentType;
  addressId?: string;
  subtotal: number;
  deliveryFee: number;
  total: number;
  paymentMethod: PaymentMethod;
  paymentStatus: PaymentStatus;
  orderStatus: OrderStatus;
  createdAt: string;
  updatedAt: string;
  user?: {
    name?: string;
    phone: string;
  };
  store?: {
    name: string;
    storeId: string;
  };
  address?: {
    addressLine: string;
    city: string;
  };
  items?: OrderItem[];
}

export interface OrderItem {
  id: string;
  productId: string;
  quantity: number;
  unitPrice: number;
  totalPrice: number;
  product?: {
    name: string;
    unit: ProductUnit;
  };
}

export interface DeliverySettings {
  id?: string;
  deliveryEnabled: boolean;
  deliveryFee: number;
  freeDeliveryThreshold: number;
  minimumOrderAmount: number;
  codEnabled: boolean;
  codCharge: number;
  minimumCodOrderAmount: number;
  maximumCodOrderAmount: number;
  pickupCodEnabled: boolean;
  updatedAt?: string;
}

export interface AuditLog {
  id: string;
  adminUserId?: string;
  action: string;
  details?: string;
  createdAt: string;
  adminUser?: {
    name: string;
    email: string;
  };
}

export interface SupportedPincode {
  id: string;
  pincode: string;
  city: string;
  state: string;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

