import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { ok, renderPage, type PageHarness } from '../test/pageHarness';

const api = vi.hoisted(() => ({ get: vi.fn(), post: vi.fn(), put: vi.fn() }));
vi.mock('../services/api', () => ({ api }));

import { Managers } from './Managers';

const stores = [{ id: 'store-1', storeId: 'STORE-001', name: 'Rajkot Central', city: 'Rajkot', isActive: true }];
const manager = {
  id: 'm1', name: 'Rahul Sharma', email: 'rahul@uniquebasket.com', role: 'STORE_MANAGER', isActive: true,
  createdAt: '', updatedAt: '', storeId: 'store-1', storeIdString: 'STORE-001', storeName: 'Rajkot Central',
};

describe('Managers page', () => {
  let page: PageHarness;
  const fill = (name: string, value: string) =>
    page.type(page.field<HTMLInputElement | HTMLSelectElement>(`[name="${name}"]`), value);
  const saveForm = () => page.submit(page.field<HTMLFormElement>('form:has([name="email"])'));

  beforeEach(async () => {
    Object.values(api).forEach((m) => m.mockReset());
    api.get.mockImplementation((url: string) =>
      Promise.resolve(
        url === '/stores'
          ? ok(stores)
          : ok({ managers: [manager], pagination: { total: 1, page: 1, limit: 20, totalPages: 1 } }),
      ),
    );
    page = renderPage(<Managers />);
    await page.settle();
  });

  afterEach(() => page.unmount());

  it('lists managers with their store', () => {
    expect(page.text()).toContain('Rahul Sharma');
    expect(page.text()).toContain('rahul@uniquebasket.com');
  });

  it('validates the registration form before calling the API', async () => {
    page.click(page.button('Register Store Manager'));
    fill('name', 'Asha Patel');
    fill('email', 'not-an-email');
    fill('password', '123');
    saveForm();
    await page.settle();

    expect(page.text()).toContain('Please enter a valid email format');
    expect(page.text()).toContain('Password must be at least 6 characters');
    expect(api.post).not.toHaveBeenCalled();
  });

  it('registers a manager assigned to a store', async () => {
    api.post.mockResolvedValue(ok({ id: 'm2' }));
    page.click(page.button('Register Store Manager'));
    fill('name', 'Asha Patel');
    fill('email', 'asha@uniquebasket.com');
    fill('password', 'Secret#123');
    fill('storeId', 'store-1');
    saveForm();
    await page.settle();

    expect(api.post).toHaveBeenCalledWith('/admin/managers', {
      name: 'Asha Patel',
      email: 'asha@uniquebasket.com',
      password: 'Secret#123',
      storeId: 'store-1',
      isActive: true,
    });
    expect(page.text()).toContain('New Store Manager created successfully.');
  });

  it('deactivates a manager only after confirmation', async () => {
    api.put.mockResolvedValue(ok({}));
    const statusToggle = [...page.container.querySelectorAll('button')].find((b) => (b.textContent ?? '').trim() === 'ACTIVE');
    expect(statusToggle).toBeDefined();
    page.click(statusToggle!);
    expect(page.text()).toContain('Deactivate Store Manager?');
    expect(api.put).not.toHaveBeenCalled();

    page.click(page.button('Yes, Deactivate'));
    await page.settle();
    expect(api.put).toHaveBeenCalledWith('/admin/managers/m1', { isActive: false });
    expect(page.text()).toContain('Manager Rahul Sharma deactivated successfully.');
  });
});
