import { describe, expect, it } from 'vitest';
import { DEFAULT_OPTIONS } from '../config/resolve.js';
import type { GenerationContext } from './pipeline.js';
import { NEW_PROJECT_STAGES, applyComponents, applyDesign } from './stages.js';

const contextWith = (components: 'none' | 'recommended' | 'all'): GenerationContext =>
  ({ options: { ...DEFAULT_OPTIONS, components } }) as GenerationContext;

describe('new project stages', () => {
  it('adds the design base and the components only with a component collection', () => {
    for (const stage of [applyDesign, applyComponents]) {
      expect(stage.enabled?.(contextWith('none'))).toBe(false);
      expect(stage.enabled?.(contextWith('recommended'))).toBe(true);
      expect(stage.enabled?.(contextWith('all'))).toBe(true);
    }
  });

  it('runs in the order each stage needs', () => {
    const ids = NEW_PROJECT_STAGES.map((stage) => stage.id);
    const order = [
      'create-workspace',
      'apply-architecture',
      'apply-routing',
      'apply-rendering',
      'apply-design',
      'apply-components',
      'add-icon-library',
      'write-starter-config',
      'install-dependencies',
      'init-git',
      'verify-project',
    ];
    expect(ids.filter((id) => order.includes(id))).toEqual(order);
  });
});
