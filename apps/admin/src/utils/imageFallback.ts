import type { SyntheticEvent } from 'react';

const FALLBACK_IMAGE = 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=120&q=80';

/**
 * <img onError> handler: swaps in the fallback image once; if that fails too, hides the image.
 * Prevents an endless request loop when the fallback itself cannot load (offline, blocked, removed).
 */
export function handleImageError(event: SyntheticEvent<HTMLImageElement>): void {
  const img = event.currentTarget;
  if (img.dataset.fallbackApplied) {
    img.style.visibility = 'hidden';
    return;
  }
  img.dataset.fallbackApplied = 'true';
  img.src = FALLBACK_IMAGE;
}
