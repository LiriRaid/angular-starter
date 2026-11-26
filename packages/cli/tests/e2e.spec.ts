import { existsSync } from 'node:fs';
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execa } from 'execa';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';

/**
 * Runs the compiled CLI against the real Angular CLI (needs network and a prior `pnpm build`).
 * Opt in with SA_E2E=1.
 *
 * Every project that is installed costs minutes, so there are few of them and each covers a family
 * of the options (ADR-0016); the other combinations are covered by the unit specs of the engine.
 * The projects install with pnpm: its store makes every install after the first a matter of links.
 */
const enabled = process.env['SA_E2E'] === '1';
const bin = fileURLToPath(new URL('../dist/bin.js', import.meta.url));
const TIMEOUT_MS = 5 * 60_000;
const INSTALL_TIMEOUT_MS = 15 * 60_000;
const CLEANUP_TIMEOUT_MS = 10 * 60_000;
const CHILD_ENV = { CI: '1' };

describe.skipIf(!enabled)('sa new (end to end, real Angular CLI)', () => {
  let cwd: string;

  beforeAll(async () => {
    expect(existsSync(bin), 'Run "pnpm build" first: dist/bin.js is missing.').toBe(true);
    cwd = await mkdtemp(join(tmpdir(), 'sa-e2e-'));
  });

  // Deleting two installed projects (node_modules) takes longer than the default hook timeout.
  afterAll(async () => {
    await rm(cwd, { recursive: true, force: true });
  }, CLEANUP_TIMEOUT_MS);

  async function create(name: string, ...flags: string[]) {
    const result = await execa(
      'node',
      [bin, 'new', name, '--defaults', '--no-install', '--no-git', ...flags],
      { cwd, reject: false, env: CHILD_ENV, extendEnv: true },
    );
    expect(result.exitCode, `${result.stdout}\n${result.stderr}`).toBe(0);
    return join(cwd, name);
  }

  /** Creates a project with its dependencies installed, so that it can be built and tested. */
  async function createInstalled(name: string, ...flags: string[]) {
    const result = await execa(
      'node',
      [bin, 'new', name, '--defaults', '--no-git', '--package-manager', 'pnpm', ...flags],
      { cwd, reject: false, env: CHILD_ENV, extendEnv: true },
    );
    expect(
      result.exitCode,
      `${result.stdout}
${result.stderr}`,
    ).toBe(0);
    // CI mode makes pnpm freeze the lockfile, and `ng add` installs on its own after a command changed
    // package.json: the project says so for itself, in the file where pnpm reads its settings.
    const workspace = join(cwd, name, 'pnpm-workspace.yaml');
    if (existsSync(workspace)) {
      await writeFile(workspace, `${await readFile(workspace, 'utf8')}\nfrozenLockfile: false\n`);
    }
    return join(cwd, name);
  }

  /** Runs the compiled CLI inside an existing project, as a person would. */
  async function asProject(project: string, ...args: string[]) {
    const result = await execa('node', [bin, ...args], {
      cwd: project,
      reject: false,
      env: CHILD_ENV,
      extendEnv: true,
    });
    expect(
      result.exitCode,
      `sa ${args.join(' ')}
${result.stdout}
${result.stderr}`,
    ).toBe(0);
  }

  async function ng(project: string, ...args: string[]) {
    // Each project runs the Angular CLI through its own package manager (pnpm refuses to run in an npm one).
    const npm = existsSync(join(project, 'package-lock.json'));
    const result = await execa(
      npm ? 'npx' : 'pnpm',
      npm ? ['--no-install', 'ng', ...args] : ['exec', 'ng', ...args],
      { cwd: project, reject: false, env: CHILD_ENV, extendEnv: true },
    );
    expect(
      result.exitCode,
      `ng ${args.join(' ')}
${result.stdout}
${result.stderr}`,
    ).toBe(0);
  }

  /** Runs a script of the project through its package manager and fails when it does not pass. */
  async function script(project: string, name: string) {
    const npm = existsSync(join(project, 'package-lock.json'));
    const result = await execa(npm ? 'npm' : 'pnpm', ['run', name], {
      cwd: project,
      reject: false,
      env: CHILD_ENV,
      extendEnv: true,
    });
    expect(
      result.exitCode,
      `${name}
${result.stdout}
${result.stderr}`,
    ).toBe(0);
  }

  /** Builds the application for production and fails on any budget warning, which the build prints without failing. */
  async function buildWithinBudgets(project: string) {
    const npm = existsSync(join(project, 'package-lock.json'));
    const result = await execa(
      npm ? 'npx' : 'pnpm',
      npm ? ['--no-install', 'ng', 'build'] : ['exec', 'ng', 'build'],
      { cwd: project, reject: false, env: CHILD_ENV, extendEnv: true },
    );
    const output = `${result.stdout}
${result.stderr}`;
    expect(result.exitCode, output).toBe(0);
    expect(output, 'the build exceeded a budget').not.toMatch(
      /exceeded maximum budget|bundle initial exceeded/i,
    );
  }

  const read = (project: string, file: string): Promise<string> =>
    readFile(join(project, file), 'utf8');

  it(
    'creates a CSS + Tailwind application with the default options',
    async () => {
      const project = await create('e2e-tailwind');
      expect(existsSync(join(project, 'starter-angular.config.json'))).toBe(true);
      expect(existsSync(join(project, 'src', 'main.ts'))).toBe(true);
      const manifest = await read(project, 'package.json');
      expect(manifest).toContain('tailwindcss');
      // Zoneless is the Angular 22 default: the app has no zone.js at all.
      expect(manifest).not.toContain('zone.js');
      // Lint and format come with every project (ADR-0027).
      expect(existsSync(join(project, 'eslint.config.mjs'))).toBe(true);
      expect(manifest).toContain('angular-eslint');
      expect(manifest).toContain('"format:check"');
    },
    TIMEOUT_MS,
  );

  it(
    'creates an SCSS application without Tailwind and records the options',
    async () => {
      const project = await create('e2e-scss', '--style', 'scss', '--prefix', 'acme');
      expect(existsSync(join(project, 'src', 'styles.scss'))).toBe(true);
      expect(await read(project, 'package.json')).not.toContain('tailwindcss');
      const config = JSON.parse(await read(project, 'starter-angular.config.json'));
      expect(config.options).toMatchObject({ style: 'scss', tailwind: false, prefix: 'acme' });
      expect(await read(project, 'angular.json')).toContain('"prefix": "acme"');
    },
    TIMEOUT_MS,
  );

  it(
    'creates an application with the default Angular SSR setup',
    async () => {
      const project = await create('e2e-ssr', '--rendering', 'ssr');
      expect(existsSync(join(project, 'src', 'main.server.ts'))).toBe(true);
    },
    TIMEOUT_MS,
  );

  it(
    'creates a Screaming project with the Starter Angular routing and the default Angular SSR that builds',
    async () => {
      const project = await createInstalled(
        'e2e-routing-ssr',
        '--architecture',
        'screaming',
        '--routing',
        'starter',
        '--rendering',
        'ssr',
        '--app-shell',
        'none',
      );

      for (const file of [
        'src/app/core/README.md',
        'src/app/core/navigation/breadcrumb.service.ts',
        'src/app/core/navigation/navigation-title.strategy.ts',
        'src/app/features/app-shell/navigation/navigation.data.ts',
        'src/main.server.ts',
      ]) {
        expect(existsSync(join(project, file)), file).toBe(true);
      }
      expect(await read(project, 'tsconfig.json')).toContain('"@features/*"');
      expect(await read(project, 'src/app/app.config.ts')).toContain(
        `provideNavigation(APP_NAVIGATION, { appName: 'e2e-routing-ssr' })`,
      );
      const config = JSON.parse(await read(project, 'starter-angular.config.json'));
      expect(config.options).toMatchObject({ architecture: 'screaming', routing: 'starter' });

      await ng(project, 'build');
    },
    INSTALL_TIMEOUT_MS,
  );

  it(
    'adds routing, icons, SSR and components to an existing project and generates a feature that build and test',
    async () => {
      const project = await createInstalled(
        'e2e-add',
        '--architecture',
        'screaming',
        '--routing',
        'angular',
        '--icons',
        'none',
        '--components',
        'none',
      );
      await asProject(project, 'add', 'routing', 'starter');
      await asProject(project, 'add', 'icons', 'lucide');
      await asProject(project, 'generate', 'feature', 'billing');
      await asProject(project, 'generate', 'component', 'invoice-card', '--feature', 'billing');
      await asProject(project, 'add', 'rendering', 'starter-ssr');
      await asProject(project, 'add', 'components', 'recommended');

      const config = JSON.parse(await read(project, 'starter-angular.config.json'));
      expect(config.options).toMatchObject({
        routing: 'starter',
        icons: 'lucide',
        rendering: 'starter-ssr',
        components: 'recommended',
      });
      expect(existsSync(join(project, 'src/app/shared/components/sa-button/sa-button.ts'))).toBe(
        true,
      );
      expect(await read(project, 'src/styles.css')).toContain('button-styles.css');
      expect(await read(project, 'src/app/app.config.ts')).toContain('withIncrementalHydration()');
      expect(
        existsSync(join(project, 'src/app/features/billing/invoice-card/invoice-card.ts')),
      ).toBe(true);
      expect(
        await read(project, 'src/app/features/app-shell/navigation/navigation.data.ts'),
      ).toContain("id: 'billing'");

      await ng(project, 'build');
      await ng(project, 'test', '--watch=false');
    },
    INSTALL_TIMEOUT_MS,
  );

  it(
    'creates the recommended project: Screaming, routing, Tailwind CSS, Lucide, the components and the App Shell',
    async () => {
      const project = await createInstalled('e2e-recommended');
      for (const file of [
        'src/styles/theme/theme-styles.css',
        'src/styles/typography/typography-styles.css',
        'src/styles/components/button-styles.css',
        'src/app/shared/animations/animations.css',
        'src/test-setup.ts',
        'src/app/core/theme/theme.service.ts',
        'src/app/core/common/icons/lucide-icons.ts',
        'src/app/shared/components/sa-button/sa-button.ts',
        'src/app/shared/components/sa-modal/sa-modal.ts',
        'src/app/shared/utils/slugify.ts',
      ]) {
        expect(existsSync(join(project, file)), file).toBe(true);
      }
      // The root is composed in app.ts: no welcome page of Angular is left.
      expect(existsSync(join(project, 'src/app/app.html'))).toBe(false);
      expect(await read(project, 'src/app/app.ts')).toContain("template: '<router-outlet />'");
      // The design is imported from styles.css, as in the reference, not registered in angular.json.
      const styles = await read(project, 'src/styles.css');
      expect(styles).toContain("@import './styles/theme/theme-styles.css';");
      expect(styles).toContain('@layer base, components, legacy-overrides, utilities;');
      expect(await read(project, 'angular.json')).not.toContain('theme-styles');
      expect(await read(project, 'angular.json')).toContain('src/test-setup.ts');
      // The Lucide package is a dependency and is installed.
      expect(
        JSON.parse(await read(project, 'package.json')).dependencies['@lucide/angular'],
      ).toMatch(/^\^1\./);
      expect(existsSync(join(project, 'node_modules', '@lucide', 'angular'))).toBe(true);

      // The App Shell: layout, sidebar, header and breadcrumb, the example pages and their routes.
      for (const file of [
        'src/app/features/app-shell/layout/main/main.ts',
        'src/app/features/app-shell/layout/sidebar/sidebar.ts',
        'src/app/features/app-shell/layout/header/header.ts',
        'src/app/features/app-shell/components/breadcrumb/breadcrumb.ts',
        'src/styles/features/sidebar-styles.css',
        'src/app/features/dashboard/dashboard.ts',
        'src/app/features/settings/general/settings-general.ts',
      ]) {
        expect(existsSync(join(project, file)), file).toBe(true);
      }
      expect(await read(project, 'src/app/app.ts')).toContain('provideLayout(APP_NAVIGATION');
      expect(await read(project, 'src/app/app.routes.ts')).toContain(
        "import('@features/app-shell/layout/main/main')",
      );

      // Lint and format work out of the box on everything the starter generated (ADR-0027).
      await script(project, 'lint');
      await script(project, 'format:check');

      await ng(project, 'build');
      await ng(project, 'test', '--watch=false');
    },
    INSTALL_TIMEOUT_MS,
  );

  it(
    'creates a project with every component and the Starter SSR with incremental hydration that builds and passes its tests',
    async () => {
      const project = await createInstalled(
        'e2e-all-components',
        '--components',
        'all',
        '--rendering',
        'starter-ssr',
        '--app-shell',
        'none',
      );
      expect(await read(project, 'package.json')).toContain('@angular/cdk');
      expect(await read(project, 'src/styles.css')).toContain('table-styles.css');
      for (const file of [
        'src/app/shared/components/sa-table/sa-table.ts',
        'src/app/shared/components/sa-datepicker/sa-datepicker.ts',
        'src/app/shared/components/sa-theme-color-picker/sa-theme-color-picker.ts',
        'src/app/shared/components/sa-weekly-schedule/sa-weekly-schedule.ts',
        'src/app/features/home/home-details/home-details.ts',
        'src/main.server.ts',
      ]) {
        expect(existsSync(join(project, file)), file).toBe(true);
      }
      expect(await read(project, 'src/app/app.config.ts')).toContain('withIncrementalHydration()');
      expect(await read(project, 'src/app/features/home/home.html')).toContain(
        '@defer (hydrate on viewport)',
      );

      await script(project, 'lint');
      await script(project, 'format:check');
      await ng(project, 'build');
      // sa test runs the same ng test, from the CLI that created the project.
      await asProject(project, 'test', '--watch=false');
    },
    INSTALL_TIMEOUT_MS,
  );

  it(
    'gives a default Angular project that already has components the Screaming structure, then a feature, the routing and the shell, and it builds and passes its tests',
    async () => {
      const project = await createInstalled(
        'e2e-add-architecture',
        '--architecture',
        'angular-default',
        '--routing',
        'angular',
        '--app-shell',
        'none',
        '--components',
        'none',
        '--icons',
        'none',
      );
      await asProject(project, 'add', 'components', 'recommended');
      const barrel = await read(project, 'src/app/shared/components/index.ts');
      await asProject(project, 'add', 'architecture', 'screaming');
      // The components the project had stay exactly where they were.
      expect(await read(project, 'src/app/shared/components/index.ts')).toBe(barrel);
      expect(existsSync(join(project, 'src/app/features/README.md'))).toBe(true);
      expect(existsSync(join(project, 'src/app/app.html'))).toBe(false);
      await ng(project, 'build');

      await asProject(project, 'generate', 'feature', 'billing');
      await asProject(project, 'add', 'routing', 'starter');
      await asProject(project, 'add', 'app-shell');
      await asProject(project, 'add', 'ui-system');
      const config = JSON.parse(await read(project, 'starter-angular.config.json'));
      expect(config.options).toMatchObject({
        architecture: 'screaming',
        components: 'recommended',
        icons: 'lucide',
        routing: 'starter',
        appShell: 'starter',
        uiSystem: 'starter',
      });
      expect(existsSync(join(project, 'src/app/features/billing/billing.ts'))).toBe(true);

      await ng(project, 'build');
      await ng(project, 'test', '--watch=false');
    },
    INSTALL_TIMEOUT_MS,
  );

  it(
    'adds the App Shell, the components, presence and the UI System to an existing project that builds and passes its tests',
    async () => {
      const project = await createInstalled(
        'e2e-add-shell',
        '--app-shell',
        'none',
        '--components',
        'none',
        '--icons',
        'none',
      );
      await asProject(project, 'add', 'app-shell');
      await asProject(project, 'generate', 'feature', 'billing');
      await asProject(project, 'add', 'components', 'all');
      await asProject(project, 'add', 'presence');
      await asProject(project, 'add', 'ui-system');

      const config = JSON.parse(await read(project, 'starter-angular.config.json'));
      expect(config.options).toMatchObject({
        appShell: 'starter',
        icons: 'lucide',
        components: 'all',
        presence: 'starter',
        uiSystem: 'starter',
      });
      const routes = await read(project, 'src/app/app.routes.ts');
      expect(routes.indexOf("path: 'billing'")).toBeGreaterThan(routes.indexOf('children: ['));
      expect(existsSync(join(project, 'src/app/shared/components/sa-table/sa-table.ts'))).toBe(
        true,
      );
      expect(
        await read(project, 'src/app/features/app-shell/layout/sidebar/user-menu/user-menu.html'),
      ).toContain('um-status-trigger');

      await ng(project, 'build');
      await ng(project, 'test', '--watch=false');
    },
    INSTALL_TIMEOUT_MS,
  );

  it(
    'creates a project with presence, the welcome home with its documentation and the UI System that builds and passes its tests',
    async () => {
      const project = await createInstalled(
        'e2e-presence-ui-system',
        '--presence',
        'starter',
        '--ui-system',
        'starter',
      );
      for (const file of [
        'src/app/core/presence/presence.service.ts',
        'src/app/core/presence/web-socket-presence.transport.ts',
        'src/app/features/app-shell/layout/sidebar/user-menu/user-status.ts',
        'src/styles/features/presence-styles.css',
        'docs/presence.md',
        'src/app/core/theme/README.md',
        'src/app/shared/components/README.md',
        'src/styles/README.md',
        'src/app/features/docs/docs.ts',
        'src/app/features/preference-design/preference-design.ts',
        'src/app/features/preference-design/ui-system/ui-system.catalog.ts',
        'src/app/core/design-preferences/design-preferences.service.ts',
        'src/styles/features/design-preferences-styles.css',
      ]) {
        expect(existsSync(join(project, file)), file).toBe(true);
      }
      const appConfig = await read(project, 'src/app/app.config.ts');
      expect(appConfig).toContain('providePresence()');
      expect(appConfig).toContain('provideDesignPreferences()');
      expect(await read(project, 'src/app/features/home/home.html')).toContain(
        '@for (card of cards',
      );
      expect(await read(project, 'src/app/features/home/home.data.ts')).toContain("id: 'presence'");
      expect(await read(project, 'src/app/features/preference-design/tabs/ui-tab.html')).toContain(
        '<app-ui-system />',
      );
      const config = JSON.parse(await read(project, 'starter-angular.config.json'));
      expect(config.options).toMatchObject({
        presence: 'starter',
        uiSystem: 'starter',
        layout: 'floating-wide',
      });

      await buildWithinBudgets(project);
      await ng(project, 'test', '--watch=false');
    },
    INSTALL_TIMEOUT_MS,
  );

  it(
    'creates the default Angular structure as plain Angular: no Lucide, no shell, no layout',
    async () => {
      const project = await createInstalled('e2e-plain', '--architecture', 'angular-default');
      const config = JSON.parse(await read(project, 'starter-angular.config.json'));
      expect(config.options).toMatchObject({
        icons: 'none',
        appShell: 'none',
        layout: 'none',
        uiSystem: 'none',
        ssrPurpose: 'none',
      });
      expect(await read(project, 'package.json')).not.toContain('lucide');
      expect(existsSync(join(project, 'src/app/features'))).toBe(false);

      await ng(project, 'build');
      await ng(project, 'test', '--watch=false');
    },
    INSTALL_TIMEOUT_MS,
  );

  it(
    'sets up a default Angular project that sa new did not make, and adds components and a component to it',
    async () => {
      const project = await createInstalled(
        'e2e-adopt',
        '--architecture',
        'angular-default',
        '--routing',
        'angular',
        '--app-shell',
        'none',
        '--components',
        'none',
        '--icons',
        'none',
      );
      // From here on the project is one the CLI knows nothing about.
      await rm(join(project, 'starter-angular.config.json'));

      await asProject(project, 'init');
      await asProject(project, 'add', 'components', 'button,modal');
      await asProject(project, 'generate', 'component', 'invoice-card', '--path', 'billing');

      expect(existsSync(join(project, 'src/app/shared/components/sa-modal/sa-modal.ts'))).toBe(
        true,
      );
      expect(existsSync(join(project, 'src/app/billing/invoice-card/invoice-card.ts'))).toBe(true);
      expect(await read(project, 'tsconfig.json')).toContain('"@shared/*"');
      expect(existsSync(join(project, 'src/app/features'))).toBe(false);

      await ng(project, 'build');
      await ng(project, 'test', '--watch=false');
    },
    INSTALL_TIMEOUT_MS,
  );

  it(
    'takes a default Angular project to the UI System with a few components, and completes its catalog when more arrive',
    async () => {
      const project = await createInstalled(
        'e2e-catalog',
        '--architecture',
        'angular-default',
        '--routing',
        'angular',
        '--app-shell',
        'none',
        '--components',
        'none',
        '--icons',
        'none',
      );
      const catalog = () =>
        read(project, 'src/app/features/preference-design/ui-system/ui-system.catalog.ts');
      const readme = () => read(project, 'README.md');
      // The README that the real ng new wrote is already the project's.
      expect(await readme()).not.toContain('This project was generated using [Angular CLI]');
      expect(await readme()).toContain('Angular default structure');

      // The UI System needs components: with none it refuses and says what to run.
      const refused = await execa('node', [bin, 'add', 'ui-system'], {
        cwd: project,
        reject: false,
        env: CHILD_ENV,
        extendEnv: true,
      });
      expect(refused.exitCode).toBe(2);
      expect(refused.stderr).toContain('sa add components');

      await asProject(project, 'add', 'components', 'button,modal,tabs');
      await asProject(project, 'add', 'architecture', 'screaming');
      await asProject(project, 'add', 'routing', 'starter');
      await asProject(project, 'add', 'app-shell');
      await asProject(project, 'add', 'ui-system');

      const first = await catalog();
      expect(first).toContain("id: 'modal'");
      expect(first).toContain("id: 'tabs'");
      // The shell brings its own search and colour picker, and the catalog shows what is installed.
      expect(first).toContain("id: 'search'");
      expect(first).toContain("id: 'theme-color-picker'");
      expect(first).not.toContain("id: 'table'");
      expect(first).not.toContain("id: 'datepicker'");
      expect(await readme()).not.toContain('This project was generated using [Angular CLI]');
      expect(await readme()).toContain('Starter Angular UI System');
      await buildWithinBudgets(project);

      // More components: the CLI says the catalog can be completed, and completes it on request.
      const more = await execa('node', [bin, 'add', 'components', 'table,datepicker'], {
        cwd: project,
        reject: false,
        env: CHILD_ENV,
        extendEnv: true,
      });
      expect(
        more.exitCode,
        `${more.stdout}
${more.stderr}`,
      ).toBe(0);
      expect(more.stdout).toContain('Next: "sa add ui-system"');
      expect(await catalog()).not.toContain("id: 'table'");
      await asProject(project, 'add', 'ui-system');
      const second = await catalog();
      expect(second).toContain("id: 'table'");
      expect(second).toContain("id: 'datepicker'");

      await buildWithinBudgets(project);
      await ng(project, 'test', '--watch=false');
    },
    INSTALL_TIMEOUT_MS,
  );

  it(
    'gives the Screaming Architecture to a project that is still what ng new generates',
    async () => {
      const project = await create(
        'e2e-adopt-architecture',
        '--architecture',
        'angular-default',
        '--routing',
        'angular',
        '--app-shell',
        'none',
        '--components',
        'none',
        '--icons',
        'none',
      );
      await rm(join(project, 'starter-angular.config.json'));

      await asProject(project, 'init');
      await asProject(project, 'add', 'architecture', 'screaming');

      expect(existsSync(join(project, 'src/app/features/README.md'))).toBe(true);
      expect(await read(project, 'tsconfig.json')).toContain('"@features/*"');
      const config = JSON.parse(await read(project, 'starter-angular.config.json'));
      expect(config.options.architecture).toBe('screaming');
    },
    TIMEOUT_MS,
  );
});
