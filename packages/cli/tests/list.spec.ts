import { describe, expect, it } from 'vitest';
import { run } from '../src/main.js';
import { createFakeIo } from './helpers/fake-io.js';

async function list(...args: string[]): Promise<string> {
  const fake = createFakeIo();
  expect(await run(['list', ...args], fake.io)).toBe(0);
  return fake.out();
}

describe('as list: the command of each option', () => {
  it('says how to add an option to a project and how to ask for it in as new', async () => {
    const out = await list('components');
    expect(out).toContain('Add: as add components recommended');
    expect(out).toContain('Add: as add components all');
    expect(out).toContain('New: as new --components recommended');
  });

  it('shows no Add line for what a project that does not use the capability already is', async () => {
    const out = await list('components');
    expect(out).not.toContain('as add components none');
    expect(out).toContain('New: as new --components none');
  });

  it('shows only the New line for what as add cannot change', async () => {
    const out = await list('style');
    expect(out).toContain('New: as new --style scss');
    expect(out).not.toContain('as add style');
  });

  it('writes the flags of the categories that have a compound name', async () => {
    expect(await list('uiSystem')).toContain('New: as new --ui-system starter');
    expect(await list('appShell')).toContain('Add: as add app-shell starter');
    expect(await list('packageManager')).toContain('New: as new --package-manager pnpm');
  });

  it('gives no command to an option that is only planned', async () => {
    const out = await list('architecture');
    const planned = out.slice(out.indexOf('modular'));
    expect(planned).not.toContain('as new --architecture modular');
  });

  it.each([
    ['app-shell', 'appShell'],
    ['ui-system', 'uiSystem'],
    ['ssr-purpose', 'ssrPurpose'],
    ['package-manager', 'packageManager'],
  ])('accepts %s as a name of the category %s', async (kebab, camel) => {
    expect(await list(kebab)).toBe(await list(camel));
  });

  it('still rejects a category that does not exist and names the valid ones', async () => {
    const fake = createFakeIo();
    expect(await run(['list', 'nope'], fake.io)).toBe(2);
    expect(fake.err()).toContain('Unknown category "nope"');
  });
});
