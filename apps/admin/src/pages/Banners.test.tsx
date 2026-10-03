import { act } from 'react';
import { createRoot, type Root } from 'react-dom/client';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

// Page-level check of the useLoader/usePageState data flow (paging, search submit, errors).
const get = vi.fn();
vi.mock('../services/api', () => ({ api: { get: (...args: unknown[]) => get(...args) } }));
vi.mock('../context/authContextStore', () => ({ useAuth: () => ({ user: { role: 'SUPER_ADMIN' } }) }));

import { Banners } from './Banners';

(globalThis as { IS_REACT_ACT_ENVIRONMENT?: boolean }).IS_REACT_ACT_ENVIRONMENT = true;

const page = (n: number, totalPages = 3) => ({
  data: {
    data: {
      banners: [{ id: `b${n}`, title: `Banner page ${n}`, imageUrl: 'https://example.com/b.png', displayOrder: n, isActive: true, createdAt: '', updatedAt: '' }],
      pagination: { total: totalPages * 10, page: n, limit: 10, totalPages },
    },
  },
});

describe('Banners page data loading', () => {
  let container: HTMLDivElement;
  let root: Root;

  beforeEach(() => {
    get.mockReset();
    container = document.createElement('div');
    document.body.appendChild(container);
    root = createRoot(container);
  });

  afterEach(() => {
    act(() => root.unmount());
    container.remove();
  });

  const settle = () => act(async () => { for (let i = 0; i < 5; i++) await Promise.resolve(); });
  const lastParams = () => get.mock.calls[get.mock.calls.length - 1][1].params;
  const buttonWithIcon = (icon: string) =>
    [...container.querySelectorAll('button')].find((b) => b.querySelector(`.lucide-${icon}`)) as HTMLButtonElement;

  it('loads page 1, then pages forward', async () => {
    get.mockImplementation((_url: string, { params }: { params: { page: number } }) => Promise.resolve(page(params.page)));
    act(() => root.render(<Banners />));
    await settle();
    expect(lastParams()).toMatchObject({ page: 1, limit: 10 });
    expect(container.textContent).toContain('Banner page 1');

    act(() => buttonWithIcon('chevron-right').click());
    await settle();
    expect(lastParams()).toMatchObject({ page: 2 });
    expect(container.textContent).toContain('Banner page 2');
  });

  it('applies the search on submit and returns to page 1', async () => {
    get.mockImplementation((_url: string, { params }: { params: { page: number } }) => Promise.resolve(page(params.page)));
    act(() => root.render(<Banners />));
    await settle();
    act(() => buttonWithIcon('chevron-right').click());
    await settle();

    const input = container.querySelector('input[placeholder="Search banner title..."]') as HTMLInputElement;
    act(() => {
      const setter = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value')!.set!;
      setter.call(input, '  diwali ');
      input.dispatchEvent(new Event('input', { bubbles: true }));
    });
    act(() => input.form!.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true })));
    await settle();
    expect(lastParams()).toMatchObject({ page: 1, search: 'diwali' });
  });

  it('shows the API error message and retries', async () => {
    vi.spyOn(console, 'error').mockImplementation(() => {});
    get.mockRejectedValueOnce({ response: { data: { message: 'Banner service down' } } });
    act(() => root.render(<Banners />));
    await settle();
    expect(container.textContent).toContain('Banner service down');

    get.mockResolvedValueOnce(page(1));
    const retry = [...container.querySelectorAll('button')].find((b) => b.textContent?.includes('Retry'))!;
    act(() => retry.click());
    await settle();
    expect(container.textContent).toContain('Banner page 1');
    expect(get).toHaveBeenCalledTimes(2);
  });
});
