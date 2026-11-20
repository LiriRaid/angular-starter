import { describe, expect, it } from 'vitest';
import { INTER_FONT_LINK, addInterFont } from './html.js';

/** `src/index.html` as `ng new` (Angular CLI 22.3) writes it. */
const NG_NEW = `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Demo</title>
  <base href="/">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="icon" type="image/x-icon" href="favicon.ico">
</head>
<body>
  <app-root></app-root>
</body>
</html>
`;

describe('addInterFont', () => {
  it('links the Inter font of the reference application at the end of the head', () => {
    const result = addInterFont(NG_NEW);
    expect(result).toContain('fonts.googleapis.com/css2?family=Inter:wght@100..900&display=swap');
    expect(result.indexOf(INTER_FONT_LINK)).toBeLessThan(result.indexOf('</head>'));
    expect(result.indexOf('favicon.ico')).toBeLessThan(result.indexOf(INTER_FONT_LINK));
  });

  it('keeps the rest of the file untouched', () => {
    const result = addInterFont(NG_NEW);
    expect(result.replace(`  ${INTER_FONT_LINK}\n`, '')).toBe(NG_NEW);
  });

  it('is idempotent', () => {
    const once = addInterFont(NG_NEW);
    expect(addInterFont(once)).toBe(once);
  });

  it('leaves a head that already loads Inter alone', () => {
    const own = NG_NEW.replace(
      '</head>',
      '  <link href="https://fonts.googleapis.com/css2?family=Inter&display=swap" rel="stylesheet">\n</head>',
    );
    expect(addInterFont(own)).toBe(own);
  });

  it('keeps the CRLF line endings of a Windows file', () => {
    const result = addInterFont(NG_NEW.replaceAll('\n', '\r\n'));
    expect(result.replaceAll('\r\n', '')).not.toContain('\n');
  });

  it('fails clearly when there is no head', () => {
    expect(() => addInterFont('<html></html>')).toThrow(/<\/head>/);
  });
});
