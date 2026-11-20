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

  it('update says it is not available yet', async () => {
    const fake = createFakeIo();
    expect(await run(['update'], fake.io)).toBe(1);
    expect(fake.err()).toContain('not available yet');
  });

  it('groups the commands by what they do, in the root help', async () => {
    const fake = createFakeIo();
    await run(['--help'], fake.io);
    const out = fake.out();
    const positions = [
      'Create a project',
      '  new ',
      'Change an existing project',
      '  add ',
      '  generate',
      'Inspect',
      '  list',
      '  config',
      '  doctor',
      'Planned',
      '  update',
    ].map((text) => out.indexOf(text));
    expect(
      positions.every((position) => position >= 0),
      out,
    ).toBe(true);
    expect(positions).toEqual([...positions].sort((a, b) => a - b));
  });

  it('shows examples and says what only `as new` can decide, in the root help', async () => {
    const fake = createFakeIo();
    await run(['--help'], fake.io);
    const out = fake.out();
    expect(out).toContain('Examples:');
    expect(out).toContain('as new InventorySystem');
    expect(out).toContain('as add icons lucide');
    expect(out).toContain('as generate feature billing');
    expect(out).toMatch(/Only `as new` decides:.*architecture.*stylesheet.*package manager/s);
    expect(out).toContain('as <command> --help');
  });

  it('documents every flag and example of `new`', async () => {
    const fake = createFakeIo();
    await run(['new', '--help'], fake.io);
    const out = fake.out();
    for (const flag of ['--architecture', '--routing', '--style', '--tailwind', '--rendering']) {
      expect(out).toContain(flag);
    }
    expect(out).toContain('(css, tailwind, scss, sass, less)');
    expect(out).toContain('--defaults');
    expect(out).toContain('Examples:');
    expect(out).toContain('as new Shop --defaults');
    expect(out).toContain('Recommended');
  });

  it('documents `add` with its capabilities, flags and examples', async () => {
    const fake = createFakeIo();
    expect(await run(['add', '--help'], fake.io)).toBe(0);
    const out = fake.out();
    expect(out).toContain('Usage: as add <capability> [value]');
    for (const capability of ['icons', 'components', 'routing', 'rendering']) {
      expect(out).toMatch(new RegExp(`^ {2}${capability} `, 'm'));
    }
    expect(out).toContain('--dry-run');
    expect(out).toContain('--no-install');
    expect(out).toContain('as add routing starter');
  });

  it('documents `generate` with its kinds, flags and examples', async () => {
    const fake = createFakeIo();
    expect(await run(['generate', '--help'], fake.io)).toBe(0);
    const out = fake.out();
    expect(out).toContain('Usage: as generate');
    expect(out).toMatch(/^ {2}feature /m);
    expect(out).toMatch(/^ {2}component /m);
    expect(out).toContain('--feature <name>');
    expect(out).toContain('--shared');
    expect(out).toContain('as generate component invoice-card --shared');
  });

  it('documents `config`', async () => {
    const fake = createFakeIo();
    expect(await run(['config', '--help'], fake.io)).toBe(0);
    const out = fake.out();
    expect(out).toContain('Usage: as config <list|get> [key]');
    expect(out).toContain('read-only');
    expect(out).toContain('as config get architecture');
  });

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
