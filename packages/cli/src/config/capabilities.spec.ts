import { describe, expect, it } from 'vitest';
import {
  CAPABILITIES,
  CATEGORIES,
  availableIds,
  SHOWN_WHEN_PLANNED,
  defaultOption,
  offeredOptions,
  recommendedOption,
  unmetRequirements,
} from './capabilities.js';

const everyOption = CATEGORIES.flatMap((category) =>
  CAPABILITIES[category].map((option) => ({ category, option })),
);

describe('capability registry', () => {
  it.each(everyOption)('$category/$option.id explains itself', ({ option }) => {
    expect(option.label.length).toBeGreaterThan(0);
    expect(option.description.length).toBeGreaterThan(20);
    expect(option.description.endsWith('.')).toBe(true);
    if (option.docs !== undefined) expect(option.docs).toMatch(/^https?:\/\/\S+$/);
  });

  it('points every option that installs something to its official documentation', () => {
    const withoutDocs = everyOption
      .filter(({ option }) => option.docs === undefined)
      .map(({ category, option }) => `${category}/${option.id}`);
    expect(withoutDocs).toEqual(['icons/none']);
  });

  it('has one stylesheet list: CSS, Tailwind CSS (recommended), SCSS, Sass and Less', () => {
    expect(CAPABILITIES.style.map((option) => option.id)).toEqual([
      'css',
      'tailwind',
      'scss',
      'sass',
      'less',
    ]);
    expect(CAPABILITIES.style.filter((option) => option.recommended).map((o) => o.id)).toEqual([
      'tailwind',
    ]);
    expect(CAPABILITIES.style.find((option) => option.id === 'tailwind')?.docs).toBe(
      'https://tailwindcss.com',
    );
  });

  it('recommends only what has one best answer and leaves the project shape to the user', () => {
    const recommended = CATEGORIES.map((category) => [
      category,
      CAPABILITIES[category].filter((option) => option.recommended).map((option) => option.id),
    ]);
    expect(Object.fromEntries(recommended)).toEqual({
      architecture: [],
      routing: [],
      style: ['tailwind'],
      rendering: ['csr'],
      ssrPurpose: [],
      appShell: [],
      layout: ['floating-wide'],
      presence: [],
      components: [],
      uiSystem: [],
      icons: ['lucide'],
      packageManager: [],
    });
  });

  it('lists the categories in the order of the wizard, each answer opening the next', () => {
    expect(CATEGORIES).toEqual([
      'architecture',
      'routing',
      'style',
      'rendering',
      'ssrPurpose',
      'appShell',
      'layout',
      'presence',
      'components',
      'uiSystem',
      'icons',
      'packageManager',
    ]);
  });

  it('keeps what only the wizard offers apart from what a project needs', () => {
    const lucide = CAPABILITIES.icons.find((option) => option.id === 'lucide');
    const starterSsr = CAPABILITIES.rendering.find((option) => option.id === 'starter-ssr');
    expect(lucide?.offeredWith).toEqual({ architecture: ['screaming'] });
    expect(starterSsr?.offeredWith).toEqual({ architecture: ['screaming'] });
    // A project with Angular's own structure may still have Lucide: it is not a requirement.
    expect(lucide?.requires).toBeUndefined();
    expect(starterSsr?.requires).toBeUndefined();
  });

  it('offers neither Lucide nor Starter SSR where the default Angular structure is chosen', () => {
    const angular = { architecture: 'angular-default' };
    expect(defaultOption('icons', angular)).toBeUndefined();
    expect(recommendedOption('icons', angular)).toBeUndefined();
    expect(offeredOptions('rendering', angular).map((option) => option.id)).toEqual(['csr', 'ssr']);
    expect(offeredOptions('icons', angular).map((option) => option.id)).toEqual(['none']);
    expect(offeredOptions('rendering', { architecture: 'screaming' }).map((o) => o.id)).toEqual([
      'csr',
      'ssr',
      'starter-ssr',
    ]);
  });

  it('asks the purpose of Starter SSR: landing and ecommerce are under construction', () => {
    expect(CAPABILITIES.ssrPurpose.map((option) => option.id)).toEqual([
      'none',
      'landing',
      'ecommerce',
      'backoffice',
    ]);
    expect(availableIds('ssrPurpose')).toEqual(['none', 'backoffice']);
    const backoffice = CAPABILITIES.ssrPurpose.find((option) => option.id === 'backoffice');
    expect(backoffice?.default).toBe(true);
    expect(backoffice?.requires).toEqual({ rendering: ['starter-ssr'] });
    expect(CAPABILITIES.ssrPurpose.find((option) => option.id === 'none')?.requires).toEqual({
      rendering: ['csr', 'ssr'],
    });
  });

  it('has the six layout modes of the demo and only the floating wide one built', () => {
    expect(CAPABILITIES.layout.map((option) => option.id)).toEqual([
      'none',
      'wide-joined',
      'compact-joined',
      'floating-wide',
      'floating-compact',
      'transparent-joined',
      'transparent-floating',
    ]);
    expect(availableIds('layout')).toEqual(['none', 'floating-wide']);
    const floating = CAPABILITIES.layout.find((option) => option.id === 'floating-wide');
    expect(floating?.recommended).toBe(true);
    expect(floating?.default).toBe(true);
    expect(floating?.requires).toEqual({ appShell: ['starter'] });
    expect(CAPABILITIES.layout.find((option) => option.id === 'none')?.requires).toEqual({
      appShell: ['none'],
    });
  });

  it('shows the planned layouts and purposes in the wizard, and nothing else', () => {
    expect(SHOWN_WHEN_PLANNED).toEqual(['ssrPurpose', 'layout']);
  });

  it('offers the UI System on top of the shell and a component collection', () => {
    expect(CAPABILITIES.uiSystem.map((option) => option.id)).toEqual(['none', 'starter']);
    expect(availableIds('uiSystem')).toEqual(['none', 'starter']);
    const starter = CAPABILITIES.uiSystem.find((option) => option.id === 'starter');
    expect(starter?.requires).toEqual({
      architecture: ['screaming'],
      appShell: ['starter'],
      components: ['recommended', 'all'],
      tailwind: true,
    });
    expect(starter?.default).toBeUndefined();
    expect(unmetRequirements(starter!, { appShell: 'starter', components: 'none' })).toEqual([
      'the components: recommended, all',
    ]);
  });

  it('says how many components each collection brings', () => {
    const [none, essential, all] = CAPABILITIES.components;
    expect(none?.id).toBe('none');
    expect(essential?.description).toMatch(/\b16\b/);
    expect(all?.description).toMatch(/\b26\b/);
    expect(all?.description).toMatch(/16/);
  });

  it('has a custom selection next to the collections, asked for what they ask for', () => {
    expect(CAPABILITIES.components.map((option) => option.id)).toEqual([
      'none',
      'recommended',
      'all',
      'custom',
    ]);
    const custom = CAPABILITIES.components.find((option) => option.id === 'custom');
    expect(custom?.requires).toEqual({
      architecture: ['screaming'],
      tailwind: true,
      icons: ['lucide'],
    });
    expect(custom?.docs).toContain('0011-components-picker');
    expect(custom?.recommended).toBeUndefined();
    expect(custom?.default).toBeUndefined();
  });

  it('says that no shell means the default Angular screen', () => {
    const none = CAPABILITIES.appShell.find((option) => option.id === 'none');
    expect(none?.description).toMatch(/default Angular/i);
  });

  it('offers presence like any other option, only on top of the application shell', () => {
    expect(availableIds('presence')).toEqual(['none', 'starter']);
    const starter = CAPABILITIES.presence.find((option) => option.id === 'starter');
    expect(starter?.docs).toBe(
      'https://github.com/LiriRaid/as-starter/blob/main/docs/adr/0009-presence-documentation-and-welcome-home.md',
    );
    expect(starter?.recommended).toBeUndefined();
    expect(starter?.default).toBeUndefined();
    expect(starter?.requires).toEqual({ appShell: ['starter'] });
    expect(CAPABILITIES.presence.find((option) => option.id === 'none')?.docs).toBeDefined();
  });

  it('names the application shell that presence needs', () => {
    const presence = CAPABILITIES.presence.find((option) => option.id === 'starter');
    expect(unmetRequirements(presence!, { appShell: 'none' })).toEqual(['the app shell: starter']);
    expect(unmetRequirements(presence!, { appShell: 'starter' })).toEqual([]);
    expect(unmetRequirements(presence!, {})).toEqual([]);
  });

  it('leaves presence out of the default: it is a realtime layer a project opts into', () => {
    expect(defaultOption('presence', { appShell: 'starter' })).toBeUndefined();
  });

  it('offers the application shell like any other option: none or the Angular Starter App Shell', () => {
    expect(availableIds('appShell')).toEqual(['none', 'starter']);
    const starter = CAPABILITIES.appShell.find((option) => option.id === 'starter');
    expect(starter?.label).toBe('Angular Starter App Shell');
    expect(starter?.docs).toBe(
      'https://github.com/LiriRaid/as-starter/blob/main/docs/adr/0008-app-shell.md',
    );
    expect(starter?.default).toBe(true);
    expect(starter?.recommended).toBeUndefined();
    expect(starter?.requires).toEqual({
      architecture: ['screaming'],
      routing: ['starter'],
      rendering: ['csr'],
      tailwind: true,
      icons: ['lucide'],
    });
  });

  it('documents the Screaming Architecture with the ADR of this project, not an article', () => {
    expect(CAPABILITIES.architecture.find((option) => option.id === 'screaming')?.docs).toBe(
      'https://github.com/LiriRaid/as-starter/blob/main/docs/adr/0002-screaming-architecture-profile.md',
    );
  });

  it('explains the three rendering strategies with their documentation', () => {
    expect(CAPABILITIES.rendering.map((option) => option.id)).toEqual([
      'csr',
      'ssr',
      'starter-ssr',
    ]);
    const [csr, ssr, starter] = CAPABILITIES.rendering;
    expect(csr?.description).toMatch(/back office/i);
    expect(ssr?.docs).toBe('https://angular.dev/guide/ssr');
    expect(starter?.docs).toBe('https://angular.dev/guide/incremental-hydration');
    expect(starter?.description).toMatch(/portfolio/i);
  });

  it('offers the three rendering strategies', () => {
    expect(availableIds('rendering')).toEqual(['csr', 'ssr', 'starter-ssr']);
  });

  it('keeps planned options out of the available ids', () => {
    expect(availableIds('architecture')).toEqual(['angular-default', 'screaming']);
    expect(availableIds('icons')).not.toContain('heroicons');
  });
});

