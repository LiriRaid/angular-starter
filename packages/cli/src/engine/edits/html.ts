/**
 * Edits to `src/index.html`. Every function takes the file's text and returns the new text.
 */

/** The `<link>` that loads Inter, the font of the reference application, exactly as it writes it. */
export const INTER_FONT_LINK =
  '<link href="https://fonts.googleapis.com/css2?family=Inter:wght@100..900&display=swap" rel="stylesheet" />';

/**
 * Loads Inter before the end of the head: the design base sets `font-family: Inter` and the reference
 * application gets the font from Google Fonts. A head that already loads Inter is left alone.
 */
export function addInterFont(text: string): string {
  if (/fonts\.googleapis\.com\/css2\?[^"']*family=Inter/.test(text)) return text;
  const end = text.indexOf('</head>');
  if (end < 0) throw new Error('it has no </head> to add the font to.');
  const eol = text.includes('\r\n') ? '\r\n' : '\n';
  // Insert at the start of the line that holds </head>, indented like the line above it.
  const lineStart = text.lastIndexOf('\n', end) + 1;
  return `${text.slice(0, lineStart)}  ${INTER_FONT_LINK}${eol}${text.slice(lineStart)}`;
}
