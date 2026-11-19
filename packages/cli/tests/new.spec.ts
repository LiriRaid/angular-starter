import { mkdir, mkdtemp, readFile, rm, stat } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { ANGULAR_CLI_VERSION } from '../src/compat.js';
import { run } from '../src/main.js';
import { createFakeIo } from './helpers/fake-io.js';
import { createFakePrompter } from './helpers/fake-prompter.js';
import { createFakeRunner } from './helpers/fake-runner.js';

let cwd: string;

beforeEach(async () => {
  cwd = await mkdtemp(join(tmpdir(), 'as-new-'));
});

afterEach(async () => {
  await rm(cwd, { recursive: true, force: true });
});

const exists = (path: string): Promise<boolean> =>
  stat(path).then(
    () => true,
    () => false,
  );

describe('as new (non-interactive)', () => {
  it('requires a project name', async () => {
    const fake = createFakeIo({ cwd });
    expect(await run(['new', '--defaults'], fake.io, { run: createFakeRunner().run })).toBe(2);
    expect(fake.err()).toContain('Project name is required');
  });

  it('rejects an invalid project name before doing anything', async () => {
    const fake = createFakeIo({ cwd });
    const runner = createFakeRunner();
    expect(await run(['new', 'My App', '--defaults'], fake.io, { run: runner.run })).toBe(2);
    expect(runner.calls).toEqual([]);
  });

  it('never overwrites an existing folder', async () => {
    await mkdir(join(cwd, 'my-app'));
    const fake = createFakeIo({ cwd });
    const runner = createFakeRunner();
    expect(await run(['new', 'my-app', '--defaults'], fake.io, { run: runner.run })).toBe(2);
    expect(fake.err()).toContain('already exists');
    expect(runner.calls.some((call) => call.args.includes('new'))).toBe(false);
  });

  it('rejects options that are planned but not available yet', async () => {
    const fake = createFakeIo({ cwd });
    const runner = createFakeRunner();
    const code = await run(['new', 'my-app', '--architecture', 'screaming'], fake.io, {
      run: runner.run,
    });
    expect(code).toBe(2);
    expect(fake.err()).toContain('not available yet');
    expect(runner.calls).toEqual([]);
  });

  it('creates the project through every stage and writes the Angular Starter configuration', async () => {
    const fake = createFakeIo({ cwd });
    const runner = createFakeRunner();
    const code = await run(['new', 'my-app', '--defaults'], fake.io, { run: runner.run });

    expect(code).toBe(0);
    const out = fake.out();
    for (const title of [
      'Validating environment',
      'Creating Angular workspace',
      'Writing Angular Starter configuration',
      'Installing dependencies',
      'Initializing Git repository',
      'Validating generated application',
    ]) {
      expect(out).toContain(`✓ ${title}`);
    }
    expect(out).toContain('Project created successfully!');
    expect(out).toContain('cd my-app');

    const target = join(cwd, 'my-app');
    const ng = runner.calls.find((call) => call.args.includes('new'));
    expect(ng?.cwd).toBe(cwd);
    expect(ng?.args.slice(0, 4)).toEqual([
      '--yes',
      `@angular/cli@${ANGULAR_CLI_VERSION}`,
      'new',
      'my-app',
    ]);
    expect(runner.calls).toContainEqual({ command: 'npm', args: ['install'], cwd: target });
    expect(runner.calls).toContainEqual({ command: 'git', args: ['init'], cwd: target });
    expect(runner.calls).toContainEqual({ command: 'git', args: ['add', '-A'], cwd: target });
    expect(runner.calls.some((call) => call.command === 'git' && call.args[0] === 'commit')).toBe(
      true,
    );

    const config = JSON.parse(await readFile(join(target, 'angular-starter.config.json'), 'utf8'));
    expect(config.schemaVersion).toBe(1);
    expect(config.generator.angularCli).toBe(ANGULAR_CLI_VERSION);
    expect(config.options).toMatchObject({
      architecture: 'angular-default',
      style: 'css',
      tailwind: true,
    });
  });

  it('skips installation and Git when asked to', async () => {
    const fake = createFakeIo({ cwd });
    const runner = createFakeRunner();
    const code = await run(['new', 'my-app', '--defaults', '--no-install', '--no-git'], fake.io, {
      run: runner.run,
    });
    expect(code).toBe(0);
    expect(fake.out()).not.toContain('Installing dependencies');
    expect(fake.out()).not.toContain('Initializing Git repository');
    expect(runner.calls.some((call) => call.args.includes('install'))).toBe(false);
    expect(runner.calls.some((call) => call.command === 'git' && call.args[0] === 'init')).toBe(
      false,
    );
    expect(fake.out()).toContain('npm install');
  });

  it('reads options from --config and lets flags override them', async () => {
    const { writeFile } = await import('node:fs/promises');
    await writeFile(
      join(cwd, 'starter.json'),
      JSON.stringify({ options: { style: 'scss', packageManager: 'pnpm', prefix: 'acme' } }),
    );
    const fake = createFakeIo({ cwd });
    const runner = createFakeRunner();
    const code = await run(
      ['new', 'my-app', '--config', 'starter.json', '--prefix', 'shop', '--no-install'],
      fake.io,
      { run: runner.run },
    );
    expect(code).toBe(0);
    const args = runner.calls.find((call) => call.args.includes('new'))?.args ?? [];
    expect(args).toContain('--style=scss');
    expect(args).toContain('--package-manager=pnpm');
    expect(args).toContain('--prefix=shop');
  });

  it('fails clearly, without claiming success, when the Angular workspace cannot be created', async () => {
    const fake = createFakeIo({ cwd });
    const runner = createFakeRunner({
      failOn: (call) => (call.args.includes('new') ? new Error('network down') : undefined),
    });
    const code = await run(['new', 'my-app', '--defaults'], fake.io, { run: runner.run });

    expect(code).toBe(1);
    expect(fake.out()).toContain('✗ Creating Angular workspace');
    expect(fake.out()).not.toContain('Project created successfully');
    expect(fake.err()).toContain('network down');
    expect(runner.calls.some((call) => call.args.includes('install'))).toBe(false);
  });

  it('treats a failed initial commit as a warning, not as a failure', async () => {
    const fake = createFakeIo({ cwd });
    const runner = createFakeRunner({
      failOn: (call) =>
        call.command === 'git' && call.args[0] === 'commit' ? new Error('no identity') : undefined,
    });
    const code = await run(['new', 'my-app', '--defaults', '--no-install'], fake.io, {
      run: runner.run,
    });
    expect(code).toBe(0);
    expect(fake.out()).toContain('Project created successfully!');
    expect(fake.out()).toContain('initial commit');
    expect(fake.out()).toContain('no identity');
  });

  it('fails when the chosen package manager is not installed', async () => {
    const fake = createFakeIo({ cwd });
    const runner = createFakeRunner({
      failOn: (call) => (call.command === 'pnpm' ? new Error('not found') : undefined),
    });
    const code = await run(['new', 'my-app', '--defaults', '--package-manager', 'pnpm'], fake.io, {
      run: runner.run,
    });
    expect(code).toBe(2);
    expect(fake.err()).toContain('pnpm');
    expect(await exists(join(cwd, 'my-app'))).toBe(false);
  });

  it('shows the plan and creates nothing with --dry-run', async () => {
    const fake = createFakeIo({ cwd });
    const runner = createFakeRunner();
    const code = await run(['new', 'my-app', '--defaults', '--dry-run'], fake.io, {
      run: runner.run,
    });

    expect(code).toBe(0);
    const out = fake.out();
    expect(out).toContain('Project name');
    expect(out).toContain('my-app');
    expect(out).toContain('Dry run');
    expect(out).toContain(`@angular/cli@${ANGULAR_CLI_VERSION}`);
    expect(runner.calls.some((call) => call.args.includes('new'))).toBe(false);
    expect(await exists(join(cwd, 'my-app'))).toBe(false);
  });

  it('lists only the values that can be used in the help of `new`', async () => {
    const fake = createFakeIo();
    expect(await run(['new', '--help'], fake.io)).toBe(0);
    const out = fake.out();
    expect(out).toContain('Usage: as new');
    expect(out).toContain('--package-manager');
    expect(out).toContain('--dry-run');
    expect(out).toContain('--config');
    expect(out).not.toContain('screaming');
    expect(out).not.toContain('starter-ssr');
  });
});

