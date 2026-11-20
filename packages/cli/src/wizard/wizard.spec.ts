import { describe, expect, it } from 'vitest';
import { createFakePrompter } from '../../tests/helpers/fake-prompter.js';
import { CAPABILITIES, type CapabilityOption, type Registry } from '../config/capabilities.js';
import { detectPackageManager, runWizard } from './wizard.js';

const NO_ENV = {};
const PLANNED = new Set([
  'modular',
  'hexagonal',
  'clean',
  'feature-sliced',
  'heroicons',
  'phosphor',
  'tabler',
  'bootstrap-icons',
]);

/** Every option the project plans to generate today and in the near future, whatever `available` says. */
const FULL: Registry = Object.fromEntries(
  Object.entries(CAPABILITIES).map(([category, options]) => [
    category,
    options.map((option: CapabilityOption) => ({ ...option, available: !PLANNED.has(option.id) })),
  ]),
) as unknown as Registry;

const SETTLED = { packageManager: 'npm', git: true, install: true } as const;

describe('runWizard', () => {
  it('asks each question once and preselects only what has one best answer', async () => {
    const { prompter, asked } = createFakePrompter([
      'screaming',
      'starter',
      'tailwind',
      'csr',
      'recommended',
      'npm',
      true,
      true,
    ]);
    const answers = await runWizard({}, prompter, NO_ENV, FULL);

    expect(asked.map((question) => question.name)).toEqual([
      'architecture',
      'routing',
      'style',
      'rendering',
      'components',
      'packageManager',
      'git',
      'install',
    ]);
    // Architecture, routing and components are the user's call: nothing is preselected there.
    expect(asked.slice(0, 5).map((question) => question.default)).toEqual([
      undefined,
      undefined,
      'tailwind',
      'csr',
      undefined,
    ]);
    expect(answers).toEqual({
      architecture: 'screaming',
      routing: 'starter',
      style: 'css',
      tailwind: true,
      rendering: 'csr',
      components: 'recommended',
      icons: 'lucide',
      packageManager: 'npm',
      git: true,
      install: true,
    });
  });

  it('has one stylesheet question and no separate Tailwind question', async () => {
    const { prompter, asked } = createFakePrompter(['screaming', 'starter', 'scss', 'csr', 'none']);
    const answers = await runWizard({ ...SETTLED, icons: 'none' }, prompter, NO_ENV, FULL);
    const style = asked.find((question) => question.name === 'style');
    expect(style?.choices).toEqual(['css', 'tailwind', 'scss', 'sass', 'less']);
    expect(asked.map((question) => question.name)).not.toContain('tailwind');
    expect(answers).toMatchObject({ style: 'scss', tailwind: false });
  });

  it('explains every choice: aligned name with its documentation and a description', async () => {
    const { prompter, asked } = createFakePrompter(['screaming']);
    await runWizard(
      { ...SETTLED, routing: 'angular', style: 'scss', rendering: 'csr', icons: 'none' },
      prompter,
      NO_ENV,
      FULL,
    );
    const architecture = asked[0];
    expect(architecture?.names?.[1]).toMatch(
      /^Screaming Architecture +\[ https:\/\/github\.com\/LiriRaid\/\S+ +\]$/,
    );
    expect(architecture?.names?.join('')).not.toContain('Recommended');
    expect(architecture?.descriptions?.every((text) => (text ?? '').length > 20)).toBe(true);
  });

  it('asks for the icon library when no component needs one', async () => {
    const { prompter, asked } = createFakePrompter(['none', 'lucide']);
    const answers = await runWizard(
      {
        ...SETTLED,
        architecture: 'screaming',
        routing: 'angular',
        style: 'css',
        tailwind: true,
        rendering: 'csr',
      },
      prompter,
      NO_ENV,
      FULL,
    );
    expect(asked.map((question) => question.name)).toEqual(['components', 'icons']);
    expect(asked[1]?.default).toBe('lucide');
    expect(answers).toEqual({ components: 'none', icons: 'lucide' });
  });

  it('implies Lucide when components are chosen instead of asking about it', async () => {
    const { prompter, asked } = createFakePrompter([]);
    const answers = await runWizard(
      {
        ...SETTLED,
        architecture: 'screaming',
        routing: 'angular',
        style: 'css',
        tailwind: true,
        rendering: 'csr',
        components: 'all',
      },
      prompter,
      NO_ENV,
      FULL,
    );
    expect(asked).toEqual([]);
    expect(answers).toEqual({ icons: 'lucide' });
  });

  it('offers components only where they can be generated', async () => {
    const scss = createFakePrompter(['none']);
    await runWizard(
      {
        ...SETTLED,
        architecture: 'screaming',
        routing: 'angular',
        style: 'scss',
        rendering: 'csr',
      },
      scss.prompter,
      NO_ENV,
      FULL,
    );
    expect(scss.asked.map((question) => question.name)).toEqual(['icons']);

    const plain = createFakePrompter(['none']);
    await runWizard(
      {
        ...SETTLED,
        architecture: 'angular-default',
        style: 'css',
        tailwind: true,
        rendering: 'csr',
      },
      plain.prompter,
      NO_ENV,
      FULL,
    );
    expect(plain.asked.map((question) => question.name)).toEqual(['icons']);

    const noLucide = createFakePrompter([]);
    await runWizard(
      {
        ...SETTLED,
        architecture: 'screaming',
        routing: 'angular',
        style: 'css',
        tailwind: true,
        rendering: 'csr',
        icons: 'none',
      },
      noLucide.prompter,
      NO_ENV,
      FULL,
    );
    expect(noLucide.asked).toEqual([]);

    // The component collections are Tailwind CSS code: plain CSS does not get the question either.
    const plainCss = createFakePrompter(['none']);
    await runWizard(
      {
        ...SETTLED,
        architecture: 'screaming',
        routing: 'angular',
        style: 'css',
        rendering: 'csr',
      },
      plainCss.prompter,
      NO_ENV,
      FULL,
    );
    expect(plainCss.asked.map((question) => question.name)).toEqual(['icons']);
  });

  it('never offers options that cannot be generated', async () => {
    const { prompter, asked } = createFakePrompter([
      'screaming',
      'starter',
      'tailwind',
      'csr',
      'recommended',
      'npm',
      true,
      true,
    ]);
    await runWizard({}, prompter, NO_ENV, FULL);
    const everyChoice = asked.flatMap((question) => question.choices ?? []);
    expect(everyChoice).not.toContain('modular');
    expect(everyChoice).not.toContain('heroicons');
    expect(everyChoice).toEqual(
      expect.arrayContaining(['screaming', 'starter', 'tailwind', 'starter-ssr', 'all']),
    );
  });

  it('offers the Angular Starter routing only with an architecture that supports it', async () => {
    const plain = createFakePrompter(['angular-default', 'css', 'csr', 'none']);
    await runWizard({ ...SETTLED }, plain.prompter, NO_ENV, FULL);
    expect(plain.asked.map((question) => question.name)).not.toContain('routing');
  });

  it('does not offer an architecture that cannot take the routing already chosen', async () => {
    const { prompter, asked } = createFakePrompter([]);
    const answers = await runWizard(
      {
        ...SETTLED,
        routing: 'starter',
        style: 'css',
        tailwind: true,
        rendering: 'csr',
        icons: 'none',
      },
      prompter,
      NO_ENV,
      FULL,
    );
    expect(asked).toEqual([]);
    expect(answers).toEqual({ architecture: 'screaming' });
  });

  it('does not ask for a stylesheet when Tailwind was requested', async () => {
    const { prompter, asked } = createFakePrompter(['angular-default', 'csr', 'none']);
    const answers = await runWizard({ ...SETTLED, tailwind: true }, prompter, NO_ENV, FULL);
    expect(asked.map((question) => question.name)).not.toContain('style');
    expect(answers.style).toBeUndefined();
  });

  it('keeps plain CSS when it was asked for with --style css', async () => {
    const { prompter, asked } = createFakePrompter([]);
    const answers = await runWizard(
      {
        ...SETTLED,
        architecture: 'angular-default',
        style: 'css',
        rendering: 'csr',
        icons: 'none',
      },
      prompter,
      NO_ENV,
      FULL,
    );
    expect(asked).toEqual([]);
    expect(answers).toEqual({});
  });

  it('skips questions that were already answered by flags or by the config file', async () => {
    const { prompter, asked } = createFakePrompter(['npm']);
    const answers = await runWizard(
      {
        architecture: 'screaming',
        routing: 'angular',
        style: 'less',
        rendering: 'ssr',
        icons: 'none',
        git: false,
        install: false,
      },
      prompter,
      NO_ENV,
      FULL,
    );
    expect(asked.map((question) => question.name)).toEqual(['packageManager']);
    expect(answers).toEqual({ packageManager: 'npm' });
  });

  it('asks nothing when every option is known', async () => {
    const { prompter, asked } = createFakePrompter([]);
    const known = {
      architecture: 'angular-default',
      routing: 'angular',
      style: 'css',
      tailwind: false,
      rendering: 'csr',
      components: 'none',
      icons: 'none',
      ...SETTLED,
    } as const;
    expect(await runWizard(known, prompter, NO_ENV, FULL)).toEqual({});
    expect(asked).toEqual([]);
  });

  it('preselects the package manager that launched the CLI', async () => {
    const { prompter, asked } = createFakePrompter(['pnpm']);
    await runWizard(
      {
        architecture: 'angular-default',
        style: 'css',
        tailwind: true,
        rendering: 'csr',
        icons: 'none',
        git: true,
        install: true,
      },
      prompter,
      { npm_config_user_agent: 'pnpm/12.9.1 npm/? node/v24.15.0 win32 x64' },
      FULL,
    );
    expect(asked[0]?.default).toBe('pnpm');
    expect(asked[0]?.names?.some((name) => name.includes('pnpm (Default)'))).toBe(true);
  });

  it('uses the registry of the CLI by default', async () => {
    const { prompter, asked } = createFakePrompter(['angular-default', 'css', 'csr', 'none']);
    await runWizard({ ...SETTLED, routing: 'angular' }, prompter, NO_ENV);
    expect(asked[0]?.choices).toEqual(['angular-default', 'screaming']);
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
