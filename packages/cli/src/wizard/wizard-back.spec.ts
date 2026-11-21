import { describe, expect, it, vi } from 'vitest';
import { BACK, createFakePrompter } from '../../tests/helpers/fake-prompter.js';
import { FULL } from '../../tests/helpers/full-registry.js';
import { ALL_COMPONENT_IDS, ESSENTIAL_COMPONENT_IDS } from '../config/components.js';
import { CancelledError } from '../errors.js';
import { runWizard, type WizardReview } from './wizard.js';

const NO_ENV = {};
const SETTLED = { packageManager: 'npm', git: true, install: true } as const;

/** Every question of the longest flow, answered: the Screaming Architecture with the shell. */
const FULL_FLOW = [
  'screaming',
  'starter',
  'tailwind',
  'csr',
  'starter',
  'floating-wide',
  'none',
  'recommended',
  [...ESSENTIAL_COMPONENT_IDS],
  'none',
  'npm',
  true,
  true,
];

const names = (asked: { name: string }[]): string[] => asked.map((question) => question.name);

describe('runWizard going back', () => {
  it('offers going back on every question but the first one', async () => {
    const { prompter, asked } = createFakePrompter(FULL_FLOW);
    await runWizard({}, prompter, NO_ENV, FULL);
    expect(asked.map((question) => question.canGoBack)).toEqual([
      false,
      ...Array<boolean>(asked.length - 1).fill(true),
    ]);
  });

  it('goes back from the components list to the collection, with its answer selected', async () => {
    const { prompter, asked } = createFakePrompter([
      'screaming',
      'starter',
      'tailwind',
      'csr',
      'starter',
      'floating-wide',
      'none',
      'recommended',
      BACK,
      'all',
      [...ALL_COMPONENT_IDS],
      'none',
      'npm',
      true,
      true,
    ]);
    const answers = await runWizard({}, prompter, NO_ENV, FULL);

    expect(names(asked).slice(7)).toEqual([
      'components',
      'componentList',
      'components',
      'componentList',
      'uiSystem',
      'packageManager',
      'git',
      'install',
    ]);
    const again = asked[9];
    expect(again?.default).toBe('recommended');
    // The list that follows the new collection starts from that collection, not from the old ticks.
    expect(asked[10]?.checked).toEqual([...ALL_COMPONENT_IDS]);
    expect(answers).toMatchObject({ components: 'all', uiSystem: 'none', icons: 'lucide' });
  });

  it('asks again with the earlier answers replayed, not asked twice', async () => {
    const { prompter, asked } = createFakePrompter([
      'screaming',
      'starter',
      BACK,
      'angular',
      'css',
      'csr',
      'none',
      'npm',
      true,
      true,
    ]);
    // Only the second question went back: the architecture was not asked a second time.
    await runWizard({}, prompter, NO_ENV, FULL);
    expect(names(asked).slice(0, 5)).toEqual([
      'architecture',
      'routing',
      'style',
      'routing',
      'style',
    ]);
    expect(asked[3]?.default).toBe('starter');
    expect(asked[3]?.canGoBack).toBe(true);
  });

  it('recomputes what the changed answer decides', async () => {
    const { prompter, asked } = createFakePrompter([
      'screaming',
      'starter',
      'tailwind',
      'csr',
      'starter',
      BACK,
      'none',
      'none',
      'lucide',
      'npm',
      true,
      true,
    ]);
    const answers = await runWizard({}, prompter, NO_ENV, FULL);

    // With the shell gone there is no layout, no presence and no UI System; the shell implied Lucide,
    // and that is undone as well, so the icons are chosen again.
    expect(names(asked).slice(4)).toEqual([
      'appShell',
      'layout',
      'appShell',
      'components',
      'icons',
      'packageManager',
      'git',
      'install',
    ]);
    expect(asked[6]?.default).toBe('starter');
    expect(answers).toMatchObject({ appShell: 'none', icons: 'lucide', components: 'none' });
    expect(answers).not.toHaveProperty('layout');
  });

  it('never asks, and never goes back to, what a flag already decided', async () => {
    const { prompter, asked } = createFakePrompter(['scss', BACK, 'less', 'csr']);
    const answers = await runWizard(
      { ...SETTLED, architecture: 'screaming', routing: 'angular', icons: 'none' },
      prompter,
      NO_ENV,
      FULL,
    );
    expect(names(asked)).toEqual(['style', 'rendering', 'style', 'rendering']);
    expect(asked.map((question) => question.canGoBack)).toEqual([false, true, false, true]);
    expect(asked[2]?.default).toBe('scss');
    expect(answers).toMatchObject({ style: 'less', rendering: 'csr' });
  });

  describe('the final confirmation', () => {
    const review = () => ({ show: vi.fn<WizardReview['show']>() });

    it('shows the summary and asks to create, change an answer or cancel', async () => {
      const { prompter, asked } = createFakePrompter([...FULL_FLOW, 'create']);
      const shown = review();
      const answers = await runWizard({}, prompter, NO_ENV, FULL, shown);

      const confirm = asked.at(-1);
      expect(confirm).toMatchObject({
        kind: 'select',
        name: 'confirm',
        message: 'Create project with this configuration?',
        choices: ['create', 'change', 'cancel'],
        default: 'create',
        canGoBack: true,
      });
      expect(shown.show).toHaveBeenCalledTimes(1);
      expect(shown.show).toHaveBeenCalledWith(answers);
      expect(answers).toMatchObject({ architecture: 'screaming', install: true });
    });

    it('is not asked when no one wants a review', async () => {
      const { prompter, asked } = createFakePrompter(FULL_FLOW);
      await runWizard({}, prompter, NO_ENV, FULL);
      expect(names(asked)).not.toContain('confirm');
    });

    it('cancels like Ctrl+C would', async () => {
      const { prompter } = createFakePrompter([...FULL_FLOW, 'cancel']);
      await expect(runWizard({}, prompter, NO_ENV, FULL, review())).rejects.toBeInstanceOf(
        CancelledError,
      );
    });

    it('lists the answers and asks again from the one that is changed', async () => {
      const { prompter, asked } = createFakePrompter([
        ...FULL_FLOW,
        'change',
        'components',
        'none',
        'npm',
        true,
        false,
        'create',
      ]);
      const shown = review();
      const answers = await runWizard({}, prompter, NO_ENV, FULL, shown);

      const list = asked.find((question) => question.name === 'changeAnswer');
      expect(list?.message).toBe('Which answer would you like to change?');
      expect(list?.choices).toEqual([
        'architecture',
        'routing',
        'style',
        'rendering',
        'appShell',
        'layout',
        'presence',
        'components',
        'componentList',
        'uiSystem',
        'packageManager',
        'git',
        'install',
      ]);
      expect(list?.names?.[0]).toBe('Architecture: Screaming Architecture');
      expect(list?.names?.at(-1)).toBe('Install dependencies: Yes');

      // The question changed comes back with its answer; the ones after it are asked again.
      const after = names(asked).slice(names(asked).indexOf('changeAnswer') + 1);
      expect(after).toEqual(['components', 'packageManager', 'git', 'install', 'confirm']);
      const components = asked.filter((question) => question.name === 'components');
      expect(components[1]?.default).toBe('recommended');
      expect(answers).toMatchObject({ components: 'none', install: false, icons: 'lucide' });
      expect(answers).not.toHaveProperty('componentList');
      expect(shown.show).toHaveBeenCalledTimes(2);
    });

    it('goes back to the last question with Esc', async () => {
      const { prompter, asked } = createFakePrompter([...FULL_FLOW, BACK, false, 'create']);
      const answers = await runWizard({}, prompter, NO_ENV, FULL, review());
      expect(names(asked).slice(-4)).toEqual(['install', 'confirm', 'install', 'confirm']);
      const install = asked.filter((question) => question.name === 'install');
      expect(install[1]?.default).toBe(true);
      expect(answers).toMatchObject({ install: false });
    });

    it('returns from the list of answers to the confirmation with Esc', async () => {
      const { prompter, asked } = createFakePrompter([...FULL_FLOW, 'change', BACK, 'create']);
      await runWizard({}, prompter, NO_ENV, FULL, review());
      expect(names(asked).slice(-3)).toEqual(['confirm', 'changeAnswer', 'confirm']);
    });

    it('has no answers to change when everything was decided by flags', async () => {
      const { prompter, asked } = createFakePrompter(['create']);
      const known = {
        ...SETTLED,
        architecture: 'angular-default',
        style: 'css',
        tailwind: false,
        rendering: 'csr',
        icons: 'none',
      } as const;
      await runWizard(known, prompter, NO_ENV, FULL, review());
      expect(asked).toHaveLength(1);
      expect(asked[0]).toMatchObject({ choices: ['create', 'cancel'], canGoBack: false });
    });
  });
});
