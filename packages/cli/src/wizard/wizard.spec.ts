import { describe, expect, it } from 'vitest';
import { createFakePrompter } from '../../tests/helpers/fake-prompter.js';
import { detectPackageManager, runWizard } from './wizard.js';

const NO_ENV = {};

describe('runWizard', () => {
  it('asks only what can be generated and what is still unknown', async () => {
    const { prompter, asked } = createFakePrompter(['css', true, 'csr', 'npm', true, true]);
    const answers = await runWizard({}, prompter, NO_ENV);

    // architecture, routing, components and icons have a single available option: no question.
    expect(asked.map((question) => question.name)).toEqual([
      'style',
      'tailwind',
      'rendering',
      'packageManager',
      'git',
      'install',
    ]);
    expect(answers).toEqual({
      style: 'css',
      tailwind: true,
      rendering: 'csr',
      packageManager: 'npm',
      git: true,
      install: true,
    });
  });

  it('never offers options that do not exist yet', async () => {
    const { prompter, asked } = createFakePrompter(['css', true, 'csr', 'npm', true, true]);
    await runWizard({}, prompter, NO_ENV);
    const everyChoice = asked.flatMap((question) => question.choices ?? []);
    expect(everyChoice).not.toContain('starter-ssr');
    expect(everyChoice).toEqual(
      expect.arrayContaining(['css', 'scss', 'sass', 'less', 'csr', 'ssr']),
    );
  });

  it('skips the Tailwind question when the stylesheet format is not CSS', async () => {
    const { prompter, asked } = createFakePrompter(['scss', 'csr', 'npm', true, true]);
    const answers = await runWizard({}, prompter, NO_ENV);
    expect(asked.map((question) => question.name)).not.toContain('tailwind');
    expect(answers.style).toBe('scss');
    expect(answers).not.toHaveProperty('tailwind');
  });

  it('does not ask for a stylesheet format when Tailwind was requested', async () => {
    const { prompter, asked } = createFakePrompter(['csr', 'npm', true, true]);
    await runWizard({ tailwind: true }, prompter, NO_ENV);
    const names = asked.map((question) => question.name);
    expect(names).not.toContain('style');
    expect(names).not.toContain('tailwind');
  });

  it('skips questions that were already answered by flags or by the config file', async () => {
    const { prompter, asked } = createFakePrompter(['npm']);
    const answers = await runWizard(
      { style: 'less', rendering: 'ssr', git: false, install: false },
      prompter,
      NO_ENV,
    );
    expect(asked.map((question) => question.name)).toEqual(['packageManager']);
    expect(answers).toEqual({ packageManager: 'npm' });
  });

  it('asks nothing when every option is known', async () => {
    const { prompter, asked } = createFakePrompter([]);
    const known = {
      style: 'css',
      tailwind: false,
      rendering: 'csr',
      packageManager: 'npm',
      git: true,
      install: true,
    } as const;
    expect(await runWizard(known, prompter, NO_ENV)).toEqual({});
    expect(asked).toEqual([]);
  });

  it('defaults the package manager to the one that launched the CLI', async () => {
    const { prompter, asked } = createFakePrompter(['pnpm']);
    await runWizard(
      { style: 'css', tailwind: true, rendering: 'csr', git: true, install: true },
      prompter,
      { npm_config_user_agent: 'pnpm/12.9.1 npm/? node/v24.15.0 win32 x64' },
    );
    expect(asked[0]?.default).toBe('pnpm');
  });
});

describe('detectPackageManager', () => {
  it.each([
    ['pnpm/12.9.1 npm/? node/v24.15.0', 'pnpm'],
    ['yarn/4.5.0 npm/? node/v24.15.0', 'yarn'],
    ['npm/11.12.1 node/v24.15.0', 'npm'],
    ['bun/1.2.0', 'npm'],
    [undefined, 'npm'],
  ])('%s -> %s', (agent, expected) => {
    expect(detectPackageManager(agent === undefined ? {} : { npm_config_user_agent: agent })).toBe(
      expected,
    );
  });
});
