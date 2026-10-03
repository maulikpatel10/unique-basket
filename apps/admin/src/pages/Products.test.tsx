import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { apiError, ok, renderPage, type PageHarness } from '../test/pageHarness';

const api = vi.hoisted(() => ({ get: vi.fn(), post: vi.fn(), put: vi.fn(), delete: vi.fn() }));
vi.mock('../services/api', () => ({ api }));
vi.mock('../context/authContextStore', () => ({ useAuth: () => ({ user: { role: 'SUPER_ADMIN' } }) }));

import { Products } from './Products';

const categories = [{ id: 'cat-1', name: 'Vegetables', isActive: true }];
const potato = {
  id: 'p1', name: 'Potato', description: null, imageUrl: null, categoryId: 'cat-1', category: { name: 'Vegetables' },
  unit: 'KG', price: '30.00', mrp: null, isActive: true, createdAt: '',
  minQuantity: '1.000', maxQuantity: '10.000', quantityStep: '0.250',
};
const coconut = { ...potato, id: 'p2', name: 'Coconut', unit: 'PIECE', minQuantity: null, maxQuantity: null, quantityStep: null };

describe('Products page', () => {
  let page: PageHarness;

  beforeEach(async () => {
    Object.values(api).forEach((m) => m.mockReset());
    api.get.mockImplementation((url: string) =>
      Promise.resolve(
        url === '/categories'
          ? ok(categories)
          : ok({ products: [potato, coconut], pagination: { total: 2, page: 1, limit: 20, totalPages: 1 } }),
      ),
    );
    page = renderPage(<Products />);
    await page.settle();
  });

  afterEach(() => page.unmount());

  it('lists products with their quantity rules', () => {
    expect(page.text()).toContain('Potato');
    expect(page.text()).toContain('1–10 KG · step 0.25');
    expect(page.text()).toContain('Quantity rules not set');
    expect(api.get).toHaveBeenCalledWith('/products', { params: { page: 1, limit: 20 } });
  });

  const openCreate = () => page.click(page.button('Add Product'));
  const fill = (name: string, value: string) => page.type(page.field(`[name="${name}"]`), value);
  const saveForm = () => page.submit(page.field<HTMLFormElement>('form:has([name="price"])'));

  it('blocks an invalid quantity configuration before calling the API', async () => {
    openCreate();
    fill('name', 'Apple');
    fill('price', '180');
    fill('minQuantity', '1');
    fill('maxQuantity', '10');
    fill('quantityStep', '0.4');
    saveForm();
    await page.settle();

    expect(page.text()).toContain('Maximum must be reachable from minimum in whole steps');
    expect(api.post).not.toHaveBeenCalled();
  });

  it('creates a product with its quantity rules', async () => {
    api.post.mockResolvedValue(ok({ id: 'p3' }));
    openCreate();
    fill('name', 'Apple');
    fill('price', '180');
    fill('minQuantity', '0.5');
    fill('maxQuantity', '5');
    fill('quantityStep', '0.25');
    saveForm();
    await page.settle();

    expect(api.post).toHaveBeenCalledWith(
      '/products',
      expect.objectContaining({ name: 'Apple', categoryId: 'cat-1', unit: 'KG', price: 180, minQuantity: 0.5, maxQuantity: 5, quantityStep: 0.25 }),
    );
    expect(page.text()).toContain('Product registered successfully.');
  });

  it('shows the server message when saving fails', async () => {
    api.post.mockRejectedValue(apiError('Category with this name already exists.'));
    vi.spyOn(console, 'error').mockImplementation(() => {});
    openCreate();
    fill('name', 'Apple');
    fill('price', '180');
    saveForm();
    await page.settle();
    expect(page.text()).toContain('Category with this name already exists.');
  });
});
