import { act, type ReactElement } from 'react';
import { createRoot, type Root } from 'react-dom/client';
import { MemoryRouter } from 'react-router-dom';

/**
 * Minimal page test harness (no testing-library dependency): renders a page inside a
 * MemoryRouter and offers DOM helpers that wrap interactions in act().
 */
(globalThis as { IS_REACT_ACT_ENVIRONMENT?: boolean }).IS_REACT_ACT_ENVIRONMENT = true;

export interface PageHarness {
  container: HTMLDivElement;
  unmount: () => void;
  /** Lets pending promises (mocked API calls) resolve and React re-render. */
  settle: () => Promise<void>;
  text: () => string;
  /** First button whose text includes `label` (or whose aria-label equals it). */
  button: (label: string) => HTMLButtonElement;
  click: (el: Element) => void;
  /** Sets an input/select/textarea value the way React expects. */
  type: (el: HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement, value: string) => void;
  field: <T extends Element = HTMLInputElement>(selector: string) => T;
  submit: (form: HTMLFormElement) => void;
}

export function renderPage(page: ReactElement): PageHarness {
  const container = document.createElement('div');
  document.body.appendChild(container);
  const root: Root = createRoot(container);
  act(() => root.render(<MemoryRouter>{page}</MemoryRouter>));

  const harness: PageHarness = {
    container,
    unmount: () => {
      act(() => root.unmount());
      container.remove();
    },
    settle: async () => {
      await act(async () => {
        for (let i = 0; i < 8; i++) await Promise.resolve();
      });
    },
    text: () => container.textContent ?? '',
    button: (label) => {
      const match = [...container.querySelectorAll('button')].find(
        (b) => b.getAttribute('aria-label') === label || (b.textContent ?? '').includes(label),
      );
      if (!match) throw new Error(`Button "${label}" not found`);
      return match;
    },
    click: (el) => act(() => (el as HTMLElement).click()),
    type: (el, value) => {
      const proto = Object.getPrototypeOf(el);
      Object.getOwnPropertyDescriptor(proto, 'value')!.set!.call(el, value);
      act(() => {
        el.dispatchEvent(new Event('input', { bubbles: true }));
        el.dispatchEvent(new Event('change', { bubbles: true }));
      });
    },
    field: <T extends Element = HTMLInputElement>(selector: string) => {
      const el = container.querySelector(selector);
      if (!el) throw new Error(`Field "${selector}" not found`);
      return el as T;
    },
    submit: (form) => act(() => form.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))),
  };
  return harness;
}

/** Axios-like response wrapper. */
export const ok = <T,>(data: T, message?: string) => ({ data: { success: true, message, data } });

/** Axios-like error with an API body. */
export const apiError = (message: string, status = 400) => ({ response: { status, data: { success: false, message } } });
