import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'node',
    globalSetup: ['./scripts/vitest-global-setup.mjs'],
    include: ['src/**/*.spec.ts', 'tests/**/*.spec.ts'],
    testTimeout: 15_000,
  },
});
