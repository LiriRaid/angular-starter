const UNITS = ['B', 'KB', 'MB', 'GB', 'TB'] as const;

/** A size in bytes as text ("1.5 MB"); an empty string when there is no size to show. */
export function formatFileSize(bytes: number | null | undefined): string {
  if (bytes === null || bytes === undefined || !Number.isFinite(bytes) || bytes <= 0) return '';

  let value = bytes;
  let unit = 0;
  while (value >= 1024 && unit < UNITS.length - 1) {
    value /= 1024;
    unit++;
  }
  return `${unit === 0 ? value : value.toFixed(1)} ${UNITS[unit]}`;
}
