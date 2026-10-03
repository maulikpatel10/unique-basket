import { act } from 'react';
import { createRoot, type Root } from 'react-dom/client';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { Pagination } from './Pagination';

// P2-07: shared server-side pagination footer.
(globalThis as { IS_REACT_ACT_ENVIRONMENT?: boolean }).IS_REACT_ACT_ENVIRONMENT = true;

describe('Pagination', () => {
  let container: HTMLDivElement;
  let root: Root;

  beforeEach(() => {
    container = document.createElement('div');
    document.body.appendChild(container);
    root = createRoot(container);
  });

  afterEach(() => {
    act(() => root.unmount());
    container.remove();
  });

  const button = (label: string) => container.querySelector(`[aria-label="${label}"]`) as HTMLButtonElement;

  it('shows totals and moves between pages', () => {
    const onPageChange = vi.fn();
    act(() =>
      root.render(
        <Pagination pagination={{ total: 45, page: 2, limit: 20, totalPages: 3 }} itemLabel="products" onPageChange={onPageChange} />,
      ),
    );
    expect(container.textContent).toContain('45 total products');

    act(() => button('Previous page').click());
    act(() => button('Next page').click());
    expect(onPageChange).toHaveBeenNthCalledWith(1, 1);
    expect(onPageChange).toHaveBeenNthCalledWith(2, 3);
  });

  it('disables both buttons when there is only one page', () => {
    act(() =>
      root.render(<Pagination pagination={{ total: 0, page: 1, limit: 20, totalPages: 0 }} itemLabel="stores" onPageChange={vi.fn()} />),
    );
    expect(button('Previous page').disabled).toBe(true);
    expect(button('Next page').disabled).toBe(true);
  });
});
