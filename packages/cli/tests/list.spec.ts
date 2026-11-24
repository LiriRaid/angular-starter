import { describe, expect, it } from 'vitest';
import { CAPABILITIES, CATEGORIES } from '../src/config/capabilities.js';
import { run } from '../src/main.js';
import { createFakeIo } from './helpers/fake-io.js';

async function list(columns: number | undefined, ...args: string[]): Promise<string> {
  const fake = createFakeIo({ columns });
  expect(await run(['list', ...args], fake.io)).toBe(0);
  return fake.out();
}

const wide = (...args: string[]): Promise<string> => list(160, ...args);

/** The line of an option: it starts with its id and holds its name. */
function optionLine(out: string, id: string, label: string): string | undefined {
  return out
    .split('\n')
    .find((line) => new RegExp(`^ {2}${id}( |$)`).test(line) && line.includes(label));
}

describe('as list: the command of each option', () => {
  it('puts the command to add an option and the one to ask for it in as new on their own lines', async () => {
    const out = await wide('components');
    expect(out).toMatch(/^ {2}recommended +as add components recommended +/m);
    expect(out).toMatch(/^ +as new --components recommended( |$)/m);
    expect(out).toMatch(/^ {2}all +as add components all( |$)/m);
  });

  it('shows no add command for what a project that does not use the capability already is', async () => {
    const out = await wide('components');
    expect(out).not.toContain('as add components none');
    expect(out).toMatch(/as new --components none/);
  });

  it('shows only the new command for what as add cannot change', async () => {
    const out = await wide('style');
    expect(out).toContain('as new --style scss');
    expect(out).not.toContain('as add style');
  });

  it('writes the flags of the categories that have a compound name', async () => {
    expect(await wide('uiSystem')).toContain('as new --ui-system starter');
    expect(await wide('appShell')).toContain('as add app-shell starter');
    expect(await wide('packageManager')).toContain('as new --package-manager pnpm');
  });

  it('says how to give a project an architecture', async () => {
    expect(await wide('architecture')).toContain('as add architecture screaming');
  });

  it('gives no command to an option that is only planned, and marks it', async () => {
    const out = await wide('architecture');
    const line = optionLine(out, 'modular', 'Modular Architecture');
    expect(line).toBeDefined();
    expect(line).toContain('(planned)');
    expect(out).not.toContain('as new --architecture modular');
  });

  it('keeps no Add: or New: labels: the table carries the commands', async () => {
    const out = await wide();
    expect(out).not.toMatch(/\b(Add|New): as /);
  });

  it('accepts a kebab-case name of the category', async () => {
    for (const [kebab, camel] of [
      ['app-shell', 'appShell'],
      ['ui-system', 'uiSystem'],
      ['ssr-purpose', 'ssrPurpose'],
      ['package-manager', 'packageManager'],
    ] as const) {
      expect(await wide(kebab)).toBe(await wide(camel));
    }
  });

  it('still rejects a category that does not exist and names the valid ones', async () => {
    const fake = createFakeIo();
    expect(await run(['list', 'nope'], fake.io)).toBe(2);
    expect(fake.err()).toContain('Unknown category "nope"');
  });
});

