import { mkdir, mkdtemp, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { run } from '../src/main.js';
import { createFakeIo } from './helpers/fake-io.js';
import { createFakeRunner, type FakeRunnerOptions } from './helpers/fake-runner.js';

let root: string;

beforeEach(async () => {
  root = await mkdtemp(join(tmpdir(), 'sa-test-command-'));
});

afterEach(async () => {
  await rm(root, { recursive: true, force: true });
});

/** An Angular project the CLI did not create: its workspace file, a lockfile and installed dependencies. */
async function angularProject(lockfile = 'pnpm-lock.yaml', installed = true): Promise<void> {
  await writeFile(join(root, 'angular.json'), '{}');
  await writeFile(join(root, 'package.json'), '{ "name": "demo" }');
  if (lockfile) await writeFile(join(root, lockfile), '');
  if (installed) await mkdir(join(root, 'node_modules'));
}

async function sa(args: string[], cwd = root, runner: FakeRunnerOptions = {}) {
  const fake = createFakeIo({ cwd });
  const fakeRunner = createFakeRunner(runner);
  const code = await run(args, fake.io, { run: fakeRunner.run });
  return { code, out: fake.out(), err: fake.err(), calls: fakeRunner.calls };
}

describe('sa test', () => {
  it('runs ng test of the project through pnpm', async () => {
    await angularProject('pnpm-lock.yaml');
    const result = await sa(['test']);

    expect(result.code, result.err).toBe(0);
    expect(result.calls).toEqual([{ command: 'pnpm', args: ['exec', 'ng', 'test'], cwd: root }]);
  });

  it('runs it through npm and yarn too, each the way it runs a local binary', async () => {
    await angularProject('package-lock.json');
    expect((await sa(['test'])).calls[0]).toEqual({
      command: 'npm',
      args: ['exec', '--', 'ng', 'test'],
      cwd: root,
    });

    await rm(join(root, 'package-lock.json'));
    await writeFile(join(root, 'yarn.lock'), '');
    expect((await sa(['test'])).calls[0]).toEqual({
      command: 'yarn',
      args: ['ng', 'test'],
      cwd: root,
    });
  });

  it('hands every argument and option to ng test, in the order they were typed', async () => {
    await angularProject();
    const result = await sa([
      'test',
      '--watch=false',
      '--include',
      'src/app/**/*.spec.ts',
      '--coverage',
    ]);

    expect(result.code, result.err).toBe(0);
    expect(result.calls[0]?.args).toEqual([
      'exec',
      'ng',
      'test',
      '--watch=false',
      '--include',
      'src/app/**/*.spec.ts',
      '--coverage',
    ]);
  });

  it('finds the project from any of its folders', async () => {
    await angularProject();
    await mkdir(join(root, 'src', 'app'), { recursive: true });
    const result = await sa(['test'], join(root, 'src', 'app'));

    expect(result.code, result.err).toBe(0);
    expect(result.calls[0]?.cwd).toBe(root);
  });

  it('does not need the project to have been created or prepared by Starter Angular', async () => {
    await angularProject();
    const result = await sa(['test']);

    expect(result.code, result.err).toBe(0);
  });

  it('needs an Angular workspace', async () => {
    const result = await sa(['test']);

    expect(result.code).toBe(2);
    expect(result.err).toContain('angular.json was not found');
    expect(result.calls).toEqual([]);
  });

  it('says to install the dependencies when they are not there', async () => {
    await angularProject('pnpm-lock.yaml', false);
    const result = await sa(['test']);

    expect(result.code).toBe(2);
    expect(result.err).toContain('pnpm install');
    expect(result.calls).toEqual([]);
  });

  it('runs in a Yarn Plug-n-Play project, which has no node_modules folder', async () => {
    await angularProject('yarn.lock', false);
    await writeFile(join(root, '.pnp.cjs'), '');
    const result = await sa(['test']);

    expect(result.code, result.err).toBe(0);
    expect(result.calls[0]?.command).toBe('yarn');
  });

  it('exits with the code ng test exits with, so a failing test fails a script or a pipeline', async () => {
    await angularProject();
    const failure = Object.assign(new Error('Command failed'), { exitCode: 3 });
    const result = await sa(['test'], root, { failOn: () => failure });

    expect(result.code).toBe(3);
    expect(result.err).toContain('ng test');
  });

  it('reports a runner that could not start at all as a failure', async () => {
    await angularProject();
    const result = await sa(['test'], root, { failOn: () => new Error('spawn pnpm ENOENT') });

    expect(result.code).toBe(1);
    expect(result.err).toContain('spawn pnpm ENOENT');
  });

  it('is listed in the help of the CLI, with the command it runs', async () => {
    const result = await sa(['--help']);

    expect(result.out).toContain('sa test');
    expect(result.out).toContain('ng test');
  });
});
