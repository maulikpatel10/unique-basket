import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { apiError, ok, renderPage, type PageHarness } from '../test/pageHarness';

const api = vi.hoisted(() => ({ get: vi.fn(), put: vi.fn() }));
vi.mock('../services/api', () => ({ api }));
// Stable object: in the app `user` is React state, so it keeps its identity between renders
const auth = vi.hoisted(() => ({ user: { role: 'SUPER_ADMIN' } }));
vi.mock('../context/authContextStore', () => ({ useAuth: () => auth }));

import { Orders } from './Orders';

const order = {
  id: 'o1', orderNumber: '#UB-031026-001', createdAt: '2026-10-03T10:00:00Z', fulfillmentType: 'DELIVERY',
  orderStatus: 'PLACED', paymentStatus: 'PENDING', paymentMethod: 'COD', subtotal: 360, deliveryFee: 0, discount: 0, total: 380,
  user: { id: 'u1', name: 'Asha', phone: '+919876543210' }, store: { id: 'store-1', name: 'Rajkot Central', storeId: 'STORE-001' },
};

describe('Orders page', () => {
  let page: PageHarness;
  const ordersCalls = () => api.get.mock.calls.filter(([url]) => url === '/admin/orders');
  const lastOrdersParams = () => ordersCalls()[ordersCalls().length - 1][1].params;

  beforeEach(async () => {
    Object.values(api).forEach((m) => m.mockReset());
    api.get.mockImplementation((url: string) =>
      Promise.resolve(
        url === '/admin/stores'
          ? ok([order.store])
          : ok({ orders: [order], pagination: { total: 1, page: 1, limit: 10, totalPages: 1 } }),
      ),
    );
    page = renderPage(<Orders />);
    await page.settle();
  });

  afterEach(() => page.unmount());

  it('lists orders on page 1', () => {
    expect(page.text()).toContain('#UB-031026-001');
    expect(page.text()).toContain('Asha');
    expect(lastOrdersParams()).toMatchObject({ page: 1, limit: 10 });
  });

  it('filters by status on the server', async () => {
    const statusSelect = [...page.container.querySelectorAll('select')].find((s) =>
      [...s.options].some((o) => o.value === 'CANCELLED'),
    )!;
    page.type(statusSelect, 'CANCELLED');
    await page.settle();
    expect(lastOrdersParams()).toMatchObject({ page: 1, status: 'CANCELLED' });
  });

  it('cancels an order after confirmation and reloads the list', async () => {
    api.put.mockResolvedValue(ok({}));
    const before = ordersCalls().length;
    page.click(page.button('Cancel Order'));
    expect(page.text()).toContain('Keep Order');

    const confirm = [...page.container.querySelectorAll('button')].filter((b) => (b.textContent ?? '').trim() === 'Cancel Order').pop()!;
    page.click(confirm);
    await page.settle();

    expect(api.put).toHaveBeenCalledWith('/admin/orders/o1/status', { status: 'CANCELLED' });
    expect(page.text()).toContain('Order #UB-031026-001 has been cancelled.');
    expect(ordersCalls().length).toBeGreaterThan(before);
  });

  it('shows the server message when cancellation is rejected', async () => {
    api.put.mockRejectedValue(apiError('Order status was changed by another request. Please refresh and try again.', 409));
    vi.spyOn(console, 'error').mockImplementation(() => {});
    page.click(page.button('Cancel Order'));
    const confirm = [...page.container.querySelectorAll('button')].filter((b) => (b.textContent ?? '').trim() === 'Cancel Order').pop()!;
    page.click(confirm);
    await page.settle();
    expect(page.text()).toContain('Order status was changed by another request.');
  });
});
