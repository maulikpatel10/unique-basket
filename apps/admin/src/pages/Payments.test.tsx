import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { ok, renderPage, type PageHarness } from '../test/pageHarness';

const api = vi.hoisted(() => ({ get: vi.fn() }));
vi.mock('../services/api', () => ({ api }));
// Returns a NEW user object on every call (worst case): the page must not refetch or loop.
const auth = vi.hoisted(() => ({ user: { id: 'm1', role: 'STORE_MANAGER', storeId: 'store-1' } }));
vi.mock('../context/authContextStore', () => ({ useAuth: () => ({ user: { ...auth.user } }) }));

import { Payments } from './Payments';

const row = {
  id: 'o1', orderNumber: '#UB-031026-002', createdAt: '2026-10-03T10:00:00Z', updatedAt: '2026-10-03T10:00:00Z',
  fulfillmentType: 'DELIVERY', paymentMethod: 'COD', paymentStatus: 'PENDING', orderStatus: 'PLACED', total: '380.00',
  user: { id: 'u1', name: 'Asha', phone: '+919876543210' }, store: { id: 'store-1', name: 'Rajkot Central', storeId: 'STORE-001' },
  payments: [],
};

describe('Payments page', () => {
  let page: PageHarness;
  const calls = (url: string) => api.get.mock.calls.filter(([u]) => u === url);

  beforeEach(async () => {
    api.get.mockReset().mockImplementation((url: string) =>
      Promise.resolve(
        url === '/admin/stores'
          ? ok([row.store])
          : ok({ payments: [row], pagination: { total: 1, page: 1, limit: 10, totalPages: 1 } }),
      ),
    );
    page = renderPage(<Payments />);
    await page.settle();
  });

  afterEach(() => page.unmount());

  it("scopes a store manager to their store and lists payments", () => {
    expect(page.text()).toContain('#UB-031026-002');
    const last = calls('/admin/payments').pop()![1].params;
    expect(last).toMatchObject({ page: 1, storeId: 'store-1' });
  });

  it('does not refetch stores when re-rendering with a new (equal) user object', async () => {
    expect(calls('/admin/stores')).toHaveLength(1);
    const paymentsBefore = calls('/admin/payments').length;

    // Typing re-renders the page several times (each render gets a fresh user object)
    const search = page.field('input[placeholder^="Search by order #"]');
    for (const value of ['A', 'As', 'Ash']) page.type(search, value);
    await page.settle();

    expect(calls('/admin/stores')).toHaveLength(1);
    expect(calls('/admin/payments')).toHaveLength(paymentsBefore);
  });
});
