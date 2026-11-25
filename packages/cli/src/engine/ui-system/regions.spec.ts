import { describe, expect, it } from 'vitest';
import { selectRegions } from './regions.js';

const has = (...ids: string[]): ReadonlySet<string> => new Set(ids);

describe('selectRegions', () => {
  it('leaves a text without markers as it is', () => {
    const text = 'a\nb\n';
    expect(selectRegions(text, has())).toBe(text);
  });

  it('keeps a block whose components are installed, without its markers', () => {
    const text = ['a', '// uis:begin(modal)', 'm1', 'm2', '// uis:end', 'b', ''].join('\n');
    expect(selectRegions(text, has('modal'))).toBe('a\nm1\nm2\nb\n');
  });

  it('drops a block whose component is missing, markers included', () => {
    const text = ['a', '// uis:begin(modal)', 'm1', '// uis:end', 'b', ''].join('\n');
    expect(selectRegions(text, has('button'))).toBe('a\nb\n');
  });

  it('needs every id of a list, and any id of the ones joined with a bar', () => {
    const text = [
      '// uis:begin(modal,button)',
      'both',
      '// uis:end',
      '// uis:begin(a|b)',
      'either',
      '// uis:end',
      '',
    ].join('\n');
    expect(selectRegions(text, has('modal'))).toBe('');
    expect(selectRegions(text, has('modal', 'button'))).toBe('both\n');
    expect(selectRegions(text, has('b'))).toBe('either\n');
    expect(selectRegions(text, has('a', 'b'))).toBe('either\n');
  });

  it('handles trailing markers on one line, in TypeScript and in templates', () => {
    const ts = ['  SaAvatar, // uis(avatar)', '  SaButton,', ''].join('\n');
    expect(selectRegions(ts, has())).toBe('  SaButton,\n');
    expect(selectRegions(ts, has('avatar'))).toBe('  SaAvatar,\n  SaButton,\n');
    const html = ['<sa-x /> <!-- uis(x) -->', '<p>always</p>', ''].join('\n');
    expect(selectRegions(html, has())).toBe('<p>always</p>\n');
    expect(selectRegions(html, has('x'))).toBe('<sa-x />\n<p>always</p>\n');
  });

  it('understands template comments as block markers', () => {
    const text = ['<!-- uis:begin(tabs) -->', '<sa-tabs />', '<!-- uis:end -->', ''].join('\n');
    expect(selectRegions(text, has('tabs'))).toBe('<sa-tabs />\n');
    expect(selectRegions(text, has())).toBe('');
  });

  it('nests: an inner block of a kept block is judged on its own, and a dropped block drops what it holds', () => {
    const text = [
      '// uis:begin(a)',
      'a',
      '// uis:begin(b)',
      'ab',
      '// uis:end',
      '// uis:end',
      '',
    ].join('\n');
    expect(selectRegions(text, has('a', 'b'))).toBe('a\nab\n');
    expect(selectRegions(text, has('a'))).toBe('a\n');
    expect(selectRegions(text, has('b'))).toBe('');
  });

  it('keeps the indentation of the lines it keeps and the line ending of the file', () => {
    const text = ['x', '  // uis:begin(a)', '  keep', '  // uis:end', 'y', ''].join('\r\n');
    expect(selectRegions(text, has('a'))).toBe('x\r\n  keep\r\ny\r\n');
  });

  it('refuses a block that is never closed or closed twice', () => {
    expect(() => selectRegions('// uis:begin(a)\nx\n', has())).toThrow(/never closed/);
    expect(() => selectRegions('x\n// uis:end\n', has())).toThrow(/closes nothing/);
  });
});
