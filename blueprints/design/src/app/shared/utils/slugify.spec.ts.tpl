import { slugify } from './slugify';

describe('slugify', () => {
  it('lowercases and joins the words with hyphens', () => {
    expect(slugify('Hello World')).toBe('hello-world');
  });

  it('removes accents', () => {
    expect(slugify('Café del Mar')).toBe('cafe-del-mar');
    expect(slugify('Ñandú')).toBe('nandu');
  });

  it('collapses any run of other characters into one hyphen', () => {
    expect(slugify('+504 9699 1587')).toBe('504-9699-1587');
    expect(slugify('a --- b!!c')).toBe('a-b-c');
  });

  it('does not start or end with a hyphen', () => {
    expect(slugify('  ¡Hola!  ')).toBe('hola');
    expect(slugify('***')).toBe('');
  });
});
