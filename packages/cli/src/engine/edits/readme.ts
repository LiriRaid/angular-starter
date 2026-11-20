/**
 * The part of a README that depends on what the project generated (which components, which
 * stylesheets) lives between these two markers. Generating or adding something rewrites only that
 * block; what the developer writes outside of it is never touched.
 */
export const GENERATED_START = '<!-- as:generated -->';
export const GENERATED_END = '<!-- /as:generated -->';

/**
 * Replaces what is between the markers with `lines`. A README without both markers is returned as it
 * is: the developer removed the block, so it does not come back.
 */
export function replaceGeneratedBlock(text: string, lines: readonly string[]): string {
  const start = text.indexOf(GENERATED_START);
  const end = text.indexOf(GENERATED_END);
  if (start < 0 || end < start) return text;
  const eol = text.includes('\r\n') ? '\r\n' : '\n';
  const body = lines.length === 0 ? '' : `${lines.join(eol)}${eol}`;
  return `${text.slice(0, start + GENERATED_START.length)}${eol}${body}${text.slice(end)}`;
}
