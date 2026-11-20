import { describe, expect, it } from 'vitest';
import { DEFAULT_OPTIONS } from '../config/resolve.js';
import type { GenerationContext } from './pipeline.js';
import {
  NEW_PROJECT_STAGES,
  applyAppShell,
  applyComponents,
  applyDesign,
  applyPresence,
} from './stages.js';

const contextWith = (
  components: 'none' | 'recommended' | 'all',
  appShell: 'none' | 'starter' = 'none',
): GenerationContext =>
  ({ options: { ...DEFAULT_OPTIONS, components, appShell } }) as GenerationContext;

describe('new project stages', () => {
  it('adds the design base and the components only with a component collection', () => {
    for (const stage of [applyDesign, applyComponents]) {
      expect(stage.enabled?.(contextWith('none'))).toBe(false);
      expect(stage.enabled?.(contextWith('recommended'))).toBe(true);
      expect(stage.enabled?.(contextWith('all'))).toBe(true);
    }
  });

  it('adds the design base for the application shell too, and the shell only when chosen', () => {
    expect(applyDesign.enabled?.(contextWith('none', 'starter'))).toBe(true);
    expect(applyDesign.enabled?.(contextWith('none', 'none'))).toBe(false);
    expect(applyComponents.enabled?.(contextWith('none', 'starter'))).toBe(false);
    expect(applyAppShell.enabled?.(contextWith('none', 'starter'))).toBe(true);
    expect(applyAppShell.enabled?.(contextWith('all', 'none'))).toBe(false);
  });

  it('adds presence only when it was chosen', () => {
    const context = (presence: 'none' | 'starter'): GenerationContext =>
      ({ options: { ...DEFAULT_OPTIONS, presence } }) as GenerationContext;
    expect(applyPresence.enabled?.(context('starter'))).toBe(true);
    expect(applyPresence.enabled?.(context('none'))).toBe(false);
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
      'apply-app-shell',
      'apply-presence',
      'add-icon-library',
      'write-starter-config',
      'install-dependencies',
      'init-git',
      'verify-project',
    ];
    expect(ids.filter((id) => order.includes(id))).toEqual(order);
  });
});
