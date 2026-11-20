import { describe, expect, it } from 'vitest';
import { formatPhoneNumber, groupNationalDigits, matchDialCode } from './format-phone-number';

describe('matchDialCode', () => {
  it('encuentra el país cuyo dialCode matchea el inicio de los dígitos', () => {
    expect(matchDialCode('50496991587')?.iso2).toBe('hn');
  });

  it('retorna null si ningún dialCode conocido matchea', () => {
    expect(matchDialCode('0000000000')).toBeNull();
  });

  it('resuelve el dialCode "1" (NANP) a Estados Unidos, no al primer país alfabético (American Samoa)', () => {
    expect(matchDialCode('15556826860')?.iso2).toBe('us');
  });
});

describe('groupNationalDigits', () => {
  it('agrupa en bloques de 4 dígitos', () => {
    expect(groupNationalDigits('96991587')).toBe('9699 1587');
  });

  it('no agrega espacio final si el resto no completa un bloque', () => {
    expect(groupNationalDigits('969')).toBe('969');
  });

  it('usa el patrón 4-4 para Honduras (mismo resultado que el fallback genérico)', () => {
    expect(groupNationalDigits('96991587', 'hn')).toBe('9699 1587');
  });

  it('usa el patrón 3-3-4 para Estados Unidos en vez del genérico de bloques de 4', () => {
    expect(groupNationalDigits('5556826860', 'us')).toBe('555 682 6860');
  });

  it('cae al agrupamiento genérico si el iso2 no tiene patrón listado', () => {
    expect(groupNationalDigits('123456789012', 'zz')).toBe('1234 5678 9012');
  });
});

describe('formatPhoneNumber', () => {
  it('formatea un número E.164 con "+", código de país y agrupado en bloques de 4', () => {
    expect(formatPhoneNumber('+50496991587')).toBe('+504 9699 1587');
  });

  it('formatea igual un número sin "+" ni espacios', () => {
    expect(formatPhoneNumber('50496991587')).toBe('+504 9699 1587');
  });

  it('solo antepone "+" si no matchea ningún código de país conocido', () => {
    expect(formatPhoneNumber('0000000000')).toBe('+0000000000');
  });

  it('retorna string vacío si no hay dígitos (incluyendo null/undefined)', () => {
    expect(formatPhoneNumber('')).toBe('');
    expect(formatPhoneNumber(null)).toBe('');
    expect(formatPhoneNumber(undefined)).toBe('');
  });
});
