import { mkdir, mkdtemp, readFile, rm, stat, writeFile } from 'node:fs/promises';
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
    for (const name of [
      'icons',
      'components',
      'routing',
      'app-shell',
      'presence',
      'ui-system',
      'rendering',
    ]) {
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
      expect(result.calls).toContainEqual({
        command: 'npm',
        args: ['install', '--no-audit', '--no-fund', '--prefer-offline'],
        cwd: project,
      });
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

  describe('app-shell', () => {
    const PLAIN = ['--app-shell', 'none', '--components', 'none', '--icons', 'none'];

    it('adds the design base, the components it uses, Lucide and the shell, and records it', async () => {
      const project = await createStarterProject(cwd, PLAIN);
      const result = await add(project, ['app-shell']);
      expect(result.code, result.err).toBe(0);
      for (const title of [
        'Adding icon library',
        'Adding the design base',
        'Adding the application shell',
      ]) {
        expect(result.out).toContain(`✓ ${title}`);
      }
      expect(await exists(join(project, 'src/app/features/app-shell/layout/main/main.ts'))).toBe(
        true,
      );
      expect(await exists(join(project, 'src/app/shared/components/as-search/as-search.ts'))).toBe(
        true,
      );
      expect(await exists(join(project, 'src/app/shared/components/as-table'))).toBe(false);
      const options = await readConfig(project);
      expect(options).toMatchObject({ appShell: 'starter', components: 'none', icons: 'lucide' });
      expect(await readFile(join(project, 'src/app/app.ts'), 'utf8')).toContain('provideLayout(');
      expect(result.calls).toContainEqual({
        command: 'npm',
        args: ['install', '--no-audit', '--no-fund', '--prefer-offline'],
        cwd: project,
      });
    });

    it('needs the starter routing', async () => {
      const project = await createStarterProject(cwd, [...PLAIN, '--routing', 'angular']);
      const result = await add(project, ['app-shell', 'starter']);
      expect(result.code).toBe(2);
      expect(result.err).toContain('requires the routing: starter');
    });

    it('works on a project that already has the components, without adding the design twice', async () => {
      const project = await createStarterProject(cwd, [
        '--app-shell',
        'none',
        '--components',
        'recommended',
      ]);
      const result = await add(project, ['app-shell']);
      expect(result.code, result.err).toBe(0);
      expect(result.out).not.toContain('Adding the design base');
      expect((await readConfig(project)).components).toBe('recommended');
    });

    it('lets a bigger component collection be added later without touching the shell', async () => {
      const project = await createStarterProject(cwd);
      const main = join(project, 'src/app/features/app-shell/layout/main/main.ts');
      const before = await readFile(main, 'utf8');
      const result = await add(project, ['components', 'all']);
      expect(result.code, result.err).toBe(0);
      expect(await exists(join(project, 'src/app/shared/components/as-table/as-table.ts'))).toBe(
        true,
      );
      expect(await readFile(main, 'utf8')).toBe(before);
    });

    it('is refused with server rendering, which the shell does not support yet', async () => {
      const project = await createStarterProject(cwd, [...PLAIN, '--rendering', 'ssr']);
      const result = await add(project, ['app-shell']);
      expect(result.code).toBe(2);
      expect(result.err).toContain('requires the rendering: csr');
    });

    it('blocks adding server rendering to a project that has the shell', async () => {
      const project = await createStarterProject(cwd);
      const result = await add(project, ['rendering', 'ssr']);
      expect(result.code).toBe(2);
      expect(result.err).toContain('requires the rendering: csr');
    });

    it('refuses to add it twice', async () => {
      const project = await createStarterProject(cwd);
      const result = await add(project, ['app-shell']);
      expect(result.code).toBe(2);
      expect(result.err).toContain('already');
    });

    it('shows the steps with --dry-run and changes nothing', async () => {
      const project = await createStarterProject(cwd, PLAIN);
      const result = await add(project, ['app-shell', '--dry-run']);
      expect(result.code).toBe(0);
      expect(result.out).toContain('Dry run');
      expect(result.out).toContain('Adding the application shell');
      expect(await exists(join(project, 'src/app/features/app-shell/layout'))).toBe(false);
    });
  });

  describe('presence', () => {
    const MENU = 'src/app/features/app-shell/layout/sidebar/user-menu/user-menu.html';

    it('adds the realtime presence on top of the shell and records it', async () => {
      const project = await createStarterProject(cwd);
      const result = await add(project, ['presence']);
      expect(result.code, result.err).toBe(0);
      expect(result.out).toContain('✓ Adding presence');
      expect(await exists(join(project, 'src/app/core/presence/presence.service.ts'))).toBe(true);
      expect(await exists(join(project, 'docs/presence.md'))).toBe(true);
      expect((await readConfig(project)).presence).toBe('starter');
      expect(await readFile(join(project, 'src/app/app.config.ts'), 'utf8')).toContain(
        'providePresence()',
      );
      expect(await readFile(join(project, MENU), 'utf8')).toContain('um-status-trigger');
      expect(result.calls.some((call) => call.args.includes('install'))).toBe(false);
    });

    it('works on a project whose configuration was written before presence existed', async () => {
      const project = await createStarterProject(cwd);
      const file = join(project, 'angular-starter.config.json');
      const config = JSON.parse(await readFile(file, 'utf8'));
      delete config.options.presence;
      await writeFile(file, JSON.stringify(config));
      const result = await add(project, ['presence']);
      expect(result.code, result.err).toBe(0);
    });

    it('needs the application shell', async () => {
      const project = await createStarterProject(cwd, ['--app-shell', 'none']);
      const result = await add(project, ['presence']);
      expect(result.code).toBe(2);
      expect(result.err).toContain('requires the app shell: starter');
    });

    it('refuses to add it twice', async () => {
      const project = await createStarterProject(cwd, ['--presence', 'starter']);
      const result = await add(project, ['presence']);
      expect(result.code).toBe(2);
      expect(result.err).toContain('already');
    });

    it('leaves the project as it was when the user menu does not have the expected shape', async () => {
      const project = await createStarterProject(cwd);
      await writeFile(join(project, MENU), '<p>my own menu</p>\n');
      const result = await add(project, ['presence']);
      expect(result.code).not.toBe(0);
      expect(result.err).toContain('user-menu.html');
      expect(await exists(join(project, 'src/app/core/presence'))).toBe(false);
      expect((await readConfig(project)).presence).toBe('none');
      expect(await readFile(join(project, MENU), 'utf8')).toBe('<p>my own menu</p>\n');
    });

    it('shows the steps with --dry-run and changes nothing', async () => {
      const project = await createStarterProject(cwd);
      const result = await add(project, ['presence', '--dry-run']);
      expect(result.code).toBe(0);
      expect(result.out).toContain('Adding presence');
      expect(await exists(join(project, 'src/app/core/presence'))).toBe(false);
    });
  });

  describe('components in a project that has no architecture', () => {
    const PLAIN = [
      '--architecture',
      'angular-default',
      '--routing',
      'angular',
      '--components',
      'none',
      '--app-shell',
      'none',
      '--icons',
      'none',
    ];

    it('creates shared and core, adds the aliases, and leaves what the project has', async () => {
      const project = await createStarterProject(cwd, PLAIN);
      expect(await exists(join(project, 'src/app/shared'))).toBe(false);
      const result = await add(project, ['components', 'button']);
      expect(result.code, result.err).toBe(0);
      expect(await exists(join(project, 'src/app/shared/components/as-button/as-button.ts'))).toBe(
        true,
      );
      expect(await exists(join(project, 'src/app/core/theme/theme.service.ts'))).toBe(true);
      expect(await readFile(join(project, 'src/app/shared/components/index.ts'), 'utf8')).toContain(
        "as-button/as-button'",
      );
      const tsconfig = await readFile(join(project, 'tsconfig.json'), 'utf8');
      expect(tsconfig).toContain('"@shared/*"');
      expect(tsconfig).toContain('"@core/*"');
      expect(await exists(join(project, 'src/app/features'))).toBe(false);
      const config = await readConfig(project);
      expect(config).toMatchObject({ architecture: 'angular-default', components: 'custom' });
    });

    it('uses the shared folder the project already has, and adds to its barrel', async () => {
      const project = await createStarterProject(cwd, PLAIN);
      await mkdir(join(project, 'src/app/shared/components'), { recursive: true });
      await writeFile(
        join(project, 'src/app/shared/components/index.ts'),
        "export { Mine } from './mine/mine';\n",
      );
      const result = await add(project, ['components', 'button']);
      expect(result.code, result.err).toBe(0);
      const barrel = await readFile(join(project, 'src/app/shared/components/index.ts'), 'utf8');
      expect(barrel).toContain("export { Mine } from './mine/mine';");
      expect(barrel).toContain("as-button/as-button'");
    });

    it('keeps the aliases the project already has', async () => {
      const project = await createStarterProject(cwd, PLAIN);
      const tsconfig = await readFile(join(project, 'tsconfig.json'), 'utf8');
      await writeFile(
        join(project, 'tsconfig.json'),
        tsconfig.replace(
          '"module": "preserve"',
          '"module": "preserve", "paths": { "@shared/*": ["./src/app/shared/*"] }',
        ),
      );
      const result = await add(project, ['components', 'button']);
      expect(result.code, result.err).toBe(0);
      const text = await readFile(join(project, 'tsconfig.json'), 'utf8');
      expect(text.match(/"@shared\/\*"/g)).toHaveLength(1);
    });

    it('stops before writing when @shared points somewhere else', async () => {
      const project = await createStarterProject(cwd, PLAIN);
      const tsconfig = await readFile(join(project, 'tsconfig.json'), 'utf8');
      await writeFile(
        join(project, 'tsconfig.json'),
        tsconfig.replace(
          '"module": "preserve"',
          '"module": "preserve", "paths": { "@shared/*": ["./src/lib/*"] }',
        ),
      );
      const result = await add(project, ['components', 'button']);
      expect(result.code).toBe(2);
      expect(result.err).toContain('@shared');
      expect(await exists(join(project, 'src/app/shared'))).toBe(false);
    });
  });

  describe('components by id', () => {
    it('adds the components named, with what they import, and records a custom selection', async () => {
      const project = await createStarterProject(cwd, [
        '--components',
        'none',
        '--app-shell',
        'none',
        '--icons',
        'none',
      ]);
      const result = await add(project, ['components', 'modal,toggle']);
      expect(result.code, result.err).toBe(0);
      for (const id of ['modal', 'toggle', 'button', 'icon']) {
        expect(
          await exists(join(project, `src/app/shared/components/as-${id}/as-${id}.ts`)),
          id,
        ).toBe(true);
      }
      expect(await exists(join(project, 'src/app/shared/components/as-table/as-table.ts'))).toBe(
        false,
      );
      const config = await readConfig(project);
      expect(config.components).toBe('custom');
      expect(config.componentList).toEqual(['modal', 'toggle']);
    });

    it('adds to what the project has and records the union', async () => {
      const project = await createStarterProject(cwd, ['--components', 'recommended']);
      const result = await add(project, ['components', 'table']);
      expect(result.code, result.err).toBe(0);
      const config = await readConfig(project);
      expect(config.components).toBe('custom');
      expect(config.componentList).toHaveLength(17);
      expect(config.componentList).toContain('table');
      expect(await exists(join(project, 'src/app/shared/components/as-table/as-table.ts'))).toBe(
        true,
      );
    });

    it('says so when every component named is already there', async () => {
      const project = await createStarterProject(cwd, ['--components', 'recommended']);
      const result = await add(project, ['components', 'button,modal']);
      expect(result.code).toBe(2);
      expect(result.err).toContain('already');
    });

    it('refuses a name that is not a component', async () => {
      const project = await createStarterProject(cwd, [
        '--components',
        'none',
        '--app-shell',
        'none',
      ]);
      const result = await add(project, ['components', 'carousel']);
      expect(result.code).toBe(2);
      expect(result.err).toContain('"carousel"');
    });
  });

  describe('ui-system', () => {
    const TAB = 'src/app/features/preference-design/tabs/ui-tab.html';

    it('adds the catalog to the UI tab of the design preferences and records it', async () => {
      const project = await createStarterProject(cwd);
      const result = await add(project, ['ui-system']);
      expect(result.code, result.err).toBe(0);
      expect(result.out).toContain('✓ Adding the UI System');
      expect(
        await exists(join(project, 'src/app/features/preference-design/ui-system/ui-system.ts')),
      ).toBe(true);
      expect(await readFile(join(project, TAB), 'utf8')).toContain('<app-ui-system />');
      expect((await readConfig(project)).uiSystem).toBe('starter');
      expect(result.calls.some((call) => call.args.includes('install'))).toBe(false);
    });

    it('works on a project whose configuration was written before the UI System existed', async () => {
      const project = await createStarterProject(cwd);
      const file = join(project, 'angular-starter.config.json');
      const config = JSON.parse(await readFile(file, 'utf8'));
      for (const key of ['uiSystem', 'layout', 'ssrPurpose']) delete config.options[key];
      await writeFile(file, JSON.stringify(config));
      const result = await add(project, ['ui-system']);
      expect(result.code, result.err).toBe(0);
    });

    it('needs the shell and a component collection', async () => {
      const noShell = await createStarterProject(cwd, ['--app-shell', 'none']);
      const withoutShell = await add(noShell, ['ui-system']);
      expect(withoutShell.code).toBe(2);
      expect(withoutShell.err).toContain('requires the app shell: starter');

      await mkdir(join(cwd, 'other'));
      const noComponents = await createStarterProject(join(cwd, 'other'), ['--components', 'none']);
      const withoutComponents = await add(noComponents, ['ui-system']);
      expect(withoutComponents.code).toBe(2);
      expect(withoutComponents.err).toContain('the components: recommended, all');
    });

    it('refuses to add it twice', async () => {
      const project = await createStarterProject(cwd, ['--ui-system', 'starter']);
      const result = await add(project, ['ui-system']);
      expect(result.code).toBe(2);
      expect(result.err).toContain('already');
    });

    it('leaves the project as it was when the UI tab does not have the expected shape', async () => {
      const project = await createStarterProject(cwd);
      await writeFile(join(project, TAB), '<p>my own tab</p>\n');
      const result = await add(project, ['ui-system']);
      expect(result.code).not.toBe(0);
      expect(result.err).toContain('ui-tab.html');
      expect((await readConfig(project)).uiSystem).toBe('none');
      expect(await readFile(join(project, TAB), 'utf8')).toBe('<p>my own tab</p>\n');
    });

    it('shows the steps with --dry-run and changes nothing', async () => {
      const project = await createStarterProject(cwd);
      const result = await add(project, ['ui-system', '--dry-run']);
      expect(result.code).toBe(0);
      expect(result.out).toContain('Adding the UI System');
      expect(await readFile(join(project, TAB), 'utf8')).not.toContain('<app-ui-system />');
    });
  });

  describe('rendering', () => {
    it('adds Angular SSR with the official ng add and records it', async () => {
      const project = await createStarterProject(cwd, ['--app-shell', 'none']);
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
      const project = await createStarterProject(cwd, ['--app-shell', 'none']);
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
      expect(await exists(join(project, 'src/styles/theme/theme-styles.css'))).toBe(true);
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
      expect(result.calls).toContainEqual({
        command: 'npm',
        args: ['install', '--no-audit', '--no-fund', '--prefer-offline'],
        cwd: project,
      });
    });

    it('needs Tailwind CSS, the stylesheet the design is written in', async () => {
      const project = await createStarterProject(cwd, ['--style', 'scss']);
      const result = await add(project, ['components', 'recommended']);
      expect(result.code).toBe(2);
      expect(result.err).toContain('requires Tailwind CSS');
    });

    it('does not need an architecture: it is added to a project that has none', async () => {
      const project = await createStarterProject(cwd, ['--architecture', 'angular-default']);
      const result = await add(project, ['components', 'recommended']);
      expect(result.code, result.err).toBe(0);
      expect(await readConfig(project)).toMatchObject({
        architecture: 'angular-default',
        components: 'recommended',
      });
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
