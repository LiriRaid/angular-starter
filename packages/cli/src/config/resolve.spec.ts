import { describe, expect, it } from 'vitest';
import { UsageError } from '../errors.js';
import { DEFAULT_OPTIONS, resolveOptions } from './resolve.js';

describe('resolveOptions', () => {
  it('returns the defaults when nothing is provided', () => {
    expect(resolveOptions({})).toEqual(DEFAULT_OPTIONS);
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
    const run = () => resolveOptions({ flags: { routing: 'starter' } });
    expect(run).toThrow(UsageError);
    expect(run).toThrow(/routing: "starter" requires the architecture: screaming/);
  });

  it.each([
    [{ rendering: 'starter-ssr' }],
    [{ components: 'recommended' }],
    [{ icons: 'heroicons' }],
    [{ appShell: true }],
  ] as const)('rejects unavailable option %j', (flags) => {
    expect(() => resolveOptions({ flags })).toThrow(/not available yet/);
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
