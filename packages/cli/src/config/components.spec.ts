import { describe, expect, it } from 'vitest';
import { COMPONENTS } from '../engine/components/manifest.js';
import {
  ALL_COMPONENT_IDS,
  ESSENTIAL_COMPONENT_IDS,
  EXTRA_COMPONENT_IDS,
  componentIdsOf,
  normalizeComponents,
} from './components.js';

describe('component ids', () => {
  it('has the 16 essential components and the 10 more of the full collection', () => {
    expect(ESSENTIAL_COMPONENT_IDS).toHaveLength(16);
    expect(EXTRA_COMPONENT_IDS).toHaveLength(10);
    expect(ALL_COMPONENT_IDS).toEqual([...ESSENTIAL_COMPONENT_IDS, ...EXTRA_COMPONENT_IDS]);
  });

  it('is exactly what the manifest of the engine can generate', () => {
    expect([...ALL_COMPONENT_IDS].sort()).toEqual(COMPONENTS.map(({ id }) => id).sort());
  });
});

describe('normalizeComponents', () => {
  it('records the essential ids, in any order, as the essential collection', () => {
    expect(normalizeComponents([...ESSENTIAL_COMPONENT_IDS].reverse())).toEqual({
      components: 'recommended',
    });
  });

  it('records every id as all the components', () => {
    expect(normalizeComponents(ALL_COMPONENT_IDS)).toEqual({ components: 'all' });
  });

  it('records an empty list as none', () => {
    expect(normalizeComponents([])).toEqual({ components: 'none' });
  });

  it('records anything else as a custom selection, without repeats', () => {
    expect(normalizeComponents(['modal', 'button', 'modal'])).toEqual({
      components: 'custom',
      componentList: ['modal', 'button'],
    });
    expect(normalizeComponents(ESSENTIAL_COMPONENT_IDS.slice(1))).toMatchObject({
      components: 'custom',
    });
  });
});

describe('componentIdsOf', () => {
  it('gives the ids of every kind of choice', () => {
    expect(componentIdsOf({ components: 'none' })).toEqual([]);
    expect(componentIdsOf({ components: 'recommended' })).toEqual(ESSENTIAL_COMPONENT_IDS);
    expect(componentIdsOf({ components: 'all' })).toEqual(ALL_COMPONENT_IDS);
    expect(componentIdsOf({ components: 'custom', componentList: ['table'] })).toEqual(['table']);
  });
});
