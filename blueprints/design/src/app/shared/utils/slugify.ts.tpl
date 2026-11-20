/**
 * Text as a URL-friendly slug: accents removed, lowercase, and every run of other characters
 * replaced by one hyphen ("Café del Mar!" becomes "cafe-del-mar").
 */
export function slugify(value: string): string {
  return value
    .normalize('NFD')
    .replace(/\p{M}/gu, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}
