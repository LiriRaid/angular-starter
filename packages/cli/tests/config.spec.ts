import { mkdtemp, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { run } from '../src/main.js';
import { createFakeIo } from './helpers/fake-io.js';
import { createStarterProject } from './helpers/starter-project.js';

let cwd: string;
let project: string;

beforeEach(async () => {
  cwd = await mkdtemp(join(tmpdir(), 'as-config-'));
  project = await createStarterProject(cwd, ['--icons', 'none']);
});

afterEach(async () => {
  await rm(cwd, { recursive: true, force: true });
});

describe('as config', () => {
  it('lists every option of the project', async () => {
    const fake = createFakeIo({ cwd: project });
    expect(await run(['config', 'list'], fake.io)).toBe(0);
    const out = fake.out();
    expect(out).toMatch(/^ {2}architecture +screaming$/m);
    expect(out).toMatch(/^ {2}icons +none$/m);
    expect(out).toMatch(/^ {2}tailwind +true$/m);
  });

  it('prints one value, ready for a script', async () => {
    const fake = createFakeIo({ cwd: project });
    expect(await run(['config', 'get', 'routing'], fake.io)).toBe(0);
    expect(fake.out()).toBe('starter\n');
  });

  it('finds the project from a nested folder', async () => {
    const fake = createFakeIo({ cwd: join(project, 'src', 'app') });
    expect(await run(['config', 'get', 'prefix'], fake.io)).toBe(0);
    expect(fake.out()).toBe('app\n');
  });

  it('fails on an unknown key and names the valid ones', async () => {
    const fake = createFakeIo({ cwd: project });
    expect(await run(['config', 'get', 'colour'], fake.io)).toBe(2);
    expect(fake.err()).toContain('Unknown option "colour"');
    expect(fake.err()).toContain('architecture');
  });

  it('needs a key to get', async () => {
    const fake = createFakeIo({ cwd: project });
    expect(await run(['config', 'get'], fake.io)).toBe(2);
    expect(fake.err()).toContain('Usage: as config get <key>');
  });

  it('is read-only and says which command decides the values', async () => {
    const fake = createFakeIo({ cwd: project });
    expect(await run(['config', 'set', 'prefix', 'x'], fake.io)).toBe(2);
    expect(fake.err()).toContain('read-only');
    expect(fake.err()).toContain('as new');
  });

  it('fails outside a project', async () => {
    const fake = createFakeIo({ cwd });
    expect(await run(['config', 'list'], fake.io)).toBe(2);
    expect(fake.err()).toContain('angular-starter.config.json');
  });

  it('does not accept a configuration file that is not valid', async () => {
    await writeFile(join(project, 'angular-starter.config.json'), '{ "options": { "style": 1 } }');
    const fake = createFakeIo({ cwd: project });
    expect(await run(['config', 'list'], fake.io)).toBe(2);
    expect(fake.err()).toContain('angular-starter.config.json');
  });
});
