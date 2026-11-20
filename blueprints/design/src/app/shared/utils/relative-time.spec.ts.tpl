import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { formatRelativeTime } from './relative-time';

describe('formatRelativeTime', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date('2025-06-15T12:00:00Z'));
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('retorna "hace instantes" para menos de un minuto', () => {
    expect(formatRelativeTime(new Date('2025-06-15T11:59:30Z').toISOString())).toBe('hace instantes');
  });

  it('retorna en minutos cuando pasó menos de una hora', () => {
    expect(formatRelativeTime(new Date('2025-06-15T11:55:00Z').toISOString())).toContain('minuto');
  });

  it('retorna en horas cuando pasó menos de un día', () => {
    expect(formatRelativeTime(new Date('2025-06-15T09:00:00Z').toISOString())).toContain('hora');
  });

  it('retorna en días cuando pasó menos de una semana', () => {
    expect(formatRelativeTime(new Date('2025-06-13T12:00:00Z').toISOString())).toContain('día');
  });

  it('nunca retorna tiempo negativo si la fecha está en el futuro', () => {
    expect(formatRelativeTime(new Date('2025-06-15T13:00:00Z').toISOString())).toBe('hace instantes');
  });
});
