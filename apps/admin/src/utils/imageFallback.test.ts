import { describe, expect, it } from 'vitest';
import type { SyntheticEvent } from 'react';
import { handleImageError } from './imageFallback';

describe('handleImageError', () => {
  it('tries the fallback once, then hides the image instead of retrying forever', () => {
    const img = document.createElement('img');
    img.src = 'https://example.com/broken.png';
    const fire = () => handleImageError({ currentTarget: img } as unknown as SyntheticEvent<HTMLImageElement>);

    fire();
    expect(img.src).toContain('images.unsplash.com');
    expect(img.style.visibility).toBe('');

    const fallbackSrc = img.src;
    fire(); // the fallback failed too
    expect(img.src).toBe(fallbackSrc);
    expect(img.style.visibility).toBe('hidden');
  });
});
