import { describe, expect, it } from 'vitest';
import { ANGULAR_CLI_VERSION } from '../src/compat.js';
import { run } from '../src/main.js';
import { createFakeIo } from './helpers/fake-io.js';

const COMMANDS = [
  'generate',
  'add',
  'config',
  'list',
  'info',
  'doctor',
  'update',
  'version',
  'help',
];

describe('as (program)', () => {
  it('prints help when called without arguments', async () => {
    const fake = createFakeIo();
    expect(await run([], fake.io)).toBe(0);
    const out = fake.out();
    expect(out).toContain('Angular Starter CLI');
    expect(out).toContain('Usage: as [command] [options]');
    for (const command of COMMANDS) expect(out).toMatch(new RegExp(`^ {2}${command}\\b`, 'm'));
    expect(out).toContain('-h, --help');
    expect(out).toContain('-v, --version');
  });

  it.each([['--help'], ['-h']])('prints help with %s', async (flag) => {
    const fake = createFakeIo();
    expect(await run([flag], fake.io)).toBe(0);
    expect(fake.out()).toContain('Usage: as [command] [options]');
  });

  it.each([['--version'], ['-v'], ['version']])('prints the version with %s', async (flag) => {
    const fake = createFakeIo();
    expect(await run([flag], fake.io)).toBe(0);
    expect(fake.out().trim()).toMatch(/^\d+\.\d+\.\d+/);
  });

  it('shows command help', async () => {
    const fake = createFakeIo();
    expect(await run(['list', '--help'], fake.io)).toBe(0);
    expect(fake.out()).toContain('Usage: as list');
  });

  it('exits with code 2 on an unknown command', async () => {
    const fake = createFakeIo();
    expect(await run(['nope'], fake.io)).toBe(2);
    expect(fake.err()).toContain('unknown command');
  });

  it('exits with code 2 on an unknown option', async () => {
    const fake = createFakeIo();
    expect(await run(['list', '--nope'], fake.io)).toBe(2);
  });

  it.each(['generate', 'add', 'config', 'update'])(
    '%s says it is not available yet',
    async (command) => {
      const fake = createFakeIo();
      expect(await run([command], fake.io)).toBe(1);
      expect(fake.err()).toContain('not available yet');
    },
  );

  it('lists available and planned options', async () => {
    const fake = createFakeIo();
    expect(await run(['list'], fake.io)).toBe(0);
    const out = fake.out();
    expect(out).toContain('angular-default');
    expect(out).toMatch(/screaming(?!.*planned)/);
    expect(out).toMatch(/modular.*planned/);
  });

  it('explains every option in the list: label, documentation and description', async () => {
    const fake = createFakeIo();
    expect(await run(['list', 'style'], fake.io)).toBe(0);
    const out = fake.out();
    expect(out).toContain('Stylesheet formats (style)');
    expect(out).toMatch(/^ {2}tailwind +Tailwind CSS \(Recommended\)/m);
    expect(out).toContain('https://tailwindcss.com');
    expect(out).toContain('Utility-first');
    expect(out).toMatch(/^ {2}css +CSS/m);
  });

  it('prints environment information', async () => {
    const fake = createFakeIo();
    expect(await run(['info'], fake.io)).toBe(0);
    expect(fake.out()).toContain(process.versions.node);
    expect(fake.out()).toContain(ANGULAR_CLI_VERSION);
  });
});
