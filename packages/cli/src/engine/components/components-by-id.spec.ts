import { describe, expect, it } from 'vitest';
import { componentsOf, componentsOfIds } from './manifest.js';

describe('componentsOfIds', () => {
  it('adds what the components import, each once, imported ones first', () => {
    const ids = componentsOfIds(['search']).map((component) => component.id);
    expect(new Set(ids).size).toBe(ids.length);
    expect(ids).toEqual(
      expect.arrayContaining(['search', 'button', 'input', 'select', 'avatar', 'icon']),
    );
    expect(ids.indexOf('icon')).toBeLessThan(ids.indexOf('button'));
    expect(ids.indexOf('button')).toBeLessThan(ids.indexOf('search'));
  });

  it('gives the same list as a collection when it is given the collection ids', () => {
    const recommended = componentsOf('recommended').map((component) => component.id);
    const byIds = componentsOfIds(recommended).map((component) => component.id);
    expect([...byIds].sort()).toEqual([...recommended].sort());
  });

  it('refuses an id that is not in the manifest', () => {
    expect(() => componentsOfIds(['carousel'])).toThrow(/carousel/);
  });
});
