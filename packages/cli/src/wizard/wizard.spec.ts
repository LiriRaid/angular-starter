import { describe, expect, it } from 'vitest';
import { createFakePrompter } from '../../tests/helpers/fake-prompter.js';
import { CAPABILITIES, type CapabilityOption, type Registry } from '../config/capabilities.js';
import {
  ALL_COMPONENT_IDS,
  ESSENTIAL_COMPONENT_IDS,
  EXTRA_COMPONENT_IDS,
} from '../config/components.js';
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
  'landing',
  'ecommerce',
  'wide-joined',
  'compact-joined',
  'floating-compact',
  'transparent-joined',
  'transparent-floating',
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
      'starter',
      'floating-wide',
      'none',
      'recommended',
      [...ESSENTIAL_COMPONENT_IDS],
      'none',
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
    // The architecture, the routing, the shell, presence, the components and the UI System are the
    // user's call: nothing is preselected. The layout starts on the one that exists.
    expect(asked.slice(0, 10).map((question) => question.default)).toEqual([
      undefined,
      undefined,
      'tailwind',
      'csr',
      undefined,
      'floating-wide',
      undefined,
      undefined,
      undefined,
      undefined,
    ]);
    expect(answers).toEqual({
      architecture: 'screaming',
      routing: 'starter',
      style: 'css',
      tailwind: true,
      rendering: 'csr',
      appShell: 'starter',
      layout: 'floating-wide',
      presence: 'none',
      components: 'recommended',
      uiSystem: 'none',
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

    // The default Angular structure is plain: no icon library question either.
    const plain = createFakePrompter([]);
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
    expect(plain.asked).toEqual([]);

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

  it('asks for the application shell after the rendering and implies Lucide with it', async () => {
    const { prompter, asked } = createFakePrompter(['starter', 'floating-wide', 'none', 'none']);
    const answers = await runWizard(
      {
        ...SETTLED,
        architecture: 'screaming',
        routing: 'starter',
        style: 'css',
        tailwind: true,
        rendering: 'csr',
      },
      prompter,
      NO_ENV,
      FULL,
    );
    expect(asked.map((question) => question.name)).toEqual([
      'appShell',
      'layout',
      'presence',
      'components',
    ]);
    expect(asked[0]?.choices).toEqual(['none', 'starter']);
    expect(asked[0]?.names?.[1]).toMatch(
      /^Angular Starter App Shell +\[ https:\/\/github\.com\/LiriRaid\/\S+0008-app-shell\.md +\]$/,
    );
    expect(answers).toEqual({
      appShell: 'starter',
      layout: 'floating-wide',
      presence: 'none',
      components: 'none',
      icons: 'lucide',
    });
  });

  it('asks for presence right after the shell, with the link to its decision', async () => {
    const { prompter, asked } = createFakePrompter(['starter', 'floating-wide', 'starter', 'none']);
    const answers = await runWizard(
      {
        ...SETTLED,
        architecture: 'screaming',
        routing: 'starter',
        style: 'css',
        tailwind: true,
        rendering: 'csr',
      },
      prompter,
      NO_ENV,
      FULL,
    );
    const presence = asked[2];
    expect(presence?.name).toBe('presence');
    expect(presence?.message).toBe('Which real-time presence would you like to use?');
    expect(presence?.choices).toEqual(['none', 'starter']);
    expect(presence?.default).toBeUndefined();
    expect(presence?.names?.[1]).toMatch(
      /^Angular Starter Presence +\[ https:\/\/github\.com\/LiriRaid\/\S+0009-\S+\.md +\]$/,
    );
    expect(answers).toMatchObject({ appShell: 'starter', presence: 'starter' });
  });

  it('does not ask for presence without the application shell', async () => {
    const none = createFakePrompter(['none', 'none', 'none']);
    await runWizard(
      {
        ...SETTLED,
        architecture: 'screaming',
        routing: 'starter',
        style: 'css',
        tailwind: true,
        rendering: 'csr',
      },
      none.prompter,
      NO_ENV,
      FULL,
    );
    expect(none.asked.map((question) => question.name)).toEqual([
      'appShell',
      'components',
      'icons',
    ]);

    const angular = createFakePrompter(['none', 'none']);
    await runWizard(
      {
        ...SETTLED,
        architecture: 'screaming',
        routing: 'angular',
        style: 'css',
        tailwind: true,
        rendering: 'csr',
      },
      angular.prompter,
      NO_ENV,
      FULL,
    );
    expect(angular.asked.map((question) => question.name)).not.toContain('presence');
  });

  it('does not ask for the application shell when the project cannot take it', async () => {
    const angular = createFakePrompter(['none']);
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
      angular.prompter,
      NO_ENV,
      FULL,
    );
    expect(angular.asked.map((question) => question.name)).not.toContain('appShell');

    const noLucide = createFakePrompter([]);
    await runWizard(
      {
        ...SETTLED,
        architecture: 'screaming',
        routing: 'starter',
        style: 'css',
        tailwind: true,
        rendering: 'csr',
        icons: 'none',
      },
      noLucide.prompter,
      NO_ENV,
      FULL,
    );
    expect(noLucide.asked.map((question) => question.name)).toEqual([]);
  });

  it('does not ask again for what a flag already decided', async () => {
    const { prompter, asked } = createFakePrompter([]);
    const answers = await runWizard(
      {
        ...SETTLED,
        architecture: 'screaming',
        routing: 'starter',
        style: 'css',
        tailwind: true,
        rendering: 'csr',
        appShell: 'starter',
        layout: 'floating-wide',
        presence: 'none',
        components: 'recommended',
        uiSystem: 'none',
      },
      prompter,
      NO_ENV,
      FULL,
    );
    expect(asked).toEqual([]);
    expect(answers).toEqual({ icons: 'lucide' });
  });

  it('never offers options that cannot be generated', async () => {
    const { prompter, asked } = createFakePrompter([
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
    ]);
    await runWizard({}, prompter, NO_ENV, FULL);
    // The layouts under construction are listed, disabled: they cannot be chosen.
    const everyChoice = asked.flatMap((question) =>
      (question.choices ?? []).filter((choice) => !(choice in (question.disabled ?? {}))),
    );
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

  it('asks only the stylesheet and the rendering for the default Angular structure', async () => {
    const { prompter, asked } = createFakePrompter(['angular-default', 'scss', 'ssr']);
    const answers = await runWizard({ ...SETTLED }, prompter, NO_ENV, FULL);
    expect(asked.map((question) => question.name)).toEqual(['architecture', 'style', 'rendering']);
    expect(asked[1]?.choices).toEqual(['css', 'tailwind', 'scss', 'sass', 'less']);
    // Starter SSR is a Screaming option: Angular's own structure gets Angular's own server rendering.
    expect(asked[2]?.choices).toEqual(['csr', 'ssr']);
    expect(answers).toEqual({
      architecture: 'angular-default',
      style: 'scss',
      tailwind: false,
      rendering: 'ssr',
    });
  });

  it('opens the routing right after the Screaming Architecture', async () => {
    const { prompter, asked } = createFakePrompter(['screaming', 'angular', 'scss', 'csr', 'none']);
    await runWizard({ ...SETTLED }, prompter, NO_ENV, FULL);
    expect(asked.slice(0, 2).map((question) => question.name)).toEqual(['architecture', 'routing']);
    expect(asked[1]?.choices).toEqual(['angular', 'starter']);
    expect(asked[2]?.name).toBe('style');
    expect(asked[3]?.name).toBe('rendering');
    expect(asked[3]?.choices).toEqual(['csr', 'ssr', 'starter-ssr']);
  });

  it('asks what Starter SSR is for, listing the purposes under construction disabled', async () => {
    const { prompter, asked } = createFakePrompter([
      'screaming',
      'starter',
      'tailwind',
      'starter-ssr',
      'backoffice',
      'none',
      'none',
    ]);
    const answers = await runWizard({ ...SETTLED }, prompter, NO_ENV, FULL);
    expect(asked.map((question) => question.name)).toEqual([
      'architecture',
      'routing',
      'style',
      'rendering',
      'ssrPurpose',
      'components',
      'icons',
    ]);
    const purpose = asked[4];
    expect(purpose?.message).toBe('What is the Starter SSR for?');
    expect(purpose?.choices).toEqual(['landing', 'ecommerce', 'backoffice']);
    expect(Object.keys(purpose?.disabled ?? {})).toEqual(['landing', 'ecommerce']);
    expect(purpose?.disabled?.['landing']).toMatch(/Under construction/);
    expect(purpose?.default).toBeUndefined();
    // The shell needs client-side rendering (ADR-0008): a server-rendered backoffice has none yet.
    expect(answers).toMatchObject({ rendering: 'starter-ssr', ssrPurpose: 'backoffice' });
    expect(answers.appShell).toBeUndefined();
  });

  it('does not ask for a purpose unless the rendering is Starter SSR', async () => {
    const { prompter, asked } = createFakePrompter([]);
    await runWizard(
      {
        ...SETTLED,
        architecture: 'screaming',
        routing: 'angular',
        style: 'css',
        tailwind: true,
        rendering: 'ssr',
        components: 'none',
        icons: 'none',
      },
      prompter,
      NO_ENV,
      FULL,
    );
    expect(asked.map((question) => question.name)).not.toContain('ssrPurpose');
  });

  it('asks the layout of the shell, with the one that exists preselected and the rest disabled', async () => {
    const { prompter, asked } = createFakePrompter(['starter', 'floating-wide', 'none', 'none']);
    await runWizard(
      {
        ...SETTLED,
        architecture: 'screaming',
        routing: 'starter',
        style: 'css',
        tailwind: true,
        rendering: 'csr',
      },
      prompter,
      NO_ENV,
      FULL,
    );
    const layout = asked[1];
    expect(layout?.name).toBe('layout');
    expect(layout?.message).toBe('Which layout mode would you like for the application shell?');
    expect(layout?.choices).toEqual([
      'wide-joined',
      'compact-joined',
      'floating-wide',
      'floating-compact',
      'transparent-joined',
      'transparent-floating',
    ]);
    expect(layout?.default).toBe('floating-wide');
    expect(layout?.names?.[2]).toMatch(/^Floating \(wide\) \(Recommended\)/);
    expect(Object.keys(layout?.disabled ?? {})).toEqual([
      'wide-joined',
      'compact-joined',
      'floating-compact',
      'transparent-joined',
      'transparent-floating',
    ]);
    expect(layout?.disabled?.['compact-joined']).toBe('Under construction');
  });

  it('does not ask for a layout when there is no shell', async () => {
    const { prompter, asked } = createFakePrompter(['none', 'none', 'none']);
    const answers = await runWizard(
      {
        ...SETTLED,
        architecture: 'screaming',
        routing: 'starter',
        style: 'css',
        tailwind: true,
        rendering: 'csr',
      },
      prompter,
      NO_ENV,
      FULL,
    );
    expect(asked.map((question) => question.name)).not.toContain('layout');
    expect(answers.layout).toBeUndefined();
  });

  it('asks for the UI System only with the shell and a component collection', async () => {
    const withCollection = createFakePrompter(['starter']);
    const answers = await runWizard(
      {
        ...SETTLED,
        architecture: 'screaming',
        routing: 'starter',
        style: 'css',
        tailwind: true,
        rendering: 'csr',
        appShell: 'starter',
        layout: 'floating-wide',
        presence: 'none',
        components: 'recommended',
      },
      withCollection.prompter,
      NO_ENV,
      FULL,
    );
    expect(withCollection.asked.map((question) => question.name)).toEqual(['uiSystem']);
    expect(withCollection.asked[0]?.choices).toEqual(['none', 'starter']);
    expect(answers).toEqual({ uiSystem: 'starter', icons: 'lucide' });

    const withoutCollection = createFakePrompter([]);
    await runWizard(
      {
        ...SETTLED,
        architecture: 'screaming',
        routing: 'starter',
        style: 'css',
        tailwind: true,
        rendering: 'csr',
        appShell: 'starter',
        layout: 'floating-wide',
        presence: 'none',
        components: 'none',
      },
      withoutCollection.prompter,
      NO_ENV,
      FULL,
    );
    expect(withoutCollection.asked).toEqual([]);
  });

  describe('the components picker (ADR-0011)', () => {
    const KNOWN = {
      ...SETTLED,
      architecture: 'screaming',
      routing: 'starter',
      style: 'css',
      tailwind: true,
      rendering: 'csr',
      appShell: 'none',
      icons: 'lucide',
    } as const;

    it('lists every component after the collection, with the essential ones ticked', async () => {
      const { prompter, asked } = createFakePrompter(['recommended', [...ESSENTIAL_COMPONENT_IDS]]);
      const answers = await runWizard(KNOWN, prompter, NO_ENV, FULL);
      expect(asked.map((question) => question.name)).toEqual(['components', 'componentList']);
      const list = asked[1];
      expect(list?.kind).toBe('checkbox');
      expect(list?.message).toBe('Which components do you want to generate?');
      expect(list?.choices).toEqual([...ALL_COMPONENT_IDS]);
      expect(list?.checked).toEqual([...ESSENTIAL_COMPONENT_IDS]);
      expect(answers).toEqual({ components: 'recommended' });
    });

    it('starts with all of them ticked when all the components were chosen', async () => {
      const { prompter, asked } = createFakePrompter(['all', [...ALL_COMPONENT_IDS]]);
      const answers = await runWizard(KNOWN, prompter, NO_ENV, FULL);
      expect(asked[1]?.checked).toEqual([...ALL_COMPONENT_IDS]);
      expect(answers).toEqual({ components: 'all' });
    });

    it('records a custom selection when the ticks change', async () => {
      const picked = [...EXTRA_COMPONENT_IDS.slice(0, 2), 'button', 'icon'];
      const { prompter } = createFakePrompter(['recommended', picked]);
      const answers = await runWizard(KNOWN, prompter, NO_ENV, FULL);
      expect(answers).toEqual({ components: 'custom', componentList: picked });
    });

    it('records none when everything is unticked', async () => {
      const { prompter } = createFakePrompter(['all', []]);
      const answers = await runWizard(KNOWN, prompter, NO_ENV, FULL);
      expect(answers).toEqual({ components: 'none' });
    });

    it('says what each component brings: its description, what it imports and its stylesheet', async () => {
      const { prompter, asked } = createFakePrompter(['recommended', [...ESSENTIAL_COMPONENT_IDS]]);
      await runWizard(KNOWN, prompter, NO_ENV, FULL);
      const list = asked[1];
      const names = list?.names ?? [];
      const descriptions = list?.descriptions ?? [];
      const button = list?.choices?.indexOf('button') ?? -1;
      expect(names[button]).toContain('as-button');
      expect(descriptions[button]).toMatch(/Button with severities/);
      expect(descriptions[button]).toContain('button-styles.css');
      expect(descriptions[button]).toMatch(/brings: icon/i);
      expect(descriptions[list?.choices?.indexOf('toggle') ?? -1]).not.toMatch(/brings/i);
    });

    it('does not ask for the list without components, or when a flag decided them', async () => {
      const none = createFakePrompter(['none']);
      await runWizard(KNOWN, none.prompter, NO_ENV, FULL);
      expect(none.asked.map((question) => question.name)).toEqual(['components']);

      const flag = createFakePrompter([]);
      await runWizard(
        { ...KNOWN, components: 'custom', componentList: ['button'] },
        flag.prompter,
        NO_ENV,
        FULL,
      );
      expect(flag.asked).toEqual([]);
    });

    it('never offers the custom selection as an answer of its own', async () => {
      const { prompter, asked } = createFakePrompter(['none']);
      await runWizard(KNOWN, prompter, NO_ENV, FULL);
      expect(asked[0]?.choices).toEqual(['none', 'recommended', 'all']);
    });
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
