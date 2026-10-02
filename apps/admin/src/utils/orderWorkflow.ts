import type { OrderStatus, FulfillmentType } from '../types';

export interface NextOrderAction {
  nextStatus: OrderStatus;
  actionLabel: string;
  buttonVariant: 'primary' | 'info' | 'cyan' | 'amber' | 'emerald';
  /** When true, the action opens Pickup Verification instead of calling the status endpoint (D-006). */
  requiresPickupVerification?: boolean;
}

/**
 * Unpaid ONLINE orders can only be cancelled until payment is completed (D-005).
 */
export const isAwaitingOnlinePayment = (
  orderStatus: string,
  paymentMethod?: string,
  paymentStatus?: string
): boolean => {
  return (
    paymentMethod === 'ONLINE' &&
    paymentStatus !== 'PAID' &&
    !['DELIVERED', 'PICKED_UP', 'CANCELLED'].includes(orderStatus)
  );
};

/**
 * Returns the exact SINGLE next valid order status and action label based on current status and fulfillment type.
 * Returns null if the order is in a terminal state (DELIVERED, PICKED_UP, CANCELLED).
 */
export const getNextOrderAction = (
  orderStatus: string,
  fulfillmentType: FulfillmentType | string,
  paymentMethod?: string,
  paymentStatus?: string
): NextOrderAction | null => {
  if (isAwaitingOnlinePayment(orderStatus, paymentMethod, paymentStatus)) {
    return null;
  }

  switch (orderStatus) {
    case 'PLACED':
      return {
        nextStatus: 'CONFIRMED',
        actionLabel: 'Confirm Order',
        buttonVariant: 'primary',
      };
    case 'CONFIRMED':
      return {
        nextStatus: 'PREPARING',
        actionLabel: 'Start Preparing',
        buttonVariant: 'info',
      };
    case 'PREPARING':
      return {
        nextStatus: 'READY_FOR_PICKUP',
        actionLabel: 'Mark Ready',
        buttonVariant: 'cyan',
      };
    case 'READY_FOR_PICKUP':
      if (fulfillmentType === 'DELIVERY') {
        return {
          nextStatus: 'OUT_FOR_DELIVERY',
          actionLabel: 'Out for Delivery',
          buttonVariant: 'amber',
        };
      }
      return {
        nextStatus: 'PICKED_UP',
        actionLabel: 'Verify Pickup',
        buttonVariant: 'emerald',
        requiresPickupVerification: true,
      };
    case 'OUT_FOR_DELIVERY':
      if (fulfillmentType === 'DELIVERY') {
        return {
          nextStatus: 'DELIVERED',
          actionLabel: 'Mark Delivered',
          buttonVariant: 'emerald',
        };
      }
      return null;
    default:
      return null;
  }
};

/**
 * Checks if cancellation is allowed for this order status.
 * Terminal states (DELIVERED, PICKED_UP, CANCELLED) cannot be cancelled.
 */
export const canCancelOrder = (orderStatus: string): boolean => {
  return !['DELIVERED', 'PICKED_UP', 'CANCELLED'].includes(orderStatus);
};

/**
 * Returns human-readable label for order statuses.
 */
export const formatOrderStatus = (status: string): string => {
  switch (status) {
    case 'PLACED':
      return 'PLACED';
    case 'CONFIRMED':
      return 'CONFIRMED';
    case 'PREPARING':
      return 'PREPARING';
    case 'READY_FOR_PICKUP':
      return 'READY FOR PICKUP';
    case 'OUT_FOR_DELIVERY':
      return 'OUT FOR DELIVERY';
    case 'DELIVERED':
      return 'DELIVERED';
    case 'PICKED_UP':
      return 'PICKED UP';
    case 'CANCELLED':
      return 'CANCELLED';
    default:
      return status.replace(/_/g, ' ');
  }
};

/**
 * Returns the sequence of workflow steps for progress visualization stepper.
 */
export const getWorkflowSteps = (fulfillmentType: FulfillmentType | string): OrderStatus[] => {
  if (fulfillmentType === 'PICKUP') {
    return ['PLACED', 'CONFIRMED', 'PREPARING', 'READY_FOR_PICKUP', 'PICKED_UP'];
  }
  return ['PLACED', 'CONFIRMED', 'PREPARING', 'READY_FOR_PICKUP', 'OUT_FOR_DELIVERY', 'DELIVERED'];
};
