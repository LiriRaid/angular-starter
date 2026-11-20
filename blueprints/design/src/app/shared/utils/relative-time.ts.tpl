const UNITS: [Intl.RelativeTimeFormatUnit, number][] = [
  ['year', 31_536_000],
  ['month', 2_592_000],
  ['week', 604_800],
  ['day', 86_400],
  ['hour', 3_600],
  ['minute', 60],
];

const rtf = new Intl.RelativeTimeFormat('es', { numeric: 'always' });

export function formatRelativeTime(iso: string): string {
  const diffSeconds = Math.max(0, (Date.now() - new Date(iso).getTime()) / 1000);
  if (diffSeconds < 60) return 'hace instantes';

  for (const [unit, secondsInUnit] of UNITS) {
    const value = Math.floor(diffSeconds / secondsInUnit);
    if (value >= 1) return rtf.format(-value, unit);
  }

  return 'hace instantes';
}
