import { act } from 'react';
import { createRoot, type Root } from 'react-dom/client';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { useLoader } from './useLoader';

// Admin data loading without synchronous setState in effects.
(globalThis as { IS_REACT_ACT_ENVIRONMENT?: boolean }).IS_REACT_ACT_ENVIRONMENT = true;

type Snapshot = { loading: boolean; error: string | null; reload: () => void };

describe('useLoader', () => {
  let container: HTMLDivElement;
  let root: Root;
  let latest: Snapshot;

  beforeEach(() => {
    container = document.createElement('div');
    document.body.appendChild(container);
    root = createRoot(container);
  });

  afterEach(() => {
    act(() => root.unmount());
    container.remove();
  });

  function Probe({ load, dep, onError }: { load: () => Promise<void>; dep: number; onError?: (m: string) => void }) {
    latest = useLoader(load, [dep], { onError, errorMessage: () => 'boom' });
    return null;
  }

  const flush = () => act(async () => { await Promise.resolve(); await Promise.resolve(); });

  it('is loading until the request settles, then clears', async () => {
    let resolve!: () => void;
    const load = vi.fn(() => new Promise<void>((r) => (resolve = r)));
    act(() => root.render(<Probe load={load} dep={1} />));
    expect(latest.loading).toBe(true);
    await act(async () => resolve());
    expect(latest).toMatchObject({ loading: false, error: null });
    expect(load).toHaveBeenCalledTimes(1);
  });

  it('reports errors through errorMessage and onError', async () => {
    const onError = vi.fn();
    act(() => root.render(<Probe load={() => Promise.reject(new Error('x'))} dep={1} onError={onError} />));
    vi.spyOn(console, 'error').mockImplementation(() => {});
    await flush();
    expect(latest).toMatchObject({ loading: false, error: 'boom' });
    expect(onError).toHaveBeenCalledWith('boom');
  });

  it('reloads when deps change or reload() is called', async () => {
    const load = vi.fn(() => Promise.resolve());
    act(() => root.render(<Probe load={load} dep={1} />));
    await flush();
    act(() => root.render(<Probe load={load} dep={2} />));
    expect(latest.loading).toBe(true);
    await flush();
    act(() => latest.reload());
    await flush();
    expect(load).toHaveBeenCalledTimes(3);
    expect(latest.loading).toBe(false);
  });

  it('ignores a superseded request that settles late', async () => {
    const resolvers: (() => void)[] = [];
    const load = vi.fn(() => new Promise<void>((r) => resolvers.push(r)));
    act(() => root.render(<Probe load={load} dep={1} />));
    act(() => root.render(<Probe load={load} dep={2} />));
    await act(async () => resolvers[0]());
    expect(latest.loading).toBe(true);
    await act(async () => resolvers[1]());
    expect(latest.loading).toBe(false);
  });
});
