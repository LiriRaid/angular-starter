import { escapeHtml } from './escape-html';

describe('escapeHtml', () => {
  it('escapes the characters that have a meaning in HTML', () => {
    expect(escapeHtml(`<a href="x">Tom & 'Jerry'</a>`)).toBe(
      '&lt;a href=&quot;x&quot;&gt;Tom &amp; &#39;Jerry&#39;&lt;/a&gt;',
    );
  });

  it('leaves plain text untouched', () => {
    expect(escapeHtml('Plain text 123')).toBe('Plain text 123');
  });

  it('escapes an ampersand only once', () => {
    expect(escapeHtml('&lt;')).toBe('&amp;lt;');
  });
});
