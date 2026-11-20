/**
 * A unique id for client-side use (optimistic entries, temporary attachments, form rows). It uses
 * `crypto.randomUUID()` and falls back to a random string where Web Crypto is missing.
 * `prefix`, when given, goes in front with a hyphen ("row-3f2a...").
 */
export function generateId(prefix?: string): string {
  const id =
    typeof crypto !== 'undefined' && 'randomUUID' in crypto
      ? crypto.randomUUID()
      : `${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 10)}`;
  return prefix ? `${prefix}-${id}` : id;
}
