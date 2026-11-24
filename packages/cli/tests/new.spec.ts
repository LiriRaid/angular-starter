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
    expect(runner.calls).toContainEqual({
      command: 'npm',
      args: ['install', '--no-audit', '--no-fund', '--prefer-offline'],
      cwd: target,
    });
    expect(runner.calls).toContainEqual({ command: 'git', args: ['init'], cwd: target });
    expect(runner.calls).toContainEqual({ command: 'git', args: ['add', '-A'], cwd: target });
    expect(runner.calls.some((call) => call.command === 'git' && call.args[0] === 'commit')).toBe(
      true,
    );

    const config = JSON.parse(await readFile(join(target, 'angular-starter.config.json'), 'utf8'));
    expect(config.schemaVersion).toBe(1);
    expect(config.generator.angularCli).toBe(ANGULAR_CLI_VERSION);
    expect(config.options).toMatchObject({
      architecture: 'screaming',
      routing: 'starter',
      style: 'css',
      tailwind: true,
      rendering: 'csr',
      icons: 'lucide',
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
        [
          'new',
          'my-app',
          '--defaults',
          '--architecture',
          'screaming',
          '--routing',
          'angular',
          '--no-install',
          '--no-git',
        ],
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
    const code = await run(
      ['new', 'my-app', '--defaults', '--architecture', 'angular-default', '--routing', 'starter'],
      fake.io,
      { run: runner.run },
    );
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
      await run(
        [
          'new',
          'my-app',
          '--defaults',
          '--architecture',
          'angular-default',
          '--no-install',
          '--no-git',
        ],
        fake.io,
        { run: createFakeRunner().run },
      ),
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
      await run(
        ['new', 'my-app', '--defaults', '--icons', 'none', '--no-install', '--no-git'],
        fake.io,
        { run: createFakeRunner().run },
      ),
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

  it.each([
    [['--style', 'tailwind'], '--style=tailwind'],
    [['--tailwind'], '--style=tailwind'],
    [['--style', 'css'], '--style=css'],
    [['--style', 'css', '--tailwind'], '--style=tailwind'],
    [['--style', 'scss'], '--style=scss'],
  ])('passes %j to ng new as %s', async (flags, expected) => {
    const fake = createFakeIo({ cwd });
    const runner = createFakeRunner();
    const code = await run(
      ['new', 'my-app', '--defaults', '--no-install', '--no-git', ...flags],
      fake.io,
      { run: runner.run },
    );
    expect(code).toBe(0);
    expect(runner.calls.find((call) => call.args.includes('new'))?.args).toContain(expected);
  });

  it('rejects --style tailwind together with --no-tailwind', async () => {
    const fake = createFakeIo({ cwd });
    const runner = createFakeRunner();
    const code = await run(
      ['new', 'my-app', '--defaults', '--style', 'tailwind', '--no-tailwind'],
      fake.io,
      { run: runner.run },
    );
    expect(code).toBe(2);
    expect(fake.err()).toContain('--no-tailwind');
    expect(runner.calls).toEqual([]);
  });

  it('shows the components and the icons in the summary', async () => {
    const fake = createFakeIo({ cwd });
    await run(['new', 'my-app', '--defaults', '--dry-run'], fake.io, {
      run: createFakeRunner().run,
    });
    expect(fake.out()).toMatch(/^ {2}Components +Essential component collection$/m);
    expect(fake.out()).toMatch(/^ {2}Icons +Lucide Icons$/m);
  });

  it('applies the Starter SSR profile after the routing and before the icon library', async () => {
    const fake = createFakeIo({ cwd });
    const runner = createFakeRunner({
      files: {
        'src/app/app.config.ts': `import { ApplicationConfig } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideClientHydration } from '@angular/platform-browser';

export const appConfig: ApplicationConfig = {
  providers: [provideRouter([]), provideClientHydration()],
};
`,
      },
    });
    const code = await run(
      ['new', 'my-app', '--defaults', '--rendering', 'starter-ssr', '--no-install', '--no-git'],
      fake.io,
      { run: runner.run },
    );
    expect(code, fake.err()).toBe(0);
    const out = fake.out();
    const order = [
      'Adding Angular Starter routing',
      'Applying Angular Starter SSR',
      'Adding icon library',
    ].map((title) => out.indexOf(`✓ ${title}`));
    expect(order.every((index) => index >= 0)).toBe(true);
    expect(order).toEqual([...order].sort((a, b) => a - b));
    expect(runner.calls.find((call) => call.args.includes('new'))?.args).toContain('--ssr');
    expect(await readFile(join(cwd, 'my-app/src/app/app.config.ts'), 'utf8')).toContain(
      'withIncrementalHydration()',
    );
  });

  it('mentions the Starter SSR in the --dry-run plan', async () => {
    const fake = createFakeIo({ cwd });
    await run(['new', 'my-app', '--defaults', '--rendering', 'starter-ssr', '--dry-run'], fake.io, {
      run: createFakeRunner().run,
    });
    expect(fake.out()).toContain('Add incremental hydration, event replay and view transitions');
  });

  it('does not run the Starter SSR stage for the other rendering strategies', async () => {
    const fake = createFakeIo({ cwd });
    await run(['new', 'my-app', '--defaults', '--no-install', '--no-git'], fake.io, {
      run: createFakeRunner().run,
    });
    expect(fake.out()).not.toContain('Starter SSR');
  });

  it('adds the application shell after the components and before the icon library', async () => {
    const fake = createFakeIo({ cwd });
    const runner = createFakeRunner();
    const code = await run(['new', 'my-app', '--defaults', '--no-install', '--no-git'], fake.io, {
      run: runner.run,
    });
    expect(code, fake.err()).toBe(0);
    const out = fake.out();
    const order = [
      'Adding native components',
      'Adding the application shell',
      'Adding icon library',
    ].map((title) => out.indexOf(`✓ ${title}`));
    expect(order.every((index) => index >= 0)).toBe(true);
    expect(order).toEqual([...order].sort((a, b) => a - b));

    const target = join(cwd, 'my-app');
    expect(
      await readFile(join(target, 'src/app/features/app-shell/layout/main/main.ts'), 'utf8'),
    ).toContain("selector: 'app-main'");
    expect(await readFile(join(target, 'src/app/app.ts'), 'utf8')).toContain('provideLayout(');
    const config = JSON.parse(await readFile(join(target, 'angular-starter.config.json'), 'utf8'));
    expect(config.options.appShell).toBe('starter');
  });

  it('adds presence with --presence starter and leaves it out of the defaults', async () => {
    const plain = createFakeIo({ cwd });
    await run(['new', 'plain-app', '--defaults', '--no-install', '--no-git'], plain.io, {
      run: createFakeRunner().run,
    });
    expect(await readFile(join(cwd, 'plain-app', 'angular-starter.config.json'), 'utf8')).toContain(
      '"presence": "none"',
    );
    await expect(
      readFile(join(cwd, 'plain-app', 'src/app/core/presence/presence.service.ts'), 'utf8'),
    ).rejects.toThrow();

    const fake = createFakeIo({ cwd });
    const code = await run(
      ['new', 'my-app', '--defaults', '--presence', 'starter', '--no-install', '--no-git'],
      fake.io,
      { run: createFakeRunner().run },
    );
    expect(code, fake.err()).toBe(0);
    const out = fake.out();
    expect(out).toContain('Presence');
    expect(out.indexOf('✓ Adding the application shell')).toBeLessThan(
      out.indexOf('✓ Adding presence'),
    );
    const target = join(cwd, 'my-app');
    expect(
      await readFile(join(target, 'src/app/core/presence/presence.service.ts'), 'utf8'),
    ).toContain('class PresenceService');
    expect(await readFile(join(target, 'src/app/app.config.ts'), 'utf8')).toContain(
      'providePresence()',
    );
    const config = JSON.parse(await readFile(join(target, 'angular-starter.config.json'), 'utf8'));
    expect(config.options.presence).toBe('starter');
  });

  it('rejects --presence starter without the shell', async () => {
    const fake = createFakeIo({ cwd });
    const code = await run(
      ['new', 'my-app', '--defaults', '--app-shell', 'none', '--presence', 'starter'],
      fake.io,
      { run: createFakeRunner().run },
    );
    expect(code).toBe(2);
    expect(fake.err()).toContain('presence: "starter" requires the app shell: starter');
  });

  it('keeps the shell out with --app-shell none', async () => {
    const fake = createFakeIo({ cwd });
    const code = await run(
      ['new', 'my-app', '--defaults', '--app-shell', 'none', '--no-install', '--no-git'],
      fake.io,
      { run: createFakeRunner().run },
    );
    expect(code, fake.err()).toBe(0);
    expect(fake.out()).not.toContain('application shell');
    const target = join(cwd, 'my-app');
    await expect(
      readFile(join(target, 'src/app/features/app-shell/layout/main/main.ts'), 'utf8'),
    ).rejects.toThrow();
    expect(await readFile(join(target, 'src/app/app.ts'), 'utf8')).not.toContain('provideLayout');
  });

  it('brings the design base for the shell even without a component collection', async () => {
    const fake = createFakeIo({ cwd });
    const code = await run(
      ['new', 'my-app', '--defaults', '--components', 'none', '--no-install', '--no-git'],
      fake.io,
      { run: createFakeRunner().run },
    );
    expect(code, fake.err()).toBe(0);
    const target = join(cwd, 'my-app');
    expect(await readFile(join(target, 'src/styles.css'), 'utf8')).toContain(
      "@import './styles/features/sidebar-styles.css';",
    );
    expect(
      await readFile(join(target, 'src/app/shared/components/as-search/as-search.ts'), 'utf8'),
    ).toContain('AsSearch');
  });

  it('loads the Inter font only with the design base, never in an Angular default project', async () => {
    const withDesign = createFakeIo({ cwd });
    await run(['new', 'with-design', '--defaults', '--no-install', '--no-git'], withDesign.io, {
      run: createFakeRunner().run,
    });
    expect(await readFile(join(cwd, 'with-design/src/index.html'), 'utf8')).toContain(
      'family=Inter:wght@100..900',
    );

    const plain = createFakeIo({ cwd });
    const code = await run(
      [
        'new',
        'plain',
        '--defaults',
        '--architecture',
        'angular-default',
        '--routing',
        'angular',
        '--components',
        'none',
        '--no-install',
        '--no-git',
      ],
      plain.io,
      { run: createFakeRunner().run },
    );
    expect(code, plain.err()).toBe(0);
    expect(await readFile(join(cwd, 'plain/src/index.html'), 'utf8')).not.toContain('Inter');
  });

  it('rejects the shell without the starter routing before doing anything', async () => {
    const fake = createFakeIo({ cwd });
    const runner = createFakeRunner();
    const code = await run(
      ['new', 'my-app', '--defaults', '--routing', 'angular', '--app-shell', 'starter'],
      fake.io,
      { run: runner.run },
    );
    expect(code).toBe(2);
    expect(fake.err()).toContain('appShell: "starter" requires the routing: starter');
    expect(runner.calls).toEqual([]);
  });

  it('mentions the application shell in the --dry-run plan and the summary', async () => {
    const fake = createFakeIo({ cwd });
    await run(['new', 'my-app', '--defaults', '--dry-run'], fake.io, {
      run: createFakeRunner().run,
    });
    expect(fake.out()).toContain('Add the Angular Starter App Shell');
    expect(fake.out()).toMatch(/^ {2}App shell +Angular Starter App Shell$/m);
  });

  it('records the layout, the purpose and the UI System, and shows them in the summary', async () => {
    const fake = createFakeIo({ cwd });
    const code = await run(['new', 'my-app', '--defaults', '--no-install', '--no-git'], fake.io, {
      run: createFakeRunner().run,
    });
    expect(code, fake.err()).toBe(0);
    expect(fake.out()).toMatch(/^ {2}Layout +Floating \(wide\)$/m);
    expect(fake.out()).toMatch(/^ {2}UI System +None$/m);
    const config = JSON.parse(
      await readFile(join(cwd, 'my-app', 'angular-starter.config.json'), 'utf8'),
    );
    expect(config.options).toMatchObject({
      ssrPurpose: 'none',
      layout: 'floating-wide',
      uiSystem: 'none',
    });
  });

  it('records the purpose of Starter SSR and refuses the ones under construction', async () => {
    const backoffice = createFakeIo({ cwd });
    expect(
      await run(
        ['new', 'my-app', '--defaults', '--rendering', 'starter-ssr', '--no-install', '--no-git'],
        backoffice.io,
        {
          run: createFakeRunner({
            files: {
              'src/app/app.config.ts': `import { ApplicationConfig } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideClientHydration } from '@angular/platform-browser';

export const appConfig: ApplicationConfig = {
  providers: [provideRouter([]), provideClientHydration()],
};
`,
            },
          }).run,
        },
      ),
      backoffice.err(),
    ).toBe(0);
    const config = JSON.parse(
      await readFile(join(cwd, 'my-app', 'angular-starter.config.json'), 'utf8'),
    );
    expect(config.options).toMatchObject({ rendering: 'starter-ssr', ssrPurpose: 'backoffice' });

    const landing = createFakeIo({ cwd });
    const runner = createFakeRunner();
    const code = await run(
      ['new', 'shop', '--defaults', '--rendering', 'starter-ssr', '--ssr-purpose', 'landing'],
      landing.io,
      { run: runner.run },
    );
    expect(code).toBe(2);
    expect(landing.err()).toContain('ssrPurpose: "landing" is not available yet');
    expect(runner.calls).toEqual([]);
  });

  it('adds the UI System with --ui-system starter and leaves it out of the defaults', async () => {
    const fake = createFakeIo({ cwd });
    const code = await run(
      ['new', 'my-app', '--defaults', '--ui-system', 'starter', '--no-install', '--no-git'],
      fake.io,
      { run: createFakeRunner().run },
    );
    expect(code, fake.err()).toBe(0);
    const out = fake.out();
    expect(out.indexOf('✓ Adding the application shell')).toBeLessThan(
      out.indexOf('✓ Adding the UI System'),
    );
    const target = join(cwd, 'my-app');
    expect(
      await readFile(join(target, 'src/app/features/preference-design/tabs/ui-tab.html'), 'utf8'),
    ).toContain('<app-ui-system />');
    const config = JSON.parse(await readFile(join(target, 'angular-starter.config.json'), 'utf8'));
    expect(config.options.uiSystem).toBe('starter');
  });

  it('rejects --ui-system starter without a component collection', async () => {
    const fake = createFakeIo({ cwd });
    const code = await run(
      ['new', 'my-app', '--defaults', '--components', 'none', '--ui-system', 'starter'],
      fake.io,
      { run: createFakeRunner().run },
    );
    expect(code).toBe(2);
    expect(fake.err()).toContain('uiSystem: "starter" requires the components: recommended, all');
  });

  it('generates only the components of --components with their ids, plus what they import', async () => {
    const fake = createFakeIo({ cwd });
    const code = await run(
      [
        'new',
        'my-app',
        '--defaults',
        '--app-shell',
        'none',
        '--components',
        'modal,toggle',
        '--no-install',
        '--no-git',
      ],
      fake.io,
      { run: createFakeRunner().run },
    );
    expect(code, fake.err()).toBe(0);
    const target = join(cwd, 'my-app');
    for (const id of ['modal', 'toggle', 'button', 'icon']) {
      expect(await exists(join(target, `src/app/shared/components/as-${id}/as-${id}.ts`)), id).toBe(
        true,
      );
    }
    expect(await exists(join(target, 'src/app/shared/components/as-table/as-table.ts'))).toBe(
      false,
    );
    const config = JSON.parse(await readFile(join(target, 'angular-starter.config.json'), 'utf8'));
    expect(config.options).toMatchObject({
      components: 'custom',
      componentList: ['modal', 'toggle'],
    });
    expect(fake.out()).toMatch(/^ {2}Components +Custom selection \(2: modal, toggle\)$/m);
  });

  it('refuses a custom selection without ids and ids that are not components', async () => {
    const without = createFakeIo({ cwd });
    expect(
      await run(['new', 'a-app', '--defaults', '--components', 'custom'], without.io, {
        run: createFakeRunner().run,
      }),
    ).toBe(2);
    expect(without.err()).toContain('componentList');

    const unknown = createFakeIo({ cwd });
    expect(
      await run(['new', 'b-app', '--defaults', '--components', 'button,carousel'], unknown.io, {
        run: createFakeRunner().run,
      }),
    ).toBe(2);
    expect(unknown.err()).toContain('"carousel"');
  });

  it('refuses a layout mode that is under construction before doing anything', async () => {
    const fake = createFakeIo({ cwd });
    const runner = createFakeRunner();
    const code = await run(['new', 'my-app', '--defaults', '--layout', 'compact-joined'], fake.io, {
      run: runner.run,
    });
    expect(code).toBe(2);
    expect(fake.err()).toContain('layout: "compact-joined" is not available yet');
    expect(runner.calls).toEqual([]);
  });

  it('leaves Angular plain with the default structure: no Lucide, no shell, no layout', async () => {
    const fake = createFakeIo({ cwd });
    await run(
      ['new', 'my-app', '--defaults', '--architecture', 'angular-default', '--dry-run'],
      fake.io,
      { run: createFakeRunner().run },
    );
    expect(fake.out()).toMatch(/^ {2}Icons +None$/m);
    expect(fake.out()).toMatch(/^ {2}Layout +None$/m);
    expect(fake.out()).not.toContain('Lucide');
  });

  it('lists only the values that can be used in the help of `new`', async () => {
    const fake = createFakeIo();
    expect(await run(['new', '--help'], fake.io)).toBe(0);
    const out = fake.out();
    expect(out).toContain('Usage: as new');
    expect(out).toContain('--package-manager');
    expect(out).toContain('--dry-run');
    expect(out).toContain('--config');
    expect(out).toContain('press Esc to go back');
    expect(out).toContain('screaming');
    expect(out).not.toContain('modular');
    expect(out).toContain('starter-ssr');
  });
});

