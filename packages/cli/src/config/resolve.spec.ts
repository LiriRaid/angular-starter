import { describe, expect, it } from 'vitest';
import { UsageError } from '../errors.js';
import { DEFAULT_OPTIONS, normalizeStyleChoice, resolveOptions } from './resolve.js';
import type { StarterOptions } from './schema.js';

describe('resolveOptions', () => {
  it('returns the defaults when nothing is provided', () => {
    expect(resolveOptions({})).toEqual(DEFAULT_OPTIONS);
  });

  it('defaults to Screaming, Starter routing, Tailwind CSS, CSR, Lucide and the recommended components', () => {
    expect(DEFAULT_OPTIONS).toMatchObject({
      architecture: 'screaming',
      routing: 'starter',
      style: 'css',
      tailwind: true,
      rendering: 'csr',
      icons: 'lucide',
      components: 'recommended',
    });
  });

  it('accepts the Tailwind CSS alias of the stylesheet list in a configuration file', () => {
    const options = resolveOptions({ file: { style: 'tailwind' as never } });
    expect(options).toMatchObject({ style: 'css', tailwind: true });
  });

  it('requires Tailwind CSS for the component collections', () => {
    const run = () =>
      resolveOptions({ flags: { style: 'css', tailwind: false, components: 'all' } });
    expect(run).toThrow(/components: "all" requires Tailwind CSS/);
  });

  it('derives the defaults from what was given, so they never conflict', () => {
    const plain = resolveOptions({ flags: { architecture: 'angular-default' } });
    expect(plain.routing).toBe('angular');
    expect(plain.components).toBe('none');

    const scss = resolveOptions({ flags: { style: 'scss' } });
    expect(scss.tailwind).toBe(false);
    expect(scss.components).toBe('none');
    expect(scss.routing).toBe('starter');
  });

  it('applies precedence: defaults < file < flags', () => {
    const options = resolveOptions({
      file: { style: 'scss', prefix: 'acme', packageManager: 'pnpm' },
      flags: { prefix: 'shop' },
    });
    expect(options.style).toBe('scss');
    expect(options.packageManager).toBe('pnpm');
    expect(options.prefix).toBe('shop');
  });

  it('does not enable Tailwind by default when the style is not CSS', () => {
    expect(resolveOptions({ flags: { style: 'scss' } }).tailwind).toBe(false);
  });

  it('rejects Tailwind combined with a non-CSS stylesheet format', () => {
    expect(() => resolveOptions({ flags: { style: 'scss', tailwind: true } })).toThrow(UsageError);
    expect(() => resolveOptions({ flags: { style: 'scss', tailwind: true } })).toThrow(/CSS/);
  });

  it('rejects options that exist in the plan but are not available yet', () => {
    const run = () => resolveOptions({ flags: { architecture: 'modular' } });
    expect(run).toThrow(UsageError);
    expect(run).toThrow(/not available yet/);
    expect(run).toThrow(/angular-default/);
  });

  it('accepts the Angular Starter routing on the Screaming architecture', () => {
    const options = resolveOptions({ flags: { architecture: 'screaming', routing: 'starter' } });
    expect(options.routing).toBe('starter');
  });

  it('rejects the Angular Starter routing on an architecture without a profile', () => {
    const run = () =>
      resolveOptions({ flags: { architecture: 'angular-default', routing: 'starter' } });
    expect(run).toThrow(UsageError);
    expect(run).toThrow(/routing: "starter" requires the architecture: screaming/);
  });

  it.each([[{ icons: 'heroicons' }]] as const)('rejects unavailable option %j', (flags) => {
    expect(() => resolveOptions({ flags })).toThrow(/not available yet/);
  });

  it('includes the application shell in the defaults when the project can take it', () => {
    expect(DEFAULT_OPTIONS.appShell).toBe('starter');
    expect(resolveOptions({ flags: { appShell: 'none' } }).appShell).toBe('none');
  });

  it('leaves the application shell out of the defaults when something it needs is missing', () => {
    expect(resolveOptions({ flags: { routing: 'angular' } }).appShell).toBe('none');
    expect(resolveOptions({ flags: { architecture: 'angular-default' } }).appShell).toBe('none');
    expect(resolveOptions({ flags: { style: 'scss' } }).appShell).toBe('none');
    expect(resolveOptions({ flags: { icons: 'none' } }).appShell).toBe('none');
    expect(resolveOptions({ flags: { rendering: 'ssr' } }).appShell).toBe('none');
    expect(resolveOptions({ flags: { rendering: 'starter-ssr' } }).appShell).toBe('none');
  });

  it('keeps presence out of the defaults and accepts it on top of the shell', () => {
    expect(DEFAULT_OPTIONS.presence).toBe('none');
    expect(resolveOptions({ flags: { presence: 'starter' } }).presence).toBe('starter');
  });

  it('rejects presence without the application shell', () => {
    expect(() => resolveOptions({ flags: { presence: 'starter', appShell: 'none' } })).toThrow(
      /presence: "starter" requires the app shell: starter/,
    );
    expect(() => resolveOptions({ flags: { presence: 'starter', routing: 'angular' } })).toThrow(
      /presence: "starter" requires/,
    );
  });

  it('rejects the application shell without what it reads or draws with', () => {
    const without = (flags: Partial<StarterOptions>) => () =>
      resolveOptions({ flags: { appShell: 'starter', ...flags } });
    expect(without({ routing: 'angular' })).toThrow(
      /appShell: "starter" requires the routing: starter/,
    );
    expect(without({ icons: 'none' })).toThrow(/the icons: lucide/);
    expect(without({ rendering: 'ssr' })).toThrow(/the rendering: csr/);
    expect(without({ style: 'scss' })).toThrow(/appShell: "starter" requires/);
    expect(without({ architecture: 'angular-default' })).toThrow(/the architecture: screaming/);
  });

  it('keeps the default Angular structure plain: no Lucide unless it was asked for', () => {
    const plain = resolveOptions({ flags: { architecture: 'angular-default' } });
    expect(plain.icons).toBe('none');
    expect(plain.rendering).toBe('csr');
    expect(plain.appShell).toBe('none');
    expect(plain.layout).toBe('none');
    expect(plain.uiSystem).toBe('none');
    expect(
      resolveOptions({ flags: { architecture: 'angular-default', icons: 'lucide' } }).icons,
    ).toBe('lucide');
  });

  it('defaults the purpose of the rendering, the layout and the UI System', () => {
    expect(DEFAULT_OPTIONS).toMatchObject({
      ssrPurpose: 'none',
      layout: 'floating-wide',
      uiSystem: 'none',
    });
    expect(resolveOptions({ flags: { rendering: 'starter-ssr' } }).ssrPurpose).toBe('backoffice');
    expect(resolveOptions({ flags: { rendering: 'ssr' } }).ssrPurpose).toBe('none');
    expect(resolveOptions({ flags: { appShell: 'none' } }).layout).toBe('none');
  });

  it('accepts Starter SSR for a backoffice and refuses the purposes under construction', () => {
    expect(
      resolveOptions({ flags: { rendering: 'starter-ssr', ssrPurpose: 'backoffice' } }).ssrPurpose,
    ).toBe('backoffice');
    for (const ssrPurpose of ['landing', 'ecommerce'] as const) {
      expect(() => resolveOptions({ flags: { rendering: 'starter-ssr', ssrPurpose } })).toThrow(
        /ssrPurpose: "\w+" is not available yet. Available: none, backoffice/,
      );
    }
  });

  it('ties the purpose to Starter SSR', () => {
    expect(() => resolveOptions({ flags: { ssrPurpose: 'backoffice' } })).toThrow(
      /ssrPurpose: "backoffice" requires the rendering: starter-ssr/,
    );
    expect(() =>
      resolveOptions({ flags: { rendering: 'starter-ssr', ssrPurpose: 'none' } }),
    ).toThrow(/ssrPurpose: "none" requires the rendering: csr, ssr/);
  });

  it('ties the layout to the application shell and refuses the modes under construction', () => {
    expect(resolveOptions({ flags: { layout: 'floating-wide' } }).layout).toBe('floating-wide');
    expect(() => resolveOptions({ flags: { layout: 'compact-joined' } })).toThrow(
      /layout: "compact-joined" is not available yet. Available: none, floating-wide/,
    );
    expect(() => resolveOptions({ flags: { appShell: 'none', layout: 'floating-wide' } })).toThrow(
      /layout: "floating-wide" requires the app shell: starter/,
    );
    expect(() => resolveOptions({ flags: { layout: 'none' } })).toThrow(
      /layout: "none" requires the app shell: none/,
    );
  });

  it('accepts the UI System on top of the shell and a component collection', () => {
    expect(resolveOptions({ flags: { uiSystem: 'starter' } }).uiSystem).toBe('starter');
    expect(resolveOptions({ flags: { uiSystem: 'starter', components: 'all' } }).uiSystem).toBe(
      'starter',
    );
  });

  it('needs the shell and a component collection for the UI System', () => {
    expect(() => resolveOptions({ flags: { uiSystem: 'starter', appShell: 'none' } })).toThrow(
      /uiSystem: "starter" requires/,
    );
    expect(() => resolveOptions({ flags: { uiSystem: 'starter', components: 'none' } })).toThrow(
      /the components: recommended, all/,
    );
  });

  it('rejects unknown values and lists every issue', () => {
    expect(() => resolveOptions({ flags: { style: 'stylus' as never } })).toThrow(/style/);
  });

  it('reserves the "as" prefix and validates the format', () => {
    expect(() => resolveOptions({ flags: { prefix: 'as' } })).toThrow(/reserved/);
    expect(() => resolveOptions({ flags: { prefix: 'My_App' } })).toThrow(/prefix/);
  });

  it('ignores undefined values coming from unset flags', () => {
    const options = resolveOptions({ flags: { style: undefined, git: undefined } });
    expect(options.style).toBe(DEFAULT_OPTIONS.style);
    expect(options.git).toBe(true);
  });
});

describe('normalizeStyleChoice', () => {
  it('turns the Tailwind CSS choice into the CSS format with Tailwind enabled', () => {
    expect(normalizeStyleChoice('tailwind', undefined)).toEqual({ style: 'css', tailwind: true });
    expect(normalizeStyleChoice('tailwind', true)).toEqual({ style: 'css', tailwind: true });
  });

  it('rejects the Tailwind CSS choice together with --no-tailwind', () => {
    expect(() => normalizeStyleChoice('tailwind', false)).toThrow(UsageError);
  });

  it('leaves every other choice untouched', () => {
    expect(normalizeStyleChoice('scss', undefined)).toEqual({ style: 'scss', tailwind: undefined });
    expect(normalizeStyleChoice(undefined, false)).toEqual({ style: undefined, tailwind: false });
  });
});
