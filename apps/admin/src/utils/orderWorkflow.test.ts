import { describe, expect, it } from 'vitest';
import { canCancelOrder, getNextOrderAction, isAwaitingOnlinePayment } from './orderWorkflow';

describe('orderWorkflow', () => {
  it('walks the DELIVERY path for paid/COD orders', () => {
    expect(getNextOrderAction('PLACED', 'DELIVERY', 'COD', 'PENDING')?.nextStatus).toBe('CONFIRMED');
    expect(getNextOrderAction('CONFIRMED', 'DELIVERY', 'COD', 'PENDING')?.nextStatus).toBe('PREPARING');
    expect(getNextOrderAction('PREPARING', 'DELIVERY', 'COD', 'PENDING')?.nextStatus).toBe('READY_FOR_PICKUP');
    expect(getNextOrderAction('READY_FOR_PICKUP', 'DELIVERY', 'COD', 'PENDING')?.nextStatus).toBe('OUT_FOR_DELIVERY');
    expect(getNextOrderAction('OUT_FOR_DELIVERY', 'DELIVERY', 'COD', 'PENDING')?.nextStatus).toBe('DELIVERED');
    expect(getNextOrderAction('DELIVERED', 'DELIVERY', 'COD', 'PAID')).toBeNull();
  });

  it('routes PICKUP completion through pickup verification (D-006)', () => {
    const action = getNextOrderAction('READY_FOR_PICKUP', 'PICKUP', 'COD', 'PENDING');
    expect(action?.nextStatus).toBe('PICKED_UP');
    expect(action?.requiresPickupVerification).toBe(true);
    expect(action?.actionLabel).toBe('Verify Pickup');
    expect(getNextOrderAction('OUT_FOR_DELIVERY', 'PICKUP', 'COD', 'PENDING')).toBeNull();
  });

  it('offers no workflow action for unpaid ONLINE orders (D-005)', () => {
    for (const paymentStatus of ['PENDING', 'FAILED']) {
      expect(getNextOrderAction('PLACED', 'DELIVERY', 'ONLINE', paymentStatus)).toBeNull();
      expect(isAwaitingOnlinePayment('PLACED', 'ONLINE', paymentStatus)).toBe(true);
    }
    expect(getNextOrderAction('PLACED', 'DELIVERY', 'ONLINE', 'PAID')?.nextStatus).toBe('CONFIRMED');
    expect(isAwaitingOnlinePayment('CANCELLED', 'ONLINE', 'PENDING')).toBe(false);
  });

  it('allows cancellation only for non-terminal orders', () => {
    expect(canCancelOrder('PLACED')).toBe(true);
    expect(canCancelOrder('READY_FOR_PICKUP')).toBe(true);
    expect(canCancelOrder('DELIVERED')).toBe(false);
    expect(canCancelOrder('PICKED_UP')).toBe(false);
    expect(canCancelOrder('CANCELLED')).toBe(false);
  });
});
