import { formatDate, formatDateTime, formatTime } from './date-time-format';

describe('date and time formatting', () => {
  // A local date, so the result does not depend on the time zone of the machine.
  const moment = new Date(2026, 0, 15, 14, 30);

  it('formats a date with its time', () => {
    const text = formatDateTime(moment, 'en');
    expect(text).toContain('Jan 15, 2026');
    expect(text).toMatch(/2:30\s?PM/);
  });

  it('formats a date alone and a time alone', () => {
    expect(formatDate(moment, 'en')).toBe('Jan 15, 2026');
    expect(formatTime(moment, 'en')).toMatch(/^2:30\s?PM$/);
  });

  it('accepts an ISO string and milliseconds', () => {
    expect(formatDate(moment.toISOString(), 'en')).toContain('2026');
    expect(formatDate(moment.getTime(), 'en')).toContain('2026');
  });

  it('follows the language asked for', () => {
    expect(formatDate(moment, 'es')).toContain('ene');
  });

  it('returns an empty string when there is no valid date', () => {
    expect(formatDateTime(null)).toBe('');
    expect(formatDate(undefined)).toBe('');
    expect(formatTime('not a date')).toBe('');
    expect(formatTime('')).toBe('');
  });
});
