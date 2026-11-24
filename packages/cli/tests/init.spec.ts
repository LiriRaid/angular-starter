import { existsSync } from 'node:fs';
import { mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { ANGULAR_CLI_VERSION } from '../src/compat.js';
import { run } from '../src/main.js';
import { findProject } from '../src/project/find.js';
import { createFakeIo } from './helpers/fake-io.js';

let root: string;

beforeEach(async () => {
  root = await mkdtemp(join(tmpdir(), 'as-init-'));
  await mkdir(join(root, 'src/app'), { recursive: true });
  await writeFile(
    join(root, 'angular.json'),
    JSON.stringify({ projects: { shop: { prefix: 'shop' } } }),
  );
  await writeFile(
    join(root, 'package.json'),
    JSON.stringify({
      name: 'shop',
      dependencies: { '@angular/core': '^22.0.0' },
      devDependencies: { '@angular/cli': '^22.1.0', tailwindcss: '^4.0.0' },
    }),
  );
  await writeFile(join(root, 'pnpm-lock.yaml'), '');
});

afterEach(async () => {
  await rm(root, { recursive: true, force: true });
});

const CONFIG = 'angular-starter.config.json';

async function init(cwd: string, ...flags: string[]) {
  const fake = createFakeIo({ cwd });
  const code = await run(['init', ...flags], fake.io);
  return { code, out: fake.out(), err: fake.err() };
}

describe('as init', () => {
  it('writes the configuration of the project from what it already has, and nothing else', async () => {
    const { code, out } = await init(root);
    expect(code).toBe(0);
    const config = JSON.parse(await readFile(join(root, CONFIG), 'utf8'));
    expect(config.schemaVersion).toBe(1);
    expect(config.generator.angularCli).toBe('22.1.0');
    expect(config.options).toMatchObject({
      architecture: 'angular-default',
      tailwind: true,
      packageManager: 'pnpm',
      prefix: 'shop',
    });
    expect(out).toContain(CONFIG);
    expect(out).toMatch(/tailwind +true/);
  });

  it('records the Angular CLI version tested by this release when the project has none', async () => {
    await writeFile(join(root, 'package.json'), JSON.stringify({ name: 'shop' }));
    await init(root);
    const config = JSON.parse(await readFile(join(root, CONFIG), 'utf8'));
    expect(config.generator.angularCli).toBe(ANGULAR_CLI_VERSION);
  });

  it('works from a folder inside the workspace', async () => {
    const { code } = await init(join(root, 'src/app'));
    expect(code).toBe(0);
    expect(existsSync(join(root, CONFIG))).toBe(true);
  });

  it('makes the project one that as add and as generate recognise', async () => {
    await init(root);
    const project = await findProject(root);
    expect(project.options.architecture).toBe('angular-default');
    expect(project.name).toBe('shop');
  });

  it('shows what it assumed', async () => {
    await writeFile(
      join(root, 'angular.json'),
      JSON.stringify({ projects: { shop: { prefix: 'as' } } }),
    );
    const { out } = await init(root);
    expect(out).toContain('"as" is reserved');
  });

  it('does not overwrite a configuration unless asked with --force', async () => {
    await writeFile(join(root, CONFIG), '{"keep":true}');
    const refused = await init(root);
    expect(refused.code).toBe(2);
    expect(refused.err).toContain('already');
    expect(await readFile(join(root, CONFIG), 'utf8')).toBe('{"keep":true}');

    const forced = await init(root, '--force');
    expect(forced.code).toBe(0);
    expect(JSON.parse(await readFile(join(root, CONFIG), 'utf8')).options).toBeDefined();
  });

  it('only prints with --dry-run', async () => {
    const { code, out } = await init(root, '--dry-run');
    expect(code).toBe(0);
    expect(out).toContain('Dry run');
    expect(existsSync(join(root, CONFIG))).toBe(false);
  });

  it('stops in a folder that is not an Angular workspace', async () => {
    const empty = await mkdtemp(join(tmpdir(), 'as-init-empty-'));
    try {
      const { code, err } = await init(empty);
      expect(code).toBe(2);
      expect(err).toContain('angular.json');
    } finally {
      await rm(empty, { recursive: true, force: true });
    }
  });
});

describe('a project that was not made by as new', () => {
  it('is told to run as init by the commands that need the configuration', async () => {
    const fake = createFakeIo({ cwd: root });
    expect(await run(['add', 'icons', 'lucide'], fake.io)).toBe(2);
    expect(fake.err()).toContain('as init');
  });
});
