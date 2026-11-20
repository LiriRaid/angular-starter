import { generateId } from './generate-id';

describe('generateId', () => {
  it('returns a different id every time', () => {
    const ids = new Set(Array.from({ length: 50 }, () => generateId()));
    expect(ids.size).toBe(50);
  });

  it('puts the prefix in front', () => {
    expect(generateId('row')).toMatch(/^row-.+/);
  });

  it('works without Web Crypto', () => {
    const original = globalThis.crypto;
    Object.defineProperty(globalThis, 'crypto', { value: undefined, configurable: true });
    try {
      expect(generateId('x')).toMatch(/^x-[a-z0-9]+-[a-z0-9]+$/);
    } finally {
      Object.defineProperty(globalThis, 'crypto', { value: original, configurable: true });
    }
  });
});
