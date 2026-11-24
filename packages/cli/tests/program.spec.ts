import { describe, expect, it } from 'vitest';
import { ANGULAR_CLI_VERSION } from '../src/compat.js';
import { run } from '../src/main.js';
import { CLI_VERSION } from '../src/version.js';
import { createFakeIo } from './helpers/fake-io.js';

const COMMANDS = [
  'new',
  'init',
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

describe('sa (program)', () => {
  it('prints help when called without arguments', async () => {
    const fake = createFakeIo();
    expect(await run([], fake.io)).toBe(0);
    const out = fake.out();
    expect(out).toContain('Starter Angular CLI');
    expect(out).toContain('Usage: sa [command] [options]');
    expect(out).toContain('Commands:');
    for (const command of COMMANDS) expect(out).toMatch(new RegExp(`^ {2}sa ${command}\\b`, 'm'));
    expect(out).toContain('-h, --help');
    expect(out).toContain('-v, --version');
  });

  it.each([['--help'], ['-h']])('prints help with %s', async (flag) => {
    const fake = createFakeIo();
    expect(await run([flag], fake.io)).toBe(0);
    expect(fake.out()).toContain('Usage: sa [command] [options]');
  });

  it.each([['--version'], ['-v'], ['version']])(
    'prints the version of the CLI and of the Angular CLI it runs with %s',
    async (flag) => {
      const fake = createFakeIo();
      expect(await run([flag], fake.io)).toBe(0);
      expect(fake.out()).toBe(
        `starter-angular ${CLI_VERSION}\nAngular CLI ${ANGULAR_CLI_VERSION}\n`,
      );
    },
  );

  it('shows command help', async () => {
    const fake = createFakeIo();
    expect(await run(['list', '--help'], fake.io)).toBe(0);
    expect(fake.out()).toContain('Usage: sa list');
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

  it('lists the commands, then the options, in the root help', async () => {
    const fake = createFakeIo();
    await run(['--help'], fake.io);
    const out = fake.out();
    const positions = [
      'Usage: sa [command] [options]',
      'Commands:',
      '  sa new ',
      '  sa init',
      '  sa add ',
      '  sa generate',
      '  sa list',
      '  sa config',
      '  sa doctor',
      '  sa update',
      'Options:',
      '-v, --version',
      '-h, --help',
    ].map((text) => out.indexOf(text));
    expect(
      positions.every((position) => position >= 0),
      out,
    ).toBe(true);
    expect(positions).toEqual([...positions].sort((a, b) => a - b));
  });

  it('keeps the root help short: one line per command and option, no examples or notes', async () => {
    const fake = createFakeIo();
    await run(['--help'], fake.io);
    const out = fake.out();
    expect(out).not.toContain('Examples:');
    expect(out).not.toContain('Only `sa new` decides');
    const lines = out.trim().split('\n');
    expect(lines.length).toBeLessThanOrEqual(24);
    for (const line of lines) expect(line.length, line).toBeLessThanOrEqual(120);
  });

  it('describes each command in a sentence, like ng does', async () => {
    const fake = createFakeIo();
    await run(['--help'], fake.io);
    for (const line of fake
      .out()
      .split('\n')
      .filter((text) => /^ {2}as \w/.test(text))) {
      expect(line, line).toMatch(/ {2}[A-Z][^.]{30,}\.$/);
    }
  });

  it('ends the root help with where to read more', async () => {
    const fake = createFakeIo();
    await run(['--help'], fake.io);
    expect(fake.out().trim().split('\n').at(-1)).toBe(
      'For more information, see https://github.com/LiriRaid/starter-angular.',
    );
  });

  it('paints the headings of the root help when the terminal has colors', async () => {
    const colored = createFakeIo({ color: true });
    await run(['--help'], colored.io);
    expect(colored.out()).toContain('\u001b[36mCommands:\u001b[39m');
    expect(colored.out()).toContain('\u001b[36mOptions:\u001b[39m');
    const plain = createFakeIo();
    await run(['--help'], plain.io);
    expect(plain.out()).not.toContain('\u001b[');
  });

  it('leaves the examples to the help of each command', async () => {
    for (const command of ['new', 'add', 'generate', 'init', 'list', 'config']) {
      const fake = createFakeIo();
      await run([command, '--help'], fake.io);
      expect(fake.out(), command).toContain('Examples:');
    }
  });

  it('documents every flag and example of `new`', async () => {
    const fake = createFakeIo();
    await run(['new', '--help'], fake.io);
    const out = fake.out();
    for (const flag of [
      '--architecture',
      '--routing',
      '--style',
      '--tailwind',
      '--rendering',
      '--ssr-purpose',
      '--app-shell',
      '--layout',
      '--presence',
      '--ui-system',
    ]) {
      expect(out).toContain(flag);
    }
    // Only what can be generated is listed as a value.
    expect(out).toContain('Layout of the app shell (none, floating-wide)');
    expect(out).toContain('What the Starter SSR is for (none,');
    expect(out).toContain('(css, tailwind, scss, sass, less)');
    expect(out).toContain('--defaults');
    expect(out).toContain('Examples:');
    expect(out).toContain('sa new Shop --defaults');
    expect(out).toContain('Recommended');
  });

  it('documents `add` with its capabilities, flags and examples', async () => {
    const fake = createFakeIo();
    expect(await run(['add', '--help'], fake.io)).toBe(0);
    const out = fake.out();
    expect(out).toContain('Usage: sa add <capability> [value]');
    for (const capability of [
      'icons',
      'components',
      'routing',
      'app-shell',
      'presence',
      'rendering',
    ]) {
      expect(out).toMatch(new RegExp(`^ {2}${capability} `, 'm'));
    }
    expect(out).toContain('--dry-run');
    expect(out).toContain('--no-install');
    expect(out).toContain('sa add routing starter');
    expect(out).toContain('sa add app-shell');
    expect(out).toContain('sa add presence');
    expect(out).toContain('sa add ui-system');
  });

  it('documents `generate` with its kinds, flags and examples', async () => {
    const fake = createFakeIo();
    expect(await run(['generate', '--help'], fake.io)).toBe(0);
    const out = fake.out();
    expect(out).toContain('Usage: sa generate');
    expect(out).toMatch(/^ {2}feature /m);
    expect(out).toMatch(/^ {2}component /m);
    expect(out).toContain('--feature <name>');
    expect(out).toContain('--shared');
    expect(out).toContain('sa generate component invoice-card --shared');
  });

  it('documents `config`', async () => {
    const fake = createFakeIo();
    expect(await run(['config', '--help'], fake.io)).toBe(0);
    const out = fake.out();
    expect(out).toContain('Usage: sa config <list|get> [key]');
    expect(out).toContain('read-only');
    expect(out).toContain('sa config get architecture');
  });

  it('lists available and planned options', async () => {
    const fake = createFakeIo({ columns: 160 });
    expect(await run(['list'], fake.io)).toBe(0);
    const out = fake.out();
    expect(out).toContain('angular-default');
    expect(out).toMatch(/screaming(?!.*planned)/);
    expect(out).toMatch(/modular.*planned/);
  });

  it('explains every option in the list: label, documentation and description', async () => {
    const fake = createFakeIo({ columns: 160 });
    expect(await run(['list', 'style'], fake.io)).toBe(0);
    const out = fake.out();
    expect(out).toContain('Stylesheet formats (style)');
    expect(out).toMatch(/^ {2}tailwind .* Tailwind CSS \(Recommended\)/m);
    expect(out).toContain('https://tailwindcss.com');
    expect(out).toContain('Utility-first');
    expect(out).toMatch(/^ {2}css .* CSS/m);
  });

  it('lists the application shell options with the link to their decision', async () => {
    const fake = createFakeIo({ columns: 160 });
    expect(await run(['list', 'appShell'], fake.io)).toBe(0);
    const out = fake.out();
    expect(out).toContain('Application shells (appShell)');
    expect(out).toMatch(/^ {2}starter .* Starter Angular App Shell/m);
    expect(out).toContain('0008-app-shell.md');
    expect(out).not.toMatch(/App Shell \(Recommended\)/);
  });

  it('lists the layout modes of the shell: the one that exists and the ones under construction', async () => {
    const fake = createFakeIo({ columns: 160 });
    expect(await run(['list', 'layout'], fake.io)).toBe(0);
    const out = fake.out();
    expect(out).toContain('Layout modes of the application shell (layout)');
    expect(out).toMatch(/^ {2}floating-wide .* Floating \(wide\) \(Recommended\)/m);
    expect(out).toMatch(/^ {2}compact-joined +Compact sidebar \(joined\) \(planned\)/m);
    expect(out).toMatch(/^ {2}transparent-floating +Transparent \(floating\) \(planned\)/m);
  });

  it('lists what the Starter SSR can be for', async () => {
    const fake = createFakeIo({ columns: 160 });
    expect(await run(['list', 'ssrPurpose'], fake.io)).toBe(0);
    const out = fake.out();
    expect(out).toContain('Purposes of the Starter SSR (ssrPurpose)');
    expect(out).toMatch(/^ {2}backoffice .* Backoffice(?! \(planned\))/m);
    expect(out).toMatch(/^ {2}landing +Landing page \(planned\)/m);
    expect(out).toMatch(/^ {2}ecommerce +Ecommerce \(planned\)/m);
  });

  it('lists the UI System', async () => {
    const fake = createFakeIo({ columns: 160 });
    expect(await run(['list', 'uiSystem'], fake.io)).toBe(0);
    expect(fake.out()).toContain('UI Systems (uiSystem)');
    expect(fake.out()).toMatch(/^ {2}starter .* Starter Angular UI System/m);
  });

  it('lists the presence options with the link to their decision', async () => {
    const fake = createFakeIo({ columns: 160 });
    expect(await run(['list', 'presence'], fake.io)).toBe(0);
    const out = fake.out();
    expect(out).toContain('Presence (presence)');
    expect(out).toMatch(/^ {2}starter .* Starter Angular Presence/m);
    expect(out).toContain('0009-presence-documentation-and-welcome-home.md');
    expect(out).not.toMatch(/Presence \(Recommended\)/);
  });

  it('prints environment information', async () => {
    const fake = createFakeIo({ columns: 160 });
    expect(await run(['info'], fake.io)).toBe(0);
    expect(fake.out()).toContain(process.versions.node);
    expect(fake.out()).toContain(ANGULAR_CLI_VERSION);
  });
});