describe('recommendedOption', () => {
  it('returns the recommended option that is available', () => {
    expect(recommendedOption('style', {})?.id).toBe('tailwind');
    expect(recommendedOption('rendering', {})?.id).toBe('csr');
    expect(recommendedOption('icons', {})?.id).toBe('lucide');
  });

  it('has none where the user decides what to work with', () => {
    expect(recommendedOption('architecture', {})).toBeUndefined();
    expect(recommendedOption('routing', { architecture: 'screaming' })).toBeUndefined();
    expect(recommendedOption('components', { architecture: 'screaming' })).toBeUndefined();
  });
});

describe('defaultOption', () => {
  const context = {
    architecture: 'screaming',
    routing: 'starter',
    style: 'css',
    tailwind: true,
    icons: 'lucide',
  };

  it('names the silent choice of --defaults for every category', () => {
    expect(defaultOption('architecture', {})?.id).toBe('screaming');
    expect(defaultOption('routing', context)?.id).toBe('starter');
    expect(defaultOption('components', context)?.id).toBe('recommended');
    expect(defaultOption('appShell', context)?.id).toBe('starter');
    expect(defaultOption('style', {})?.id).toBe('tailwind');
  });

  it('leaves the application shell out of the default when the project cannot take it', () => {
    expect(defaultOption('appShell', { ...context, routing: 'angular' })).toBeUndefined();
    expect(defaultOption('appShell', { ...context, icons: 'none' })).toBeUndefined();
    expect(defaultOption('appShell', { ...context, tailwind: false })).toBeUndefined();
    expect(defaultOption('appShell', { ...context, rendering: 'ssr' })).toBeUndefined();
  });

  it('falls back to undefined when the default cannot be used', () => {
    expect(defaultOption('routing', { architecture: 'angular-default' })).toBeUndefined();
    expect(
      defaultOption('components', { architecture: 'screaming', style: 'css', tailwind: false }),
    ).toBeUndefined();
  });
});

