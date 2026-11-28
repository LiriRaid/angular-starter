import { existsSync } from 'node:fs';
import { mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { basename, join } from 'node:path';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { ANGULAR_CLI_VERSION } from '../src/compat.js';
import { run } from '../src/main.js';
import { findProject } from '../src/project/find.js';
import { createFakeIo } from './helpers/fake-io.js';

let root: string;

beforeEach(async () => {
  root = await mkdtemp(join(tmpdir(), 'sa-init-'));
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

const CONFIG = 'starter-angular.config.json';

async function init(cwd: string, ...flags: string[]) {
  const fake = createFakeIo({ cwd });
  const code = await run(['init', ...flags], fake.io);
  return { code, out: fake.out(), err: fake.err() };
}

describe('sa init', () => {
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

  it('makes the project one that sa add and sa generate recognise', async () => {
    await init(root);
    const project = await findProject(root);
    expect(project.options.architecture).toBe('angular-default');
    expect(project.name).toBe(basename(root));
  });

  it('shows what it assumed', async () => {
    await writeFile(
      join(root, 'angular.json'),
      JSON.stringify({ projects: { shop: { prefix: 'sa' } } }),
    );
    const { out } = await init(root);
    expect(out).toContain('"sa" is reserved');
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
    // What it found, and the one file it would write, drawn like the other commands do.
    expect(out).toContain(`+ ${CONFIG}`);
    expect(out).toContain('Would create 1 file.');
    expect(existsSync(join(root, CONFIG))).toBe(false);
  });

  it('stops in a folder that is not an Angular workspace', async () => {
    const empty = await mkdtemp(join(tmpdir(), 'sa-init-empty-'));
    try {
      const { code, err } = await init(empty);
      expect(code).toBe(2);
      expect(err).toContain('angular.json');
    } finally {
      await rm(empty, { recursive: true, force: true });
    }
  });
});

describe('a project that was not made by sa new', () => {
  it('is told to run sa init by the commands that need the configuration', async () => {
    const fake = createFakeIo({ cwd: root });
    expect(await run(['add', 'icons', 'lucide'], fake.io)).toBe(2);
    expect(fake.err()).toContain('sa init');
  });
});

describe('sa init --force on a project that has a configuration', () => {
  it('keeps what sa new recorded and detection can only assume: layout, SSR purpose, git, install', async () => {
    await mkdir(join(root, 'src/app/features/app-shell/layout/main'), { recursive: true });
    await writeFile(join(root, 'src/app/features/app-shell/layout/main/main.ts'), '');
    await writeFile(
      join(root, CONFIG),
      JSON.stringify({
        schemaVersion: 1,
        options: { layout: 'compact-joined', ssrPurpose: 'landing', git: false, install: false },
      }),
    );
    const { code } = await init(root, '--force');
    expect(code).toBe(0);
    const options = JSON.parse(await readFile(join(root, CONFIG), 'utf8')).options;
    expect(options).toMatchObject({
      appShell: 'starter',
      layout: 'compact-joined',
      git: false,
      install: false,
    });
  });

  it('does not fail on a package.json that is not valid JSON', async () => {
    await writeFile(join(root, 'package.json'), '{ "name": "shop", }');
    const { code, err } = await init(root);
    expect(code, err).toBe(0);
    const config = JSON.parse(await readFile(join(root, CONFIG), 'utf8'));
    expect(config.generator.angularCli).toBe(ANGULAR_CLI_VERSION);
  });
});
