import { useCallback, useEffect, useRef, useState } from 'react';
import { asApiError } from '../utils/apiError';

export interface LoaderOptions {
  /** Maps a failed request to the message shown on the page. Defaults to the API message or a generic one. */
  errorMessage?: (error: unknown) => string;
  /** Side effect on failure (e.g. a toast). Runs after the request settles. */
  onError?: (message: string) => void;
}

const defaultMessage = (error: unknown) =>
  asApiError(error).response?.data?.message || 'Failed to load data. Please try again.';

/**
 * Runs `load` whenever `deps` change (and on `reload()`), exposing `loading` / `error`.
 *
 * `load` fetches and stores its data (setState after the request resolves). The hook never sets
 * state synchronously inside the effect — `loading` is derived from whether the latest request
 * has settled — which satisfies react-hooks/set-state-in-effect. Responses from superseded
 * requests are ignored. `deps` must be primitives (they are serialised into the request key).
 */
export function useLoader(
  load: () => Promise<void>,
  deps: ReadonlyArray<string | number | boolean | null | undefined>,
  options: LoaderOptions = {},
) {
  const [reloadCount, setReloadCount] = useState(0);
  const [settled, setSettled] = useState<{ key: string; error: string | null } | null>(null);

  const loadRef = useRef(load);
  const optionsRef = useRef(options);
  useEffect(() => {
    loadRef.current = load;
    optionsRef.current = options;
  });

  const key = JSON.stringify([...deps, reloadCount]);

  useEffect(() => {
    let active = true;
    loadRef.current().then(
      () => {
        if (active) setSettled({ key, error: null });
      },
      (caught: unknown) => {
        if (!active) return;
        console.error('Request failed:', caught);
        const message = (optionsRef.current.errorMessage ?? defaultMessage)(caught);
        setSettled({ key, error: message });
        optionsRef.current.onError?.(message);
      },
    );
    return () => {
      active = false;
    };
  }, [key]);

  const reload = useCallback(() => setReloadCount((count) => count + 1), []);

  return {
    loading: settled?.key !== key,
    error: settled?.key === key ? settled.error : null,
    reload,
  };
}

/**
 * Current page for a paginated list that returns to page 1 whenever `resetKey`
 * (e.g. the serialised filters + submitted search) changes — derived during render,
 * so no effect is needed to reset it.
 */
export function usePageState(resetKey: string) {
  const [state, setState] = useState({ key: resetKey, page: 1 });
  const page = state.key === resetKey ? state.page : 1;
  const goToPage = useCallback((next: number) => setState({ key: resetKey, page: next }), [resetKey]);
  return [page, goToPage] as const;
}
