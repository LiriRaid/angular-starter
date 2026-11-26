import { mkdir, mkdtemp, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { run } from '../src/main.js';
import { createFakeIo } from './helpers/fake-io.js';
import { createFakeRunner, type FakeRunnerOptions } from './helpers/fake-runner.js';

let root: string;

beforeEach(async () => {
  root = await mkdtemp(join(tmpdir(), 'sa-lint-format-'));
});

afterEach(async () => {
  await rm(root, { recursive: true, force: true });
});

const SCRIPTS = {
  lint: 'eslint "src/**/*.{ts,html}"',
  'lint:fix': 'eslint "src/**/*.{ts,html}" --fix',
  format: 'prettier --write "src/**/*.{ts,html,css}"',
  'format:check': 'prettier --check "src/**/*.{ts,html,css}"',
};

/** An Angular project the CLI did not create: workspace file, manifest with scripts, lockfile, installed packages. */
async function angularProject(
  lockfile = 'pnpm-lock.yaml',
  scripts: Record<string, string> = SCRIPTS,
  installed = true,
): Promise<void> {
  await writeFile(join(root, 'angular.json'), '{}');
  await writeFile(join(root, 'package.json'), JSON.stringify({ name: 'demo', scripts }));
  if (lockfile) await writeFile(join(root, lockfile), '');
  if (installed) await mkdir(join(root, 'node_modules'));
}

async function sa(args: string[], cwd = root, runner: FakeRunnerOptions = {}) {
  const fake = createFakeIo({ cwd });
  const fakeRunner = createFakeRunner(runner);
  const code = await run(args, fake.io, { run: fakeRunner.run });
  return { code, out: fake.out(), err: fake.err(), calls: fakeRunner.calls };
}

describe.each([
  ['lint', 'lint', 'lint:fix', '--fix'],
  ['format', 'format', 'format:check', '--check'],
] as const)('sa %s', (word, script, variant, flag) => {
  it(`runs the ${script} script of the project through its package manager`, async () => {
    await angularProject('pnpm-lock.yaml');
    const result = await sa([word]);
    expect(result.code, result.err).toBe(0);
    expect(result.calls).toEqual([{ command: 'pnpm', args: ['run', script], cwd: root }]);

    await rm(join(root, 'pnpm-lock.yaml'));
    await writeFile(join(root, 'package-lock.json'), '');
    expect((await sa([word])).calls[0]).toEqual({
      command: 'npm',
      args: ['run', script],
      cwd: root,
    });

    await rm(join(root, 'package-lock.json'));
    await writeFile(join(root, 'yarn.lock'), '');
    expect((await sa([word])).calls[0]).toEqual({
      command: 'yarn',
      args: ['run', script],
      cwd: root,
    });
  });

  it(`runs the ${variant} script when it is given ${flag}, which is not handed over`, async () => {
    await angularProject();
    const result = await sa([word, flag]);

    expect(result.code, result.err).toBe(0);
    expect(result.calls[0]?.args).toEqual(['run', variant]);
  });

  it('hands every other argument to the script, the way each package manager takes them', async () => {
    await angularProject('pnpm-lock.yaml');
    expect((await sa([word, 'src/app/app.ts'])).calls[0]?.args).toEqual([
      'run',
      script,
      'src/app/app.ts',
    ]);
    expect((await sa([word, flag, 'src/app/app.ts'])).calls[0]?.args).toEqual([
      'run',
      variant,
      'src/app/app.ts',
    ]);

    await rm(join(root, 'pnpm-lock.yaml'));
    await writeFile(join(root, 'package-lock.json'), '');
    expect((await sa([word, 'src/app/app.ts'])).calls[0]?.args).toEqual([
      'run',
      script,
      '--',
      'src/app/app.ts',
    ]);
  });

  it('finds the project from any of its folders and does not need it to be made by Starter Angular', async () => {
    await angularProject();
    await mkdir(join(root, 'src', 'app'), { recursive: true });
    const result = await sa([word], join(root, 'src', 'app'));

    expect(result.code, result.err).toBe(0);
    expect(result.calls[0]?.cwd).toBe(root);
  });

  it('names the script and the command that adds it when the project does not have it', async () => {
    await angularProject('pnpm-lock.yaml', { build: 'ng build' });
    const result = await sa([word, flag]);

    expect(result.code).toBe(2);
    expect(result.err).toContain(`"${variant}"`);
    expect(result.err).toContain('sa add tooling');
    expect(result.calls).toEqual([]);
  });

  it('needs an Angular workspace', async () => {
    const result = await sa([word]);

    expect(result.code).toBe(2);
    expect(result.err).toContain('angular.json was not found');
  });

  it('says to install the dependencies when they are not there', async () => {
    await angularProject('pnpm-lock.yaml', SCRIPTS, false);
    const result = await sa([word]);

    expect(result.code).toBe(2);
    expect(result.err).toContain('pnpm install');
    expect(result.calls).toEqual([]);
  });

  it('exits with the code of the script, so a pipeline fails when the code is not clean', async () => {
    await angularProject();
    const failure = Object.assign(new Error('Command failed'), { exitCode: 1 });
    const result = await sa([word], root, { failOn: () => failure });

    expect(result.code).toBe(1);
    expect(result.err).toContain(`"${script}"`);
  });

  it('is listed in the help of the CLI', async () => {
    const result = await sa(['--help']);

    expect(result.out).toContain(`sa ${word}`);
  });
});
