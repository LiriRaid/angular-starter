import { describe, expect, it } from 'vitest';
import { deriveInitials } from './derive-initials';

describe('deriveInitials', () => {
  it('usa la primera letra de nombre y apellido para nombres de dos o más palabras', () => {
    expect(deriveInitials('Gabriel Cruz')).toBe('GC');
    expect(deriveInitials('Josselin Alexandra Rapalo')).toBe('JA');
  });

  it('usa las primeras dos letras cuando es una sola palabra', () => {
    expect(deriveInitials('Gabriel')).toBe('GA');
  });

  it('siempre retorna en mayúsculas', () => {
    expect(deriveInitials('gabriel cruz')).toBe('GC');
  });
});
