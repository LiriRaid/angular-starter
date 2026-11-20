const UNITS: readonly (readonly [Intl.RelativeTimeFormatUnit, number])[] = [
  ['year', 365 * 24 * 3600],
  ['month', 30 * 24 * 3600],
  ['week', 7 * 24 * 3600],
  ['day', 24 * 3600],
  ['hour', 3600],
  ['minute', 60],
];

export interface RelativeTimeOptions {
  /** BCP 47 language tag; the language of the browser when absent. */
  locale?: string;
  /** The moment to measure from, in milliseconds; now when absent. Useful in tests. */
  now?: number;
}

/**
 * How long ago (or from now) a moment is, in the user's language: "3 hours ago", "in 2 days",
 * "now". Accepts a Date, an ISO string or milliseconds.
 */
export function formatRelativeTime(
  value: Date | string | number,
  { locale, now = Date.now() }: RelativeTimeOptions = {},
): string {
  const time = new Date(value).getTime();
  if (Number.isNaN(time)) return '';

  const format = new Intl.RelativeTimeFormat(locale, { numeric: 'auto' });
  const seconds = (time - now) / 1000;
  for (const [unit, size] of UNITS) {
    if (Math.abs(seconds) >= size) return format.format(Math.trunc(seconds / size), unit);
  }
  return format.format(0, 'second');
}