describe('as new (interactive)', () => {
  it('asks for the missing values, shows a summary and creates the project', async () => {
    const fake = createFakeIo({ cwd, interactive: true });
    const runner = createFakeRunner();
    // style, rendering, package manager, git, install, final confirmation.
    const { prompter, asked } = createFakePrompter(['scss', 'csr', 'pnpm', false, false, true]);
    const code = await run(['new', 'my-app'], fake.io, { run: runner.run, prompter });

    expect(code).toBe(0);
    expect(asked.map((question) => question.name)).toEqual([
      'style',
      'rendering',
      'packageManager',
      'git',
      'install',
      'confirm',
    ]);
    const args = runner.calls.find((call) => call.args.includes('new'))?.args ?? [];
    expect(args).toContain('--style=scss');
    expect(args).toContain('--package-manager=pnpm');
    expect(fake.out()).toContain('Project configuration');
    expect(runner.calls.some((call) => call.args.includes('install'))).toBe(false);
  });

  it('asks for the project name when it was not given', async () => {
    const fake = createFakeIo({ cwd, interactive: true });
    const runner = createFakeRunner();
    const { prompter, asked } = createFakePrompter([
      'my-app',
      'css',
      true,
      'csr',
      'npm',
      false,
      false,
      true,
    ]);
    expect(await run(['new'], fake.io, { run: runner.run, prompter })).toBe(0);
    expect(asked[0]?.name).toBe('projectName');
    expect(await exists(join(cwd, 'my-app', 'angular-starter.config.json'))).toBe(true);
  });

  it('creates nothing when the final confirmation is declined', async () => {
    const fake = createFakeIo({ cwd, interactive: true });
    const runner = createFakeRunner();
    const { prompter } = createFakePrompter(['css', true, 'csr', 'npm', true, true, false]);
    expect(await run(['new', 'my-app'], fake.io, { run: runner.run, prompter })).toBe(130);
    expect(runner.calls.some((call) => call.args.includes('new'))).toBe(false);
    expect(await exists(join(cwd, 'my-app'))).toBe(false);
  });

  it('exits with 130 when the user presses Ctrl+C in a prompt', async () => {
    const fake = createFakeIo({ cwd, interactive: true });
    const cancelled = Object.assign(new Error('User force closed the prompt'), {
      name: 'ExitPromptError',
    });
    const { prompter } = createFakePrompter([cancelled]);
    expect(await run(['new', 'my-app'], fake.io, { run: createFakeRunner().run, prompter })).toBe(
      130,
    );
  });

  it('does not prompt when --defaults is used, even in a terminal', async () => {
    const fake = createFakeIo({ cwd, interactive: true });
    const { prompter, asked } = createFakePrompter([]);
    expect(
      await run(['new', 'my-app', '--defaults', '--dry-run'], fake.io, {
        run: createFakeRunner().run,
        prompter,
      }),
    ).toBe(0);
    expect(asked).toEqual([]);
  });
});