describe('as list: one table for the whole listing', () => {
  it('paints the headers of the columns when the terminal has colors', async () => {
    const fake = createFakeIo({ columns: 160, color: true });
    expect(await run(['list', 'rendering'], fake.io)).toBe(0);
    expect(fake.out()).toContain('\u001b[36mID');
    expect(fake.out()).toContain('\u001b[36mCommands');
    expect(fake.out()).toContain('\u001b[36mOption');
  });

  it('names the three columns under the title of each category', async () => {
    const out = await wide('rendering');
    expect(out).toMatch(/^ {2}ID +Commands +Option$/m);
  });

  it('starts the commands in the same column in every category', async () => {
    const out = await wide();
    const starts = out
      .split('\n')
      .filter((line) => /^ {2}(\S+ +)?as (add|new) /.test(line))
      .map((line) => line.indexOf('as '));
    expect(starts.length).toBeGreaterThan(20);
    expect(new Set(starts).size).toBe(1);
  });

  it('starts the name of every option in the column of the Option header, in every category', async () => {
    const out = await wide();
    const column = (out.split('\n').find((line) => /^ {2}ID /.test(line)) ?? '').indexOf('Option');
    expect(column).toBeGreaterThan(0);
    for (const category of CATEGORIES) {
      for (const option of CAPABILITIES[category]) {
        const line = optionLine(out, option.id, option.label);
        expect(line, `${category}: ${option.id}`).toBeDefined();
        expect((line as string).slice(column).startsWith(option.label)).toBe(true);
      }
    }
  });

  it('starts the headers where the cells of their columns start', async () => {
    const out = await wide();
    const headers = out.split('\n').filter((line) => /^ {2}ID +Commands +Option$/.test(line));
    expect(headers).toHaveLength(CATEGORIES.length);
    expect(new Set(headers.map((line) => line.indexOf('Commands'))).size).toBe(1);
    expect(new Set(headers.map((line) => line.indexOf('Option'))).size).toBe(1);
    const commandColumn = headers[0]?.indexOf('Commands');
    const firstCommand = out.split('\n').find((line) => /^ {2}(\S+ +)?as (add|new) /.test(line));
    expect(firstCommand?.indexOf('as ')).toBe(commandColumn);
  });

  it('wraps the description in the third column, under the name, with the link last', async () => {
    const out = await wide('rendering');
    const lines = out.split('\n');
    const scss = CAPABILITIES.rendering.find((option) => option.available);
    expect(scss).toBeDefined();
    const nameLine = lines.findIndex((line) => line.includes(scss?.label ?? '?'));
    const column = (lines[nameLine] ?? '').indexOf(scss?.label ?? '?');
    const next = lines[nameLine + 1] ?? '';
    // Right under the name: a command, if the option has a second one, and then the description.
    expect(next.slice(column).trim().length).toBeGreaterThan(0);
    expect(
      next
        .slice(0, column)
        .replace(/as (add|new) .*/, '')
        .trim(),
    ).toBe('');
    if (scss?.docs) expect(out).toContain(scss.docs);
  });

  it('never makes a line longer than the terminal, except for a link', async () => {
    for (const columns of [100, 120]) {
      const out = await list(columns);
      const longer = out
        .split('\n')
        .filter((line) => line.length > columns && !/https?:\/\/\S+$/.test(line));
      expect(longer, `${columns} columns`).toEqual([]);
    }
  });

  it('uses 100 columns when the output is not a terminal', async () => {
    expect(await list(undefined)).toBe(await list(100));
  });

  it('puts the description on a line below the row when the terminal is narrow', async () => {
    const out = await list(64, 'style');
    const scss = CAPABILITIES.style.find((option) => option.id === 'scss');
    const row = out.split('\n').find((line) => line.includes('as new --style scss'));
    expect(row).toBeDefined();
    expect(row).not.toContain(scss?.label ?? '?');
    expect(row).not.toContain(scss?.description.slice(0, 20) ?? '?');
    // The name and then the description, under the row.
    const lines = out.split('\n');
    const at = lines.indexOf(row as string);
    expect(lines[at + 1]?.trim()).toBe(scss?.label);
    expect(lines[at + 2]).toContain(scss?.description.slice(0, 20));
    const longer = out
      .split('\n')
      .filter((line) => line.length > 64 && !/https?:\/\/\S+$/.test(line));
    expect(longer).toEqual([]);
  });

  it('keeps the same columns in a narrow terminal, for every row', async () => {
    const out = await list(64);
    const starts = out
      .split('\n')
      .filter((line) => /^ {2}(\S+ +)?as (add|new) /.test(line))
      .map((line) => line.indexOf('as '));
    expect(new Set(starts).size).toBe(1);
  });
});
