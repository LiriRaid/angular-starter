import { describe, expect, it } from 'vitest';
import { escapeHtml } from './escape-html';

describe('escapeHtml', () => {
  it('escapa lo que rompe HTML, en contenido y en atributos entre comillas', () => {
    expect(escapeHtml(`<img src="x" onerror='y'> & más`)).toBe('&lt;img src=&quot;x&quot; onerror=&#39;y&#39;&gt; &amp; más');
  });

  it('no escapa dos veces un texto ya escapado a mano: cada carácter se trata una vez', () => {
    expect(escapeHtml('a & b')).toBe('a &amp; b');
    expect(escapeHtml(escapeHtml('<'))).toBe('&amp;lt;');
  });
});
