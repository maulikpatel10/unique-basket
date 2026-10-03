import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { ok, renderPage, type PageHarness } from '../test/pageHarness';

const api = vi.hoisted(() => ({ get: vi.fn() }));
vi.mock('../services/api', () => ({ api }));
// A new user object on every call: the dashboard must load once, not on every render.
vi.mock('../context/authContextStore', () => ({ useAuth: () => ({ user: { id: 'a1', role: 'SUPER_ADMIN' } }) }));

import { Dashboard } from './Dashboard';

describe('Dashboard page', () => {
  let page: PageHarness;

  beforeEach(async () => {
    api.get.mockReset().mockResolvedValue(
      ok({ totalOrders: 12, pendingOrders: 3, revenue: 4560, activeStores: 2, recentOrders: [] }),
    );
    page = renderPage(<Dashboard />);
    await page.settle();
  });

  afterEach(() => page.unmount());

  it('loads the server-side summary once', () => {
    expect(api.get).toHaveBeenCalledTimes(1);
    expect(api.get).toHaveBeenCalledWith('/admin/dashboard/summary');
    expect(page.text()).toContain('12');
  });
});
