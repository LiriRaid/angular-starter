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

  it('accepts a name with capital letters, like ng new', async () => {
    const fake = createFakeIo({ cwd });
    const runner = createFakeRunner();
    expect(
      await run(['new', 'InventorySystem', '--defaults', '--no-install', '--no-git'], fake.io, {
        run: runner.run,
      }),
    ).toBe(0);
    expect(await exists(join(cwd, 'InventorySystem', 'angular-starter.config.json'))).toBe(true);
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
    const code = await run(['new', 'my-app', '--architecture', 'modular'], fake.io, {
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

  it('applies the Screaming Architecture profile between creating the workspace and installing', async () => {
    const fake = createFakeIo({ cwd });
    const runner = createFakeRunner();
    const code = await run(
      ['new', 'my-app', '--defaults', '--architecture', 'screaming'],
      fake.io,
      {
        run: runner.run,
      },
    );

    expect(code).toBe(0);
    const out = fake.out();
    const order = [
      'Creating Angular workspace',
      'Applying architecture profile',
      'Writing Angular Starter configuration',
      'Installing dependencies',
    ].map((title) => out.indexOf(`✓ ${title}`));
    expect(order.every((index) => index >= 0)).toBe(true);
    expect(order).toEqual([...order].sort((a, b) => a - b));

    const target = join(cwd, 'my-app');
    expect(await exists(join(target, 'src/app/features/home/home.routes.ts'))).toBe(true);
    expect(await readFile(join(target, 'tsconfig.json'), 'utf8')).toContain('@features/*');
    const config = JSON.parse(await readFile(join(target, 'angular-starter.config.json'), 'utf8'));
    expect(config.options.architecture).toBe('screaming');
  });

  it('adds the Angular Starter routing after the architecture profile and before installing', async () => {
    const fake = createFakeIo({ cwd });
    const runner = createFakeRunner();
    const code = await run(
      ['new', 'my-app', '--defaults', '--architecture', 'screaming', '--routing', 'starter'],
      fake.io,
      { run: runner.run },
    );

    expect(code).toBe(0);
    const out = fake.out();
    const order = [
      'Applying architecture profile',
      'Adding Angular Starter routing',
      'Writing Angular Starter configuration',
      'Installing dependencies',
    ].map((title) => out.indexOf(`✓ ${title}`));
    expect(order.every((index) => index >= 0)).toBe(true);
    expect(order).toEqual([...order].sort((a, b) => a - b));

    const target = join(cwd, 'my-app');
    expect(await exists(join(target, 'src/app/core/navigation/breadcrumb.service.ts'))).toBe(true);
    expect(await readFile(join(target, 'src/app/app.config.ts'), 'utf8')).toContain(
      "provideNavigation(APP_NAVIGATION, { appName: 'my-app' })",
    );
    const config = JSON.parse(await readFile(join(target, 'angular-starter.config.json'), 'utf8'));
    expect(config.options.routing).toBe('starter');
  });

  it('does not add the navigation files with the default Angular routing', async () => {
    const fake = createFakeIo({ cwd });
    expect(
      await run(
        ['new', 'my-app', '--defaults', '--architecture', 'screaming', '--no-install', '--no-git'],
        fake.io,
        { run: createFakeRunner().run },
      ),
    ).toBe(0);
    expect(fake.out()).not.toContain('Angular Starter routing');
    expect(await exists(join(cwd, 'my-app/src/app/core/navigation'))).toBe(false);
  });

  it('rejects the starter routing without the Screaming architecture before doing anything', async () => {
    const fake = createFakeIo({ cwd });
    const runner = createFakeRunner();
    const code = await run(['new', 'my-app', '--defaults', '--routing', 'starter'], fake.io, {
      run: runner.run,
    });
    expect(code).toBe(2);
    expect(fake.err()).toContain('requires the architecture: screaming');
    expect(runner.calls).toEqual([]);
  });

  it('fails without installing when app.config.ts cannot take the navigation providers', async () => {
    const fake = createFakeIo({ cwd });
    // Good enough for the architecture profile (it finds provideRouter), but no providers array.
    const runner = createFakeRunner({
      files: {
        'src/app/app.config.ts':
          "import { provideRouter } from '@angular/router';\nexport const appConfig = { providers: provideRouter([]) };\n",
      },
    });
    const code = await run(
      ['new', 'my-app', '--defaults', '--architecture', 'screaming', '--routing', 'starter'],
      fake.io,
      { run: runner.run },
    );
    expect(code).toBe(1);
    expect(fake.out()).toContain('✗ Adding Angular Starter routing');
    expect(runner.calls.some((call) => call.args.includes('install'))).toBe(false);
  });

  it('does not apply any profile to the default Angular structure', async () => {
    const fake = createFakeIo({ cwd });
    expect(
      await run(['new', 'my-app', '--defaults', '--no-install', '--no-git'], fake.io, {
        run: createFakeRunner().run,
      }),
    ).toBe(0);
    expect(fake.out()).not.toContain('Applying');
    expect(await exists(join(cwd, 'my-app/src/app/features'))).toBe(false);
  });

  it('fails without installing when the generated files do not have the expected shape', async () => {
    const fake = createFakeIo({ cwd });
    const runner = createFakeRunner({
      files: { 'src/app/app.routes.ts': 'export const other = 1;\n' },
    });
    const code = await run(
      ['new', 'my-app', '--defaults', '--architecture', 'screaming'],
      fake.io,
      {
        run: runner.run,
      },
    );
    expect(code).toBe(1);
    expect(fake.out()).toContain('✗ Applying architecture profile');
    expect(fake.out()).not.toContain('Project created successfully');
    expect(runner.calls.some((call) => call.args.includes('install'))).toBe(false);
    expect(fake.err()).toContain('A partial project was left');
  });

  it('adds the Lucide icon library to package.json before installing', async () => {
    const fake = createFakeIo({ cwd });
    const runner = createFakeRunner();
    const code = await run(['new', 'my-app', '--defaults', '--icons', 'lucide'], fake.io, {
      run: runner.run,
    });

    expect(code).toBe(0);
    const out = fake.out();
    expect(out.indexOf('✓ Adding icon library')).toBeGreaterThan(-1);
    expect(out.indexOf('✓ Adding icon library')).toBeLessThan(
      out.indexOf('✓ Installing dependencies'),
    );
    expect(out).toContain('https://lucide.dev/guide/angular/getting-started');

    const manifest = JSON.parse(await readFile(join(cwd, 'my-app', 'package.json'), 'utf8'));
    expect(manifest.dependencies['@lucide/angular']).toMatch(/^\^1\./);
    expect(manifest.dependencies['@angular/core']).toBe('^22.3.0');
    const config = JSON.parse(
      await readFile(join(cwd, 'my-app', 'angular-starter.config.json'), 'utf8'),
    );
    expect(config.options.icons).toBe('lucide');
  });

  it('does not touch package.json when no icon library is chosen', async () => {
    const fake = createFakeIo({ cwd });
    expect(
      await run(['new', 'my-app', '--defaults', '--no-install', '--no-git'], fake.io, {
        run: createFakeRunner().run,
      }),
    ).toBe(0);
    expect(fake.out()).not.toContain('Adding icon library');
    expect(await readFile(join(cwd, 'my-app', 'package.json'), 'utf8')).not.toContain('lucide');
  });

  it('mentions the icon library in the --dry-run plan', async () => {
    const fake = createFakeIo({ cwd });
    const code = await run(
      ['new', 'my-app', '--defaults', '--icons', 'lucide', '--dry-run'],
      fake.io,
      { run: createFakeRunner().run },
    );
    expect(code).toBe(0);
    expect(fake.out()).toContain('Add the Lucide Icons package (@lucide/angular)');
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

  it('mentions the architecture profile in the --dry-run plan', async () => {
    const fake = createFakeIo({ cwd });
    const code = await run(
      ['new', 'my-app', '--defaults', '--architecture', 'screaming', '--dry-run'],
      fake.io,
      { run: createFakeRunner().run },
    );
    expect(code).toBe(0);
    expect(fake.out()).toContain('Apply the Screaming Architecture profile');
  });

  it('mentions the Angular Starter routing in the --dry-run plan', async () => {
    const fake = createFakeIo({ cwd });
    const code = await run(
      [
        'new',
        'my-app',
        '--defaults',
        '--architecture',
        'screaming',
        '--routing',
        'starter',
        '--dry-run',
      ],
      fake.io,
      { run: createFakeRunner().run },
    );
    expect(code).toBe(0);
    expect(fake.out()).toContain('Add the Angular Starter Routing (navigation tree');
  });

  it('lists only the values that can be used in the help of `new`', async () => {
    const fake = createFakeIo();
    expect(await run(['new', '--help'], fake.io)).toBe(0);
    const out = fake.out();
    expect(out).toContain('Usage: as new');
    expect(out).toContain('--package-manager');
    expect(out).toContain('--dry-run');
    expect(out).toContain('--config');
    expect(out).toContain('screaming');
    expect(out).not.toContain('modular');
    expect(out).not.toContain('starter-ssr');
  });
});

describe('as new (interactive)', () => {
  it('asks for the missing values, shows a summary and creates the project', async () => {
    const fake = createFakeIo({ cwd, interactive: true });
    const runner = createFakeRunner();
    // architecture, style, rendering, icons, package manager, git, install, final confirmation.
    const { prompter, asked } = createFakePrompter([
      'angular-default',
      'scss',
      'csr',
      'none',
      'pnpm',
      false,
      false,
      true,
    ]);
    const code = await run(['new', 'my-app'], fake.io, { run: runner.run, prompter });

    expect(code).toBe(0);
    expect(asked.map((question) => question.name)).toEqual([
      'architecture',
      'style',
      'rendering',
      'icons',
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
      'angular-default',
      'css',
      true,
      'csr',
      'none',
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
    const { prompter } = createFakePrompter([
      'angular-default',
      'css',
      true,
      'csr',
      'none',
      'npm',
      true,
      true,
      false,
    ]);
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
