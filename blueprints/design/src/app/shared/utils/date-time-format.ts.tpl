type DateInput = Date | string | number | null | undefined;

function toDate(value: DateInput): Date | null {
  if (value === null || value === undefined || value === '') return null;
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
}

function formatWith(value: DateInput, options: Intl.DateTimeFormatOptions, locale?: string): string {
  const date = toDate(value);
  return date ? new Intl.DateTimeFormat(locale, options).format(date) : '';
}

/** A date and time in the user's language ("Jan 15, 2026, 12:30 PM"). */
export const formatDateTime = (value: DateInput, locale?: string): string =>
  formatWith(value, { dateStyle: 'medium', timeStyle: 'short' }, locale);

/** A date without the time ("Jan 15, 2026"). */
export const formatDate = (value: DateInput, locale?: string): string =>
  formatWith(value, { dateStyle: 'medium' }, locale);

/** A time of day without the date ("12:30 PM"). */
export const formatTime = (value: DateInput, locale?: string): string =>
  formatWith(value, { timeStyle: 'short' }, locale);
