import { mkdtemp, readFile, rm, stat, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { ANGULAR_CLI_VERSION } from '../src/compat.js';
import { run } from '../src/main.js';
import { createFakeIo } from './helpers/fake-io.js';
import { createFakeRunner, type FakeRunnerOptions } from './helpers/fake-runner.js';
import { SSR_APP_CONFIG, createStarterProject } from './helpers/starter-project.js';

let cwd: string;

beforeEach(async () => {
  cwd = await mkdtemp(join(tmpdir(), 'as-add-'));
});

afterEach(async () => {
  await rm(cwd, { recursive: true, force: true });
});

const exists = (path: string): Promise<boolean> =>
  stat(path).then(
    () => true,
    () => false,
  );

async function add(project: string, args: string[], runnerOptions: FakeRunnerOptions = {}) {
  const fake = createFakeIo({ cwd: project });
  const runner = createFakeRunner(runnerOptions);
  const code = await run(['add', ...args], fake.io, { run: runner.run });
  return { code, out: fake.out(), err: fake.err(), calls: runner.calls };
}

const readConfig = async (project: string) =>
  JSON.parse(await readFile(join(project, 'angular-starter.config.json'), 'utf8')).options;

describe('as add', () => {
  it('needs a project created by Angular Starter', async () => {
    const result = await add(cwd, ['icons', 'lucide']);
    expect(result.code).toBe(2);
    expect(result.err).toContain('angular-starter.config.json');
  });

  it('names the capabilities it can add when asked for another one', async () => {
    const project = await createStarterProject(cwd);
    const result = await add(project, ['theme']);
    expect(result.code).toBe(2);
    expect(result.err).toContain('Unknown capability "theme"');
    for (const name of ['icons', 'components', 'routing', 'rendering']) {
      expect(result.err).toContain(name);
    }
  });

  it('says what only `as new` can decide', async () => {
    const project = await createStarterProject(cwd);
    const result = await add(project, ['architecture', 'screaming']);
    expect(result.code).toBe(2);
    expect(result.err).toContain('as new');
  });

  describe('icons', () => {
    it('adds the Lucide package, installs it and records the choice', async () => {
      const project = await createStarterProject(cwd, ['--icons', 'none']);
      const result = await add(project, ['icons', 'lucide']);
      expect(result.code, result.err).toBe(0);
      expect(result.out).toContain('✓ Adding icon library');
      expect(result.out).toContain('https://lucide.dev/guide/angular/getting-started');
      const manifest = JSON.parse(await readFile(join(project, 'package.json'), 'utf8'));
      expect(manifest.dependencies).toHaveProperty(['@lucide/angular']);
      expect((await readConfig(project)).icons).toBe('lucide');
      expect(result.calls).toContainEqual({ command: 'npm', args: ['install'], cwd: project });
    });

    it('does not install with --no-install', async () => {
      const project = await createStarterProject(cwd, ['--icons', 'none']);
      const result = await add(project, ['icons', 'lucide', '--no-install']);
      expect(result.code).toBe(0);
      expect(result.calls.some((call) => call.args.includes('install'))).toBe(false);
    });

    it('refuses what is already there', async () => {
      const project = await createStarterProject(cwd, ['--icons', 'lucide']);
      const result = await add(project, ['icons', 'lucide']);
      expect(result.code).toBe(2);
      expect(result.err).toContain('already');
    });

    it('refuses a library that is only planned', async () => {
      const project = await createStarterProject(cwd, ['--icons', 'none']);
      const result = await add(project, ['icons', 'heroicons']);
      expect(result.code).toBe(2);
      expect(result.err).toContain('not available yet');
    });
  });

  describe('routing', () => {
    it('adds the navigation tree, the title strategy and the breadcrumbs', async () => {
      const project = await createStarterProject(cwd, ['--routing', 'angular']);
      expect(await exists(join(project, 'src/app/core/navigation'))).toBe(false);
      const result = await add(project, ['routing', 'starter']);
      expect(result.code, result.err).toBe(0);
      expect(await exists(join(project, 'src/app/core/navigation/breadcrumb.service.ts'))).toBe(
        true,
      );
      expect(await readFile(join(project, 'src/app/app.config.ts'), 'utf8')).toContain(
        "provideNavigation(APP_NAVIGATION, { appName: 'demo' })",
      );
      expect((await readConfig(project)).routing).toBe('starter');
    });

    it('needs the architecture the routing is built on', async () => {
      const project = await createStarterProject(cwd, ['--architecture', 'angular-default']);
      const result = await add(project, ['routing', 'starter']);
      expect(result.code).toBe(2);
      expect(result.err).toContain('requires the architecture: screaming');
    });

    it('refuses to add it twice', async () => {
      const project = await createStarterProject(cwd);
      const result = await add(project, ['routing', 'starter']);
      expect(result.code).toBe(2);
      expect(result.err).toContain('already');
    });
  });

  describe('rendering', () => {
    it('adds Angular SSR with the official ng add and records it', async () => {
      const project = await createStarterProject(cwd);
      const result = await add(project, ['rendering', 'ssr']);
      expect(result.code, result.err).toBe(0);
      expect(result.calls).toContainEqual({
        command: 'npx',
        args: [
          '--yes',
          `@angular/cli@${ANGULAR_CLI_VERSION}`,
          'add',
          '@angular/ssr',
          '--skip-confirmation',
        ],
        cwd: project,
      });
      expect((await readConfig(project)).rendering).toBe('ssr');
    });

    it('adds the Starter SSR on top of the SSR that ng add leaves', async () => {
      const project = await createStarterProject(cwd);
      const result = await add(project, ['rendering', 'starter-ssr'], {
        onRun: async (call) => {
          if (call.args.includes('add')) {
            await writeFile(join(project, 'src/app/app.config.ts'), SSR_APP_CONFIG);
          }
        },
      });
      expect(result.code, result.err).toBe(0);
      expect(result.out).toContain('✓ Applying Angular Starter SSR');
      expect(await readFile(join(project, 'src/app/app.config.ts'), 'utf8')).toContain(
        'withIncrementalHydration()',
      );
      expect((await readConfig(project)).rendering).toBe('starter-ssr');
    });

    it('upgrades a project that already has Angular SSR without running ng add again', async () => {
      const project = await createStarterProject(cwd, ['--rendering', 'ssr'], {
        files: { 'src/app/app.config.ts': SSR_APP_CONFIG },
      });
      const result = await add(project, ['rendering', 'starter-ssr']);
      expect(result.code, result.err).toBe(0);
      expect(result.calls.some((call) => call.args.includes('@angular/ssr'))).toBe(false);
      expect((await readConfig(project)).rendering).toBe('starter-ssr');
    });

    it('cannot go back to client-side rendering', async () => {
      const project = await createStarterProject(cwd, ['--rendering', 'ssr']);
      const result = await add(project, ['rendering', 'csr']);
      expect(result.code).toBe(2);
      expect(result.err).toContain('csr');
    });
  });

  describe('components', () => {
    it('adds the design base, the components and the icon library they need', async () => {
      const project = await createStarterProject(cwd, ['--components', 'none', '--icons', 'none']);
      const result = await add(project, ['components', 'recommended']);
      expect(result.code, result.err).toBe(0);
      for (const title of [
        'Adding native components',
        'Adding the design base',
        'Adding icon library',
      ]) {
        expect(result.out).toContain(`✓ ${title}`);
      }
      expect(await exists(join(project, 'src/styles/design.css'))).toBe(true);
      expect(await exists(join(project, 'src/app/shared/components/as-button/as-button.ts'))).toBe(
        true,
      );
      expect(await readFile(join(project, 'src/app/shared/components/index.ts'), 'utf8')).toContain(
        'AsButton',
      );
      expect(await readFile(join(project, 'src/app/app.config.ts'), 'utf8')).toContain(
        'provideThemeInitializer()',
      );
      const options = await readConfig(project);
      expect(options).toMatchObject({ components: 'recommended', icons: 'lucide' });
      expect(result.calls).toContainEqual({ command: 'npm', args: ['install'], cwd: project });
    });

    it('needs the stylesheet the design is written in', async () => {
      const project = await createStarterProject(cwd, ['--style', 'scss']);
      const result = await add(project, ['components', 'recommended']);
      expect(result.code).toBe(2);
      expect(result.err).toContain('requires the stylesheet format: css');
    });

    it('needs the Screaming architecture', async () => {
      const project = await createStarterProject(cwd, ['--architecture', 'angular-default']);
      const result = await add(project, ['components', 'recommended']);
      expect(result.code).toBe(2);
      expect(result.err).toContain('requires the architecture: screaming');
    });

    it('refuses what the project already has', async () => {
      const project = await createStarterProject(cwd);
      const result = await add(project, ['components', 'recommended']);
      expect(result.code).toBe(2);
      expect(result.err).toContain('already');
    });
  });

  it('shows the plan and changes nothing with --dry-run', async () => {
    const project = await createStarterProject(cwd, ['--icons', 'none']);
    const result = await add(project, ['icons', 'lucide', '--dry-run']);
    expect(result.code).toBe(0);
    expect(result.out).toContain('Dry run');
    expect(result.out).toContain('Lucide Icons');
    expect((await readConfig(project)).icons).toBe('none');
    expect(result.calls).toEqual([]);
  });
});
