import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { apiError, ok, renderPage, type PageHarness } from '../test/pageHarness';

const api = vi.hoisted(() => ({ get: vi.fn(), put: vi.fn() }));
vi.mock('../services/api', () => ({ api }));
const auth = vi.hoisted(() => ({ user: { role: 'SUPER_ADMIN' } }));
vi.mock('../context/authContextStore', () => ({ useAuth: () => auth }));

import { Settings } from './Settings';

// D-009 values as returned by the API (decimals as strings)
const settings = {
  id: 's1', deliveryEnabled: true, deliveryFee: '30.00', freeDeliveryThreshold: '200.00', minimumOrderAmount: '199.00',
  codEnabled: true, codCharge: '20.00', minimumCodOrderAmount: '100.00', maximumCodOrderAmount: '5000.00',
  pickupCodEnabled: true, updatedAt: '2026-10-03T00:00:00Z',
};

describe('Settings page (fares & COD)', () => {
  let page: PageHarness;
  const numberInputs = () => [...page.container.querySelectorAll<HTMLInputElement>('input[type="number"]')];
  const form = () => page.field<HTMLFormElement>('form');

  beforeEach(async () => {
    api.get.mockReset().mockResolvedValue(ok(settings));
    api.put.mockReset();
    page = renderPage(<Settings />);
    await page.settle();
  });

  afterEach(() => page.unmount());

  it('loads the current settings into the form', () => {
    expect(api.get).toHaveBeenCalledWith('/admin/settings/fare-cod');
    expect(numberInputs().map((i) => i.value)).toEqual(['30', '200', '199', '20', '100', '5000']);
  });

  it('rejects negative values and an inverted COD range without saving', async () => {
    page.type(numberInputs()[0], '-5');
    page.submit(form());
    await page.settle();
    expect(page.text()).toContain('Delivery fee cannot be negative.');

    page.type(numberInputs()[0], '30');
    page.type(numberInputs()[4], '6000');
    page.submit(form());
    await page.settle();
    expect(page.text()).toContain('Minimum COD amount cannot exceed maximum COD amount.');
    expect(api.put).not.toHaveBeenCalled();
  });

  it('saves edited values and shows the confirmation', async () => {
    api.put.mockResolvedValue(ok({ ...settings, deliveryFee: '35.00' }, 'Settings saved.'));
    page.type(numberInputs()[0], '35');
    page.submit(form());
    await page.settle();

    expect(api.put).toHaveBeenCalledWith('/admin/settings/fare-cod', expect.objectContaining({ deliveryFee: 35, freeDeliveryThreshold: 200 }));
    expect(page.text()).toContain('Settings saved.');
    expect(numberInputs()[0].value).toBe('35');
  });

  it('shows the server error when saving fails', async () => {
    api.put.mockRejectedValue(apiError('Minimum COD amount cannot be greater than maximum COD amount.'));
    vi.spyOn(console, 'error').mockImplementation(() => {});
    page.submit(form());
    await page.settle();
    expect(page.text()).toContain('Minimum COD amount cannot be greater than maximum COD amount.');
  });
});
