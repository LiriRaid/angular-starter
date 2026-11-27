import { mkdtemp, readFile, rm, stat, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { run } from '../src/main.js';
import { createFakeIo } from './helpers/fake-io.js';
import { createFakeRunner } from './helpers/fake-runner.js';
import { createStarterProject } from './helpers/starter-project.js';

let cwd: string;

beforeEach(async () => {
  cwd = await mkdtemp(join(tmpdir(), 'sa-add-tooling-'));
});

afterEach(async () => {
  await rm(cwd, { recursive: true, force: true });
});

const exists = (path: string): Promise<boolean> =>
  stat(path).then(
    () => true,
    () => false,
  );

async function add(project: string, args: string[]) {
  const fake = createFakeIo({ cwd: project });
  const runner = createFakeRunner();
  const code = await run(['add', 'tooling', ...args], fake.io, { run: runner.run });
  return { code, out: fake.out(), err: fake.err(), calls: runner.calls };
}

const manifestOf = async (project: string) =>
  JSON.parse(await readFile(join(project, 'package.json'), 'utf8'));

/** A project made before the tooling existed: no ESLint configuration, packages or lint scripts. */
async function withoutTooling(project: string): Promise<void> {
  const manifest = await manifestOf(project);
  for (const name of ['eslint', '@eslint/js', 'typescript-eslint', 'angular-eslint']) {
    delete manifest.devDependencies?.[name];
  }
  for (const name of ['lint', 'lint:fix', 'format', 'format:check'])
    delete manifest.scripts?.[name];
  await writeFile(join(project, 'package.json'), `${JSON.stringify(manifest, null, 2)}\n`);
  await rm(join(project, 'eslint.config.mjs'), { force: true });
}

describe('sa add tooling', () => {
  it('lists tooling among the capabilities it can add', async () => {
    const project = await createStarterProject(cwd);
    const help = createFakeIo({ cwd: project });
    await run(['add', '--help'], help.io, { run: createFakeRunner().run });
    expect(help.out()).toContain('tooling');
    expect(help.out()).toContain('sa add tooling');
  });

  it('adds ESLint, its packages and the lint and format scripts, then installs', async () => {
    const project = await createStarterProject(cwd);
    await withoutTooling(project);
    const result = await add(project, []);

    expect(result.code, result.err).toBe(0);
    expect(await exists(join(project, 'eslint.config.mjs'))).toBe(true);
    const manifest = await manifestOf(project);
    expect(manifest.devDependencies['eslint']).toBeDefined();
    expect(manifest.scripts['lint']).toContain('eslint');
    expect(manifest.scripts['format:check']).toContain('prettier --check');
    expect(result.out).toContain('Lint and format added');
    // The README of the project lists the commands it has now.
    expect(await readFile(join(project, 'README.md'), 'utf8')).toContain('format:check');
    expect(result.calls.some((call) => call.args[0] === 'install')).toBe(true);
  });

  it('does not install with --no-install', async () => {
    const project = await createStarterProject(cwd);
    await withoutTooling(project);
    const result = await add(project, ['--no-install']);

    expect(result.code, result.err).toBe(0);
    expect(result.calls.some((call) => call.args[0] === 'install')).toBe(false);
  });

  it('shows the steps and changes nothing with --dry-run', async () => {
    const project = await createStarterProject(cwd);
    await withoutTooling(project);
    const result = await add(project, ['--dry-run']);

    expect(result.code, result.err).toBe(0);
    expect(result.out).toContain('Dry run');
    expect(result.out).toContain('ESLint');
    expect(await exists(join(project, 'eslint.config.mjs'))).toBe(false);
    expect((await manifestOf(project)).scripts['lint']).toBeUndefined();
  });

  it('refuses when the project has everything already', async () => {
    const project = await createStarterProject(cwd);
    const result = await add(project, []);

    expect(result.code).toBe(2);
    expect(result.err).toContain('already in this project');
  });

  it('keeps the ESLint setup of the developer and adds the format scripts', async () => {
    const project = await createStarterProject(cwd);
    await withoutTooling(project);
    await writeFile(join(project, 'eslint.config.js'), '// own\n');
    const result = await add(project, ['--no-install']);

    expect(result.code, result.err).toBe(0);
    expect(result.out).toContain('Kept your ESLint setup (eslint.config.js)');
    expect(await readFile(join(project, 'eslint.config.js'), 'utf8')).toBe('// own\n');
    expect(await exists(join(project, 'eslint.config.mjs'))).toBe(false);
    const manifest = await manifestOf(project);
    expect(manifest.scripts['format']).toBeDefined();
    expect(manifest.scripts['lint']).toBeUndefined();
  });
});
