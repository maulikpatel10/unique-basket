import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

// Unit/component tests for the admin panel (P1-19)
export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    include: ['src/**/*.test.{ts,tsx}'],
  },
});