describe('unmetRequirements', () => {
  const starter = CAPABILITIES.routing.find((option) => option.id === 'starter');

  it('names the architecture a routing needs', () => {
    expect(starter).toBeDefined();
    expect(unmetRequirements(starter!, { architecture: 'angular-default' })).toEqual([
      'the architecture: screaming',
    ]);
    expect(unmetRequirements(starter!, { architecture: 'screaming' })).toEqual([]);
  });

  it('names the routing the application shell reads its navigation from', () => {
    const shell = CAPABILITIES.appShell.find((option) => option.id === 'starter');
    expect(shell).toBeDefined();
    expect(
      unmetRequirements(shell!, {
        architecture: 'screaming',
        routing: 'angular',
        tailwind: true,
        icons: 'lucide',
      }),
    ).toEqual(['the routing: starter']);
  });

  it('names every missing requirement of a component collection', () => {
    const components = CAPABILITIES.components.find((option) => option.id === 'recommended');
    expect(components).toBeDefined();
    expect(
      unmetRequirements(components!, {
        architecture: 'angular-default',
        style: 'scss',
        tailwind: false,
        icons: 'none',
      }),
    ).toEqual(['the architecture: screaming', 'the icons: lucide', 'Tailwind CSS']);
    expect(
      unmetRequirements(components!, {
        architecture: 'screaming',
        style: 'css',
        tailwind: true,
        icons: 'lucide',
      }),
    ).toEqual([]);
  });
});