describe('as new (interactive)', () => {
  it('asks for the missing values, shows a summary and creates the project', async () => {
    const fake = createFakeIo({ cwd, interactive: true });
    const runner = createFakeRunner();
    // architecture, style, rendering, package manager, git, install, final confirmation: the
    // default Angular structure has no routing, shell, components or icon questions.
    const { prompter, asked } = createFakePrompter([
      'angular-default',
      'scss',
      'csr',
      'pnpm',
      false,
      false,
      'create',
    ]);
    const code = await run(['new', 'my-app'], fake.io, { run: runner.run, prompter });

    expect(code).toBe(0);
    expect(asked.map((question) => question.name)).toEqual([
      'architecture',
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
      'angular-default',
      'css',
      'csr',
      'npm',
      false,
      false,
      'create',
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
      'csr',
      'npm',
      true,
      true,
      'cancel',
    ]);
    expect(await run(['new', 'my-app'], fake.io, { run: runner.run, prompter })).toBe(130);
    expect(runner.calls.some((call) => call.args.includes('new'))).toBe(false);
    expect(await exists(join(cwd, 'my-app'))).toBe(false);
  });

  it('lets the user change an answer from the final confirmation before creating anything', async () => {
    const fake = createFakeIo({ cwd, interactive: true });
    const runner = createFakeRunner();
    const { prompter, asked } = createFakePrompter([
      'angular-default',
      'scss',
      'csr',
      'npm',
      false,
      false,
      'change',
      'style',
      'css',
      'csr',
      'npm',
      false,
      false,
      'create',
    ]);
    expect(await run(['new', 'my-app'], fake.io, { run: runner.run, prompter })).toBe(0);
    expect(asked.map((question) => question.name)).toContain('changeAnswer');
    const args = runner.calls.find((call) => call.args.includes('new'))?.args ?? [];
    expect(args).toContain('--style=css');
    expect(args).not.toContain('--style=scss');
    // The summary is printed again with what was changed.
    expect(fake.out().match(/Project configuration/g)).toHaveLength(2);
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
