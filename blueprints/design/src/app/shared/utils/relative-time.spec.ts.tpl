import { formatRelativeTime } from './relative-time';

describe('formatRelativeTime', () => {
  const now = Date.UTC(2026, 0, 15, 12, 0, 0);
  const at = (seconds: number): number => now + seconds * 1000;
  const format = (seconds: number) => formatRelativeTime(at(seconds), { locale: 'en', now });

  it('says "now" for the last seconds', () => {
    expect(format(0)).toBe('now');
    expect(format(-30)).toBe('now');
  });

  it('counts the past in the largest unit that fits', () => {
    expect(format(-90)).toBe('1 minute ago');
    expect(format(-3 * 3600)).toBe('3 hours ago');
    expect(format(-2 * 24 * 3600)).toBe('2 days ago');
    expect(format(-14 * 24 * 3600)).toBe('2 weeks ago');
    expect(format(-60 * 24 * 3600)).toBe('2 months ago');
    expect(format(-800 * 24 * 3600)).toBe('2 years ago');
  });

  it('counts the future too', () => {
    expect(format(2 * 3600)).toBe('in 2 hours');
    expect(format(24 * 3600)).toBe('tomorrow');
  });

  it('accepts an ISO string and a Date', () => {
    const iso = new Date(at(-3600)).toISOString();
    expect(formatRelativeTime(iso, { locale: 'en', now })).toBe('1 hour ago');
    expect(formatRelativeTime(new Date(iso), { locale: 'en', now })).toBe('1 hour ago');
  });

  it('follows the language asked for', () => {
    expect(formatRelativeTime(at(-3 * 3600), { locale: 'es', now })).toBe('hace 3 horas');
  });

  it('returns an empty string for a value that is not a date', () => {
    expect(formatRelativeTime('not a date', { locale: 'en', now })).toBe('');
  });
});
