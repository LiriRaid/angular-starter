import { describe, expect, it } from 'vitest';

import { addPrecise, resolveInputFieldStyles, resolveInputType, sanitizeDecimalInput, stepNumberValue } from './as-input.config';

describe('resolveInputType', () => {
  it('number se dibuja como texto: el <input type="number"> nativo borra estados intermedios como "1." y salta el cursor', () => {
    expect(resolveInputType('number')).toBe('text');
    expect(resolveInputType('price')).toBe('text');
  });

  it('el resto de tipos se conservan', () => {
    expect(resolveInputType('email')).toBe('email');
    expect(resolveInputType('password')).toBe('password');
  });
});

describe('sanitizeDecimalInput', () => {
  it('deja solo dígitos y un único punto decimal', () => {
    expect(sanitizeDecimalInput('12a.5b.7')).toBe('12.57');
  });

  it('la coma decimal ("2,5") se toma como punto en vez de perderse y guardar 25', () => {
    expect(sanitizeDecimalInput('2,5')).toBe('2.5');
    expect(sanitizeDecimalInput('-0,75', { allowNegative: true })).toBe('-0.75');
  });

  it('conserva el estado intermedio "1." mientras se escribe o se borra', () => {
    expect(sanitizeDecimalInput('1.')).toBe('1.');
    expect(sanitizeDecimalInput('.')).toBe('.');
  });

  it('el signo "-" inicial solo se permite cuando se pide', () => {
    expect(sanitizeDecimalInput('-3.5', { allowNegative: true })).toBe('-3.5');
    expect(sanitizeDecimalInput('-3.5')).toBe('3.5');
    expect(sanitizeDecimalInput('3-5', { allowNegative: true })).toBe('35');
  });

  it('un texto vacío queda vacío', () => {
    expect(sanitizeDecimalInput('')).toBe('');
  });
});

describe('addPrecise', () => {
  it('evita los artefactos de coma flotante', () => {
    expect(0.1 + 0.2).not.toBe(0.3);
    expect(addPrecise(0.1, 0.2)).toBe(0.3);
    expect(addPrecise(1.5, 1)).toBe(2.5);
  });
});

describe('stepNumberValue', () => {
  it('suma el paso sin realinear al múltiplo más cercano: 1.5 con paso 1 pasa a 2.5, no a 2', () => {
    expect(stepNumberValue({ current: '1.5', direction: 1, step: 1 })).toBe('2.5');
    expect(stepNumberValue({ current: '1.5', direction: -1, step: 1 })).toBe('0.5');
  });

  it('un valor vacío o incompleto cuenta como 0 y el paso por defecto es 1', () => {
    expect(stepNumberValue({ current: '', direction: 1 })).toBe('1');
    expect(stepNumberValue({ current: '1.', direction: 1 })).toBe('2');
  });

  it('acepta el paso como texto ("0.1") y no arrastra error de coma flotante', () => {
    expect(stepNumberValue({ current: '0.2', direction: 1, step: '0.1' })).toBe('0.3');
  });

  it('respeta min y max: ni la rueda ni las flechas llevan el valor fuera del rango', () => {
    expect(stepNumberValue({ current: '0', direction: -1, step: 1, min: 0 })).toBe('0');
    expect(stepNumberValue({ current: '99.5', direction: 1, step: 1, max: 100 })).toBe('100');
    expect(stepNumberValue({ current: '5', direction: 1, step: 10, min: 0, max: 8 })).toBe('8');
  });

  it('un paso inválido o cero cae al 1', () => {
    expect(stepNumberValue({ current: '2', direction: 1, step: 'abc' })).toBe('3');
    expect(stepNumberValue({ current: '2', direction: 1, step: 0 })).toBe('3');
  });
});

describe('resolveInputFieldStyles', () => {
  it('deja sitio a los botones de incremento a la derecha solo cuando hay stepper', () => {
    expect(resolveInputFieldStyles('number', false, false, false, 'on')['padding-right']).toBe('1rem');
    expect(resolveInputFieldStyles('number', false, false, false, 'on', true)['padding-right']).toBe('2.25rem');
  });
});
