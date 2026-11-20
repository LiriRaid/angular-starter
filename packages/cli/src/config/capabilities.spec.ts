import { describe, expect, it } from 'vitest';
import {
  CAPABILITIES,
  CATEGORIES,
  availableIds,
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

  it('marks exactly the recommended choices', () => {
    const recommended = CATEGORIES.map((category) => [
      category,
      CAPABILITIES[category].filter((option) => option.recommended).map((option) => option.id),
    ]);
    expect(Object.fromEntries(recommended)).toEqual({
      architecture: ['screaming'],
      routing: ['starter'],
      style: ['tailwind'],
      rendering: ['csr'],
      components: ['recommended'],
      icons: ['lucide'],
      packageManager: [],
    });
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
  it('returns the recommended option that is available and whose requirements are met', () => {
    expect(recommendedOption('architecture', {})?.id).toBe('screaming');
    expect(
      recommendedOption('routing', { architecture: 'screaming', style: 'css', icons: 'lucide' })
        ?.id,
    ).toBe('starter');
  });

  it('falls back to undefined when the recommended option cannot be used', () => {
    expect(recommendedOption('routing', { architecture: 'angular-default' })).toBeUndefined();
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

  it('names every missing requirement of a component collection', () => {
    const components = CAPABILITIES.components.find((option) => option.id === 'recommended');
    expect(components).toBeDefined();
    expect(
      unmetRequirements(components!, {
        architecture: 'angular-default',
        style: 'scss',
        icons: 'none',
      }),
    ).toEqual(['the architecture: screaming', 'the stylesheet format: css', 'the icons: lucide']);
    expect(
      unmetRequirements(components!, { architecture: 'screaming', style: 'css', icons: 'lucide' }),
    ).toEqual([]);
  });
});
