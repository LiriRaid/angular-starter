import { mkdir, mkdtemp, readFile, rename, rm, stat, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { ANGULAR_CLI_VERSION } from '../src/compat.js';
import { ALL_COMPONENT_IDS, ESSENTIAL_COMPONENT_IDS } from '../src/config/components.js';
import { run } from '../src/main.js';
import { createFakeIo } from './helpers/fake-io.js';
import { createFakePrompter } from './helpers/fake-prompter.js';
import { createFakeRunner, type FakeRunnerOptions } from './helpers/fake-runner.js';
import { ANGULAR_README } from './helpers/generated-workspace.js';
import { SSR_APP_CONFIG, createStarterProject } from './helpers/starter-project.js';

let cwd: string;

beforeEach(async () => {
  cwd = await mkdtemp(join(tmpdir(), 'sa-add-'));
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
  JSON.parse(await readFile(join(project, 'starter-angular.config.json'), 'utf8')).options;

describe('sa add', () => {
  it('needs a project created by Starter Angular', async () => {
    const result = await add(cwd, ['icons', 'lucide']);
    expect(result.code).toBe(2);
    expect(result.err).toContain('starter-angular.config.json');
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
      'architecture',
    ]) {
      expect(result.err).toContain(name);
    }
  });

  it('says what only `sa new` can decide', async () => {
    const project = await createStarterProject(cwd);
    const result = await add(project, ['style', 'scss']);
    expect(result.code).toBe(2);
    expect(result.err).toContain('sa new');
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
      expect(result.err).toContain('sa add architecture screaming');
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
      expect(await exists(join(project, 'src/app/shared/components/sa-search/sa-search.ts'))).toBe(
        true,
      );
      expect(await exists(join(project, 'src/app/shared/components/sa-table'))).toBe(false);
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
      expect(result.err).toContain('sa add routing starter');
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
      expect(await exists(join(project, 'src/app/shared/components/sa-table/sa-table.ts'))).toBe(
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
      const file = join(project, 'starter-angular.config.json');
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
      expect(result.err).toContain('sa add app-shell starter');
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

  describe('architecture', () => {
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
    const WITH_COMPONENTS = [
      '--architecture',
      'angular-default',
      '--routing',
      'angular',
      '--app-shell',
      'none',
      '--components',
      'recommended',
      '--icons',
      'lucide',
    ];
    const read = (project: string, file: string): Promise<string> =>
      readFile(join(project, file), 'utf8');

    it('gives a project that is still what ng new generates the folders, the aliases and a clean root', async () => {
      const project = await createStarterProject(cwd, PLAIN);
      const result = await add(project, ['architecture', 'screaming']);
      expect(result.code, result.err).toBe(0);
      for (const folder of ['core', 'features', 'shared']) {
        expect(await exists(join(project, `src/app/${folder}/README.md`)), folder).toBe(true);
      }
      const tsconfig = await read(project, 'tsconfig.json');
      for (const alias of ['@core/*', '@features/*', '@shared/*']) {
        expect(tsconfig).toContain(`"${alias}"`);
      }
      const root = await read(project, 'src/app/app.ts');
      expect(root).toContain('<router-outlet />');
      expect(root).not.toContain('templateUrl');
      expect(await exists(join(project, 'src/app/app.html'))).toBe(false);
      expect(await exists(join(project, 'src/app/app.css'))).toBe(false);
      expect(await read(project, 'src/app/app.spec.ts')).not.toContain('should render title');
      expect(await exists(join(project, 'src/app/features/home'))).toBe(false);
      expect((await readConfig(project)).architecture).toBe('screaming');
    });

    it('says what it adapted and what to do next', async () => {
      const project = await createStarterProject(cwd, PLAIN);
      const result = await add(project, ['architecture', 'screaming']);
      expect(result.code, result.err).toBe(0);
      expect(result.out).toContain('src/app/app.ts');
      expect(result.out).toContain('sa generate feature');
      expect(result.out).toContain('sa add routing starter');
    });

    it('keeps the components the project already has and adds only what is missing', async () => {
      const project = await createStarterProject(cwd, WITH_COMPONENTS);
      const barrel = await read(project, 'src/app/shared/components/index.ts');
      const result = await add(project, ['architecture', 'screaming']);
      expect(result.code, result.err).toBe(0);
      expect(await read(project, 'src/app/shared/components/index.ts')).toBe(barrel);
      expect(await exists(join(project, 'src/app/shared/components/sa-button/sa-button.ts'))).toBe(
        true,
      );
      expect(await exists(join(project, 'src/app/features/README.md'))).toBe(true);
      expect(await read(project, 'tsconfig.json')).toContain('"@features/*"');
      expect((await readConfig(project)).components).toBe('recommended');
    });

    it('does not move, replace or refuse the code the project has, not even a features folder', async () => {
      const project = await createStarterProject(cwd, PLAIN);
      await mkdir(join(project, 'src/app/features/billing'), { recursive: true });
      await writeFile(
        join(project, 'src/app/features/billing/billing.ts'),
        'export const a = 1;\n',
      );
      await mkdir(join(project, 'src/app/orders'), { recursive: true });
      await writeFile(join(project, 'src/app/orders/orders.ts'), 'export const b = 2;\n');
      const result = await add(project, ['architecture', 'screaming']);
      expect(result.code, result.err).toBe(0);
      expect(await read(project, 'src/app/features/billing/billing.ts')).toBe(
        'export const a = 1;\n',
      );
      expect(await read(project, 'src/app/orders/orders.ts')).toBe('export const b = 2;\n');
      expect(await exists(join(project, 'src/app/features/README.md'))).toBe(true);
    });

    it('leaves a root component that was changed as it is and names it in a notice', async () => {
      const project = await createStarterProject(cwd, PLAIN);
      await writeFile(join(project, 'src/app/app.ts'), 'export const notAComponent = 1;\n');
      const result = await add(project, ['architecture', 'screaming']);
      expect(result.code, result.err).toBe(0);
      expect(await read(project, 'src/app/app.ts')).toBe('export const notAComponent = 1;\n');
      expect(await exists(join(project, 'src/app/app.html'))).toBe(true);
      expect(result.out).toContain('src/app/app.ts');
      expect(result.out).toMatch(/review|delete/i);
      expect((await readConfig(project)).architecture).toBe('screaming');
    });

    it('keeps a welcome template the developer changed, and says it is no longer used', async () => {
      const project = await createStarterProject(cwd, PLAIN);
      await writeFile(join(project, 'src/app/app.html'), '<h1>My own page</h1>\n');
      const result = await add(project, ['architecture', 'screaming']);
      expect(result.code, result.err).toBe(0);
      expect(await read(project, 'src/app/app.html')).toBe('<h1>My own page</h1>\n');
      expect(result.out).toContain('src/app/app.html');
    });

    it('stops, writing nothing, when an alias of the architecture points somewhere else', async () => {
      const project = await createStarterProject(cwd, PLAIN);
      const tsconfig = await read(project, 'tsconfig.json');
      await writeFile(
        join(project, 'tsconfig.json'),
        tsconfig.replace(
          '"compilerOptions": {',
          '"compilerOptions": { "baseUrl": ".", "paths": { "@features/*": ["./elsewhere/*"] },',
        ),
      );
      const result = await add(project, ['architecture', 'screaming']);
      expect(result.code).toBe(2);
      expect(result.err).toContain('@features/*');
      expect(await exists(join(project, 'src/app/features'))).toBe(false);
      expect((await readConfig(project)).architecture).toBe('angular-default');
    });

    it('lets sa generate feature work in the project afterwards', async () => {
      const project = await createStarterProject(cwd, PLAIN);
      expect((await add(project, ['architecture', 'screaming'])).code).toBe(0);
      const fake = createFakeIo({ cwd: project });
      const code = await run(['generate', 'feature', 'billing'], fake.io);
      expect(code, fake.err()).toBe(0);
      expect(await exists(join(project, 'src/app/features/billing/billing.ts'))).toBe(true);
    });

    it('refuses a project that already has it', async () => {
      const project = await createStarterProject(cwd);
      const result = await add(project, ['architecture', 'screaming']);
      expect(result.code).toBe(2);
      expect(result.err).toContain('already');
    });

    it('refuses an architecture that is only planned', async () => {
      const project = await createStarterProject(cwd, PLAIN);
      const result = await add(project, ['architecture', 'hexagonal']);
      expect(result.code).toBe(2);
      expect(result.err).toContain('hexagonal');
    });

    it('shows the steps with --dry-run and changes nothing', async () => {
      const project = await createStarterProject(cwd, PLAIN);
      const result = await add(project, ['architecture', 'screaming', '--dry-run']);
      expect(result.code).toBe(0);
      expect(result.out).toContain('Dry run');
      expect(await exists(join(project, 'src/app/features'))).toBe(false);
    });

    describe('in a terminal', () => {
      async function ask(project: string, answers: unknown[], extra: string[] = []) {
        const fake = createFakeIo({ cwd: project, interactive: true });
        const runner = createFakeRunner();
        const { prompter, asked } = createFakePrompter(answers);
        const code = await run(['add', 'architecture', 'screaming', ...extra], fake.io, {
          run: runner.run,
          prompter,
        });
        return { code, out: fake.out(), err: fake.err(), asked };
      }

      it('asks whether to add the routing and the app shell too, and stops there on a no', async () => {
        const project = await createStarterProject(cwd, PLAIN);
        const result = await ask(project, [false]);
        expect(result.code, result.err).toBe(0);
        expect(result.asked).toHaveLength(1);
        expect(result.asked[0]?.kind).toBe('confirm');
        const options = await readConfig(project);
        expect(options).toMatchObject({ architecture: 'screaming', routing: 'angular' });
        expect(options.appShell).toBe('none');
      });

      it('adds the Starter routing and the app shell on a yes', async () => {
        const project = await createStarterProject(cwd, PLAIN);
        const result = await ask(project, [true]);
        expect(result.code, result.err).toBe(0);
        expect(await readConfig(project)).toMatchObject({
          architecture: 'screaming',
          routing: 'starter',
          appShell: 'starter',
        });
      });

      it('does not ask in a dry run', async () => {
        const project = await createStarterProject(cwd, PLAIN);
        const result = await ask(project, [], ['--dry-run']);
        expect(result.code, result.err).toBe(0);
        expect(result.asked).toEqual([]);
      });
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
      expect(await exists(join(project, 'src/app/shared/components/sa-button/sa-button.ts'))).toBe(
        true,
      );
      expect(await exists(join(project, 'src/app/core/theme/theme.service.ts'))).toBe(true);
      expect(await readFile(join(project, 'src/app/shared/components/index.ts'), 'utf8')).toContain(
        "sa-button/sa-button'",
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
      expect(barrel).toContain("sa-button/sa-button'");
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
          await exists(join(project, `src/app/shared/components/sa-${id}/sa-${id}.ts`)),
          id,
        ).toBe(true);
      }
      expect(await exists(join(project, 'src/app/shared/components/sa-table/sa-table.ts'))).toBe(
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
      expect(await exists(join(project, 'src/app/shared/components/sa-table/sa-table.ts'))).toBe(
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
      const file = join(project, 'starter-angular.config.json');
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
      expect(withoutShell.err).toContain('sa add app-shell starter');

      await mkdir(join(cwd, 'other'));
      const noComponents = await createStarterProject(join(cwd, 'other'), ['--components', 'none']);
      const withoutComponents = await add(noComponents, ['ui-system']);
      expect(withoutComponents.code).toBe(2);
      expect(withoutComponents.err).toContain('sa add components');
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
      expect(result.out).toContain('✓ Applying Starter Angular SSR');
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
      expect(await exists(join(project, 'src/app/shared/components/sa-button/sa-button.ts'))).toBe(
        true,
      );
      expect(await readFile(join(project, 'src/app/shared/components/index.ts'), 'utf8')).toContain(
        'SaButton',
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

describe('sa add components when tsconfig.json extends another file', () => {
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

  async function extending(extendsValue: string, basePaths: Record<string, string[]>) {
    const project = await createStarterProject(cwd, PLAIN);
    await writeFile(
      join(project, 'tsconfig.base.json'),
      JSON.stringify({ compilerOptions: { paths: basePaths } }),
    );
    const tsconfig = await readFile(join(project, 'tsconfig.json'), 'utf8');
    await writeFile(
      join(project, 'tsconfig.json'),
      tsconfig.replace('{', `{ "extends": "${extendsValue}",`),
    );
    return project;
  }

  it('keeps the aliases it inherits: paths in the child replace the ones of the base', async () => {
    const project = await extending('./tsconfig.base.json', { '@app/*': ['./src/app/*'] });
    const result = await add(project, ['components', 'button']);
    expect(result.code, result.err).toBe(0);
    const text = await readFile(join(project, 'tsconfig.json'), 'utf8');
    for (const alias of ['@app/*', '@shared/*', '@core/*']) expect(text).toContain(`"${alias}"`);
  });

  it('stops and names the file when the base is outside the project folder', async () => {
    const project = await extending('../tsconfig.shared.json', {});
    const result = await add(project, ['components', 'button']);
    expect(result.code).toBe(2);
    expect(result.err).toContain('extends');
    expect(await exists(join(project, 'src/app/shared'))).toBe(false);
  });
});

describe('sa add: what it says about Lucide Icons', () => {
  const NO_ICONS = ['--components', 'none', '--icons', 'none'];

  it('warns, before the steps, that adding components installs Lucide Icons too, and why', async () => {
    const project = await createStarterProject(cwd, NO_ICONS);
    const result = await add(project, ['components', 'icon', '--dry-run']);
    expect(result.code, result.err).toBe(0);
    const notice = result.out.indexOf('Lucide Icons will be installed too');
    expect(notice).toBeGreaterThanOrEqual(0);
    expect(result.out).toContain('sa-icon');
    expect(notice).toBeLessThan(result.out.indexOf('Planned steps'));
  });

  it('says it when the components really are added, not only in a dry run', async () => {
    const project = await createStarterProject(cwd, NO_ICONS);
    const result = await add(project, ['components', 'button,modal']);
    expect(result.code, result.err).toBe(0);
    expect(result.out).toContain('Lucide Icons will be installed too');
  });

  it('warns when the app shell brings Lucide Icons, which it needs too', async () => {
    const project = await createStarterProject(cwd, ['--app-shell', 'none', ...NO_ICONS]);
    const result = await add(project, ['app-shell', '--dry-run']);
    expect(result.code, result.err).toBe(0);
    expect(result.out).toContain('Lucide Icons will be installed too');
  });

  it('keeps quiet when the project already has Lucide Icons', async () => {
    const project = await createStarterProject(cwd, ['--components', 'none', '--icons', 'lucide']);
    const result = await add(project, ['components', 'icon', '--dry-run']);
    expect(result.code, result.err).toBe(0);
    expect(result.out).not.toContain('Lucide Icons will be installed too');
  });

  it('suggests the sa-icon component when only Lucide Icons was added to a project with no components', async () => {
    const project = await createStarterProject(cwd, NO_ICONS);
    const result = await add(project, ['icons', 'lucide']);
    expect(result.code, result.err).toBe(0);
    expect(result.out).toContain('sa add components icon');
  });

  it('lists the components, not only the collections, when no value is given', async () => {
    const project = await createStarterProject(cwd, NO_ICONS);
    const result = await add(project, ['components']);
    expect(result.code).toBe(2);
    expect(result.err).toContain('recommended');
    expect(result.err).toContain('icon');
    expect(result.err).toContain('button');
    expect(result.err).toContain('datepicker');
  });
});

describe('sa add: the README of the project', () => {
  const README = (project: string): Promise<string> => readFile(join(project, 'README.md'), 'utf8');

  it('says what the project has after each addition, rewriting only its own block', async () => {
    const project = await createStarterProject(cwd, [
      '--components',
      'none',
      '--icons',
      'none',
      '--app-shell',
      'none',
    ]);
    expect(await README(project)).not.toContain('sa- components');
    const written = `${await README(project)}\n## Deploy\n\nWe deploy on Fridays.\n`;
    await writeFile(join(project, 'README.md'), written);

    const result = await add(project, ['components', 'icon,button']);
    expect(result.code, result.err).toBe(0);
    const after = await README(project);
    expect(after).toContain('`sa-` components');
    expect(after).toContain('We deploy on Fridays.');
    expect(after).toContain('**Icons**: Lucide Icons');
  });

  it('turns the README that ng new writes into a Starter Angular one the first time something is added', async () => {
    const project = await createStarterProject(cwd, ['--components', 'none', '--icons', 'none']);
    await writeFile(join(project, 'README.md'), ANGULAR_README);
    const result = await add(project, ['icons', 'lucide']);
    expect(result.code, result.err).toBe(0);
    const readme = await README(project);
    expect(readme).not.toContain('This project was generated using [Angular CLI]');
    expect(readme).toContain('Lucide Icons');
  });

  it('does not touch a README the developer wrote', async () => {
    const project = await createStarterProject(cwd, ['--components', 'none', '--icons', 'none']);
    const own = '# Our shop\n\nRun it with the script of Ana.\n';
    await writeFile(join(project, 'README.md'), own);
    const result = await add(project, ['icons', 'lucide']);
    expect(result.code, result.err).toBe(0);
    expect(await README(project)).toBe(own);
  });
});

describe('sa add with no value, in a terminal', () => {
  const NO_ICONS = ['--components', 'none', '--icons', 'none'];

  async function ask(project: string, args: string[], answers: unknown[]) {
    const fake = createFakeIo({ cwd: project, interactive: true });
    const runner = createFakeRunner();
    const { prompter, asked } = createFakePrompter(answers);
    const code = await run(['add', ...args], fake.io, { run: runner.run, prompter });
    return { code, out: fake.out(), err: fake.err(), asked };
  }

  it('shows a checklist of every component with the essential ones ticked', async () => {
    const project = await createStarterProject(cwd, NO_ICONS);
    const result = await ask(project, ['components'], [ESSENTIAL_COMPONENT_IDS]);
    expect(result.code, result.err).toBe(0);
    const [question] = result.asked;
    expect(question?.kind).toBe('checkbox');
    expect(question?.choices).toEqual([...ALL_COMPONENT_IDS]);
    expect(question?.names?.[0]).toBe('sa-icon (recommended)');
    expect(question?.checked).toEqual([...ESSENTIAL_COMPONENT_IDS]);
    expect(question?.disabled).toEqual({});
    expect(question?.descriptions?.every((text) => (text ?? '').length > 10)).toBe(true);
  });

  it('adds what was ticked and records it as the collection it equals', async () => {
    const project = await createStarterProject(cwd, NO_ICONS);
    const result = await ask(project, ['components'], [ESSENTIAL_COMPONENT_IDS]);
    expect(result.code, result.err).toBe(0);
    expect(result.out).toContain('Lucide Icons will be installed too');
    expect((await readConfig(project)).components).toBe('recommended');
    expect(await exists(join(project, 'src/app/shared/components/sa-button/sa-button.ts'))).toBe(
      true,
    );
  });

  it('records a different selection as a custom one', async () => {
    const project = await createStarterProject(cwd, NO_ICONS);
    const result = await ask(project, ['components'], [['icon', 'button']]);
    expect(result.code, result.err).toBe(0);
    expect(await readConfig(project)).toMatchObject({ components: 'custom', icons: 'lucide' });
  });

  it('lists every component, blocking the ones the project has and marking the recommended ones', async () => {
    const project = await createStarterProject(cwd);
    // A custom selection can have the UI System: it is offered, and declined here.
    const result = await ask(project, ['components'], [['table'], false]);
    expect(result.code, result.err).toBe(0);
    const [question] = result.asked;
    expect(question?.choices).toEqual([...ALL_COMPONENT_IDS]);
    // The shell brings search and the theme colour picker, which the recorded collection does not list.
    const installed = [...ESSENTIAL_COMPONENT_IDS, 'search', 'theme-color-picker'];
    expect(Object.keys(question?.disabled ?? {}).sort()).toEqual([...installed].sort());
    expect(new Set(Object.values(question?.disabled ?? {}))).toEqual(
      new Set(['(already in the project)']),
    );
    expect(question?.names).toContain('sa-button (recommended)');
    expect(question?.names).toContain('sa-table');
    expect(question?.names).not.toContain('sa-search (recommended)');
    // What the project has shows ticked and blocked; nothing else starts ticked.
    expect(question?.checked).toEqual(installed);
    expect(await exists(join(project, 'src/app/shared/components/sa-table/sa-table.ts'))).toBe(
      true,
    );
  });

  it('adds only what is not blocked, even when the answer holds a component the project has', async () => {
    const project = await createStarterProject(cwd);
    const result = await ask(project, ['components'], [['button', 'table'], false]);
    expect(result.code, result.err).toBe(0);
    expect(await exists(join(project, 'src/app/shared/components/sa-table/sa-table.ts'))).toBe(
      true,
    );
    const { componentList } = await readConfig(project);
    expect(componentList).toContain('table');
    expect(new Set(componentList).size).toBe(componentList.length);
  });

  it('stops when nothing is ticked', async () => {
    const project = await createStarterProject(cwd, NO_ICONS);
    const result = await ask(project, ['components'], [[]]);
    expect(result.code).toBe(2);
    expect(result.err).toContain('No component was ticked');
  });

  it('says so when the project already has every component', async () => {
    const project = await createStarterProject(cwd, ['--components', 'all']);
    const result = await ask(project, ['components'], []);
    expect(result.code).toBe(2);
    expect(result.err).toContain('already has every component');
    expect(result.asked).toEqual([]);
  });

  it('shows a selector for the rendering and adds what is chosen', async () => {
    const project = await createStarterProject(cwd, ['--app-shell', 'none']);
    const result = await ask(project, ['rendering'], ['ssr']);
    expect(result.code, result.err).toBe(0);
    const [question] = result.asked;
    expect(question?.kind).toBe('select');
    expect(question?.choices).toEqual(['ssr', 'starter-ssr']);
    expect(question?.descriptions?.every((text) => (text ?? '').length > 10)).toBe(true);
    expect((await readConfig(project)).rendering).toBe('ssr');
  });

  it('asks nothing when the value is given', async () => {
    const project = await createStarterProject(cwd, NO_ICONS);
    const result = await ask(project, ['components', 'icon'], []);
    expect(result.code, result.err).toBe(0);
    expect(result.asked).toEqual([]);
  });

  it('asks nothing for a capability that has a single option', async () => {
    const project = await createStarterProject(cwd, ['--icons', 'none']);
    const result = await ask(project, ['icons'], []);
    expect(result.code, result.err).toBe(0);
    expect(result.asked).toEqual([]);
  });
});

describe('sa add: what a capability needs and what it offers next', () => {
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

  async function ask(project: string, args: string[], answers: unknown[]) {
    const fake = createFakeIo({ cwd: project, interactive: true });
    const runner = createFakeRunner();
    const { prompter, asked } = createFakePrompter(answers);
    const code = await run(['add', ...args], fake.io, { run: runner.run, prompter });
    return { code, out: fake.out(), err: fake.err(), asked };
  }

  it('lists the architectures in a terminal, the planned ones not selectable', async () => {
    const project = await createStarterProject(cwd, PLAIN);
    const result = await ask(project, ['architecture'], ['screaming', false]);
    expect(result.code, result.err).toBe(0);
    const [question] = result.asked;
    expect(question?.kind).toBe('select');
    expect(question?.choices).toContain('screaming');
    expect(question?.choices).toContain('modular');
    expect(question?.choices).not.toContain('angular-default');
    expect(question?.disabled?.['screaming']).toBeUndefined();
    expect(question?.disabled?.['modular']).toBeDefined();
    expect((await readConfig(project)).architecture).toBe('screaming');
  });

  it('does not ask which architecture when the project already has one', async () => {
    const project = await createStarterProject(cwd);
    const result = await ask(project, ['architecture'], []);
    expect(result.code).toBe(2);
    expect(result.err).toContain('already');
    expect(result.asked).toEqual([]);
  });

  // An Angular project that chose its components, but nothing else of the starter.
  const WITH_COMPONENTS = [
    '--architecture',
    'angular-default',
    '--routing',
    'angular',
    '--components',
    'recommended',
    '--icons',
    'lucide',
    '--app-shell',
    'none',
  ];

  it('asks to add what the UI System needs, says what, and adds it in order', async () => {
    const project = await createStarterProject(cwd, WITH_COMPONENTS);
    const result = await ask(project, ['ui-system'], [true]);
    expect(result.code, result.err).toBe(0);
    expect(result.asked).toHaveLength(1);
    expect(result.asked[0]?.kind).toBe('confirm');
    expect(result.asked[0]?.message).toMatch(/architecture/i);
    expect(await readConfig(project)).toMatchObject({
      architecture: 'screaming',
      routing: 'starter',
      appShell: 'starter',
      components: 'recommended',
      uiSystem: 'starter',
    });
  });

  it('changes nothing when the developer says no to what it needs', async () => {
    const project = await createStarterProject(cwd, WITH_COMPONENTS);
    const result = await ask(project, ['ui-system'], [false]);
    expect(result.code, result.err).toBe(0);
    expect(await readConfig(project)).toMatchObject({
      architecture: 'angular-default',
      uiSystem: 'none',
    });
  });

  it('stops outside a terminal and names the commands to run first', async () => {
    const project = await createStarterProject(cwd, WITH_COMPONENTS);
    const result = await add(project, ['ui-system']);
    expect(result.code).toBe(2);
    expect(result.err).toContain('sa add architecture screaming');
    expect(result.err).toContain('sa add app-shell');
  });

  it('shows the whole chain in a dry run and changes nothing', async () => {
    const project = await createStarterProject(cwd, WITH_COMPONENTS);
    const result = await add(project, ['ui-system', '--dry-run']);
    expect(result.code, result.err).toBe(0);
    expect(result.out).toContain('architecture');
    expect(result.out).toContain('app-shell');
    expect((await readConfig(project)).architecture).toBe('angular-default');
  });

  it('never adds the components on its own: without them it stops, asks nothing and says what to run', async () => {
    const project = await createStarterProject(cwd, PLAIN);
    const result = await ask(project, ['ui-system'], []);
    expect(result.code).toBe(2);
    expect(result.asked).toEqual([]);
    expect(result.err).toContain('sa add components');
    expect(result.err).not.toContain('sa add app-shell');
    expect(await readConfig(project)).toMatchObject({
      architecture: 'angular-default',
      components: 'none',
      uiSystem: 'none',
    });
  });

  it('does the same in a dry run and outside a terminal', async () => {
    const project = await createStarterProject(cwd, PLAIN);
    for (const args of [['ui-system'], ['ui-system', '--dry-run']]) {
      const result = await add(project, args);
      expect(result.code, args.join(' ')).toBe(2);
      expect(result.err).toContain('sa add components');
    }
  });

  it('does not count the components of the shell as a collection the developer chose', async () => {
    const project = await createStarterProject(cwd, ['--components', 'none']);
    const result = await ask(project, ['ui-system'], []);
    expect(result.code).toBe(2);
    expect(result.err).toContain('sa add components');
    expect(result.asked).toEqual([]);
    expect((await readConfig(project)).uiSystem).toBe('none');
  });

  it('brings the components it draws with when they are not in the project, and says so', async () => {
    const project = await createStarterProject(cwd, ['--components', 'modal,tabs']);
    const shared = join(project, 'src/app/shared/components');
    await rm(join(shared, 'sa-toggle'), { recursive: true });
    const result = await add(project, ['ui-system']);
    expect(result.code, result.err).toBe(0);
    expect(result.out).toContain('sa-toggle will be installed too');
    expect(await exists(join(shared, 'sa-toggle/sa-toggle.ts'))).toBe(true);
    expect((await readConfig(project)).uiSystem).toBe('starter');
  });

  it('does not say it when the shell already brought them', async () => {
    const project = await createStarterProject(cwd, ['--components', 'modal,tabs']);
    const result = await add(project, ['ui-system']);
    expect(result.code, result.err).toBe(0);
    expect(result.out).not.toContain('will be installed too');
  });

  it('offers the UI System after the components when the project has the shell', async () => {
    const project = await createStarterProject(cwd, ['--components', 'none']);
    const result = await ask(project, ['components', 'recommended'], [true]);
    expect(result.code, result.err).toBe(0);
    expect(result.asked[0]?.kind).toBe('confirm');
    expect((await readConfig(project)).uiSystem).toBe('starter');
  });

  it('offers the UI System after the app shell when the project has the components', async () => {
    const project = await createStarterProject(cwd, ['--app-shell', 'none']);
    const accepted = await ask(project, ['app-shell'], [false]);
    expect(accepted.code, accepted.err).toBe(0);
    expect(accepted.asked[0]?.kind).toBe('confirm');
    expect((await readConfig(project)).uiSystem).toBe('none');
  });

  describe('completing the UI System catalog when more components arrive', () => {
    const CATALOG = 'src/app/features/preference-design/ui-system/ui-system.catalog.ts';
    const FEW = ['--components', 'modal', '--ui-system', 'starter'];
    const catalogOf = (project: string): Promise<string> =>
      readFile(join(project, CATALOG), 'utf8');

    it('only suggests it outside a terminal, naming the components and the command', async () => {
      const project = await createStarterProject(cwd, FEW);
      expect(await catalogOf(project)).not.toContain("id: 'table'");
      const result = await add(project, ['components', 'table']);
      expect(result.code, result.err).toBe(0);
      expect(result.out).toContain('Next: "sa add ui-system"');
      expect(result.out).toContain('sa-table');
      expect(await catalogOf(project)).not.toContain("id: 'table'");
    });

    it('asks in a terminal, with yes as the answer by default, and completes the catalog', async () => {
      const project = await createStarterProject(cwd, FEW);
      const result = await ask(project, ['components', 'table'], [true]);
      expect(result.code, result.err).toBe(0);
      const [question] = result.asked;
      expect(question?.kind).toBe('confirm');
      expect(question?.default).toBe(true);
      expect(question?.message).toContain('sa-table');
      expect(await catalogOf(project)).toContain("id: 'table'");
      expect(result.out).toContain('The UI System catalog now shows');
    });

    it('leaves the catalog as it is when the developer says no', async () => {
      const project = await createStarterProject(cwd, FEW);
      const result = await ask(project, ['components', 'table'], [false]);
      expect(result.code, result.err).toBe(0);
      expect(await catalogOf(project)).not.toContain("id: 'table'");
    });

    it('does not ask when the catalog already shows what the project has', async () => {
      const project = await createStarterProject(cwd, [
        '--components',
        'all',
        '--ui-system',
        'starter',
      ]);
      const result = await ask(project, ['components', 'button'], []);
      expect(result.code).toBe(2);
      expect(result.asked).toEqual([]);
    });

    it('is what "sa add ui-system" does in a project that has it', async () => {
      const project = await createStarterProject(cwd, FEW);
      await add(project, ['components', 'table']);
      const result = await add(project, ['ui-system']);
      expect(result.code, result.err).toBe(0);
      expect(result.out).toContain('The UI System catalog now shows');
      expect(await catalogOf(project)).toContain("id: 'table'");
      const again = await add(project, ['ui-system']);
      expect(again.code).toBe(2);
      expect(again.err).toContain('already');
    });

    it('shows the step with --dry-run and changes nothing', async () => {
      const project = await createStarterProject(cwd, FEW);
      await add(project, ['components', 'table']);
      const result = await add(project, ['ui-system', '--dry-run']);
      expect(result.code, result.err).toBe(0);
      expect(result.out).toContain('Completing the UI System catalog');
      expect(await catalogOf(project)).not.toContain("id: 'table'");
    });

    it('warns and changes nothing when the developer edited the catalog', async () => {
      const project = await createStarterProject(cwd, FEW);
      await add(project, ['components', 'table']);
      const edited = `${await catalogOf(project)}
// mine
`;
      await writeFile(join(project, CATALOG), edited);
      const result = await add(project, ['ui-system']);
      expect(result.code, result.err).toBe(0);
      expect(result.out).toContain('ui-system.catalog.ts');
      expect(result.out).toContain('sa-table');
      expect(await catalogOf(project)).toBe(edited);
    });
  });

  it('only suggests the UI System outside a terminal', async () => {
    const project = await createStarterProject(cwd, ['--app-shell', 'none']);
    const result = await add(project, ['app-shell']);
    expect(result.code, result.err).toBe(0);
    expect(result.out).toContain('sa add ui-system');
  });

  it('names the project after its folder, as typed, and not after the package', async () => {
    const created = await createStarterProject(cwd, PLAIN);
    const project = join(cwd, 'MyShopApp');
    await rename(created, project);
    const manifest = JSON.parse(await readFile(join(project, 'package.json'), 'utf8'));
    await writeFile(
      join(project, 'package.json'),
      JSON.stringify({ ...manifest, name: 'my-shop-app' }),
    );
    expect((await add(project, ['architecture', 'screaming'])).code).toBe(0);
    expect((await add(project, ['routing', 'starter'])).code).toBe(0);
    const config = await readFile(join(project, 'src/app/app.config.ts'), 'utf8');
    expect(config).toContain("appName: 'MyShopApp'");
    expect(config).not.toContain('my-shop-app');
  });
});
