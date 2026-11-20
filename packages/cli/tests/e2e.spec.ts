import { existsSync } from 'node:fs';
import { mkdtemp, readFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execa } from 'execa';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';

/**
 * Runs the compiled CLI against the real Angular CLI (needs network and a prior `pnpm build`).
 * Opt in with AS_E2E=1.
 */
const enabled = process.env['AS_E2E'] === '1';
const bin = fileURLToPath(new URL('../dist/bin.js', import.meta.url));
const TIMEOUT_MS = 5 * 60_000;
const INSTALL_TIMEOUT_MS = 15 * 60_000;
const CLEANUP_TIMEOUT_MS = 10 * 60_000;

describe.skipIf(!enabled)('as new (end to end, real Angular CLI)', () => {
  let cwd: string;

  beforeAll(async () => {
    expect(existsSync(bin), 'Run "pnpm build" first: dist/bin.js is missing.').toBe(true);
    cwd = await mkdtemp(join(tmpdir(), 'as-e2e-'));
  });

  // Deleting two installed projects (node_modules) takes longer than the default hook timeout.
  afterAll(async () => {
    await rm(cwd, { recursive: true, force: true });
  }, CLEANUP_TIMEOUT_MS);

  async function create(name: string, ...flags: string[]) {
    const result = await execa(
      'node',
      [bin, 'new', name, '--defaults', '--no-install', '--no-git', ...flags],
      { cwd, reject: false, env: { CI: '1' }, extendEnv: true },
    );
    expect(result.exitCode, `${result.stdout}\n${result.stderr}`).toBe(0);
    return join(cwd, name);
  }

  /** Creates a project with its dependencies installed, so that it can be built and tested. */
  async function createInstalled(name: string, ...flags: string[]) {
    const result = await execa(
      'node',
      [bin, 'new', name, '--defaults', '--no-git', '--package-manager', 'npm', ...flags],
      { cwd, reject: false, env: { CI: '1' }, extendEnv: true },
    );
    expect(
      result.exitCode,
      `${result.stdout}
${result.stderr}`,
    ).toBe(0);
    return join(cwd, name);
  }

  /** Runs the compiled CLI inside an existing project, as a person would. */
  async function asProject(project: string, ...args: string[]) {
    const result = await execa('node', [bin, ...args], {
      cwd: project,
      reject: false,
      env: { CI: '1' },
      extendEnv: true,
    });
    expect(
      result.exitCode,
      `as ${args.join(' ')}
${result.stdout}
${result.stderr}`,
    ).toBe(0);
  }

  async function ng(project: string, ...args: string[]) {
    const result = await execa('npx', ['--no-install', 'ng', ...args], {
      cwd: project,
      reject: false,
      env: { CI: '1' },
      extendEnv: true,
    });
    expect(
      result.exitCode,
      `ng ${args.join(' ')}
${result.stdout}
${result.stderr}`,
    ).toBe(0);
  }

  const read = (project: string, file: string): Promise<string> =>
    readFile(join(project, file), 'utf8');

  it(
    'creates a CSS + Tailwind application with the default options',
    async () => {
      const project = await create('e2e-tailwind');
      expect(existsSync(join(project, 'angular-starter.config.json'))).toBe(true);
      expect(existsSync(join(project, 'src', 'main.ts'))).toBe(true);
      const manifest = await read(project, 'package.json');
      expect(manifest).toContain('tailwindcss');
      // Zoneless is the Angular 22 default: the app has no zone.js at all.
      expect(manifest).not.toContain('zone.js');
    },
    TIMEOUT_MS,
  );

  it(
    'creates an SCSS application without Tailwind and records the options',
    async () => {
      const project = await create('e2e-scss', '--style', 'scss', '--prefix', 'acme');
      expect(existsSync(join(project, 'src', 'styles.scss'))).toBe(true);
      expect(await read(project, 'package.json')).not.toContain('tailwindcss');
      const config = JSON.parse(await read(project, 'angular-starter.config.json'));
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

  it.each([
    ['csr', 'e2e-screaming'],
    ['ssr', 'e2e-screaming-ssr'],
  ])(
    'creates a Screaming Architecture project (%s) that builds and passes its tests',
    async (rendering, name) => {
      const project = await createInstalled(
        name,
        '--architecture',
        'screaming',
        '--rendering',
        rendering,
        '--app-shell',
        'none',
      );

      for (const file of [
        'src/app/core/README.md',
        'src/app/features/home/home.routes.ts',
        'src/app/shared/components/index.ts',
      ]) {
        expect(existsSync(join(project, file)), file).toBe(true);
      }
      expect(await read(project, 'tsconfig.json')).toContain('"@features/*"');
      const config = JSON.parse(await read(project, 'angular-starter.config.json'));
      expect(config.options.architecture).toBe('screaming');

      await ng(project, 'build');
      await ng(project, 'test', '--watch=false');
    },
    INSTALL_TIMEOUT_MS,
  );

  it.each([
    ['csr', 'e2e-routing'],
    ['ssr', 'e2e-routing-ssr'],
  ])(
    'creates a Screaming project with the Angular Starter routing (%s) that builds and passes its tests',
    async (rendering, name) => {
      const project = await createInstalled(
        name,
        '--architecture',
        'screaming',
        '--routing',
        'starter',
        '--rendering',
        rendering,
        '--app-shell',
        'none',
      );

      for (const file of [
        'src/app/core/navigation/breadcrumb.service.ts',
        'src/app/core/navigation/navigation-title.strategy.ts',
        'src/app/core/navigation/navigation.providers.ts',
        'src/app/features/app-shell/navigation/navigation.data.ts',
      ]) {
        expect(existsSync(join(project, file)), file).toBe(true);
      }
      expect(await read(project, 'src/app/app.config.ts')).toContain(
        `provideNavigation(APP_NAVIGATION, { appName: '${name}' })`,
      );
      const config = JSON.parse(await read(project, 'angular-starter.config.json'));
      expect(config.options).toMatchObject({ architecture: 'screaming', routing: 'starter' });

      await ng(project, 'build');
      await ng(project, 'test', '--watch=false');
    },
    INSTALL_TIMEOUT_MS,
  );

  it(
    'creates a Starter SSR project with incremental hydration that builds and passes its tests',
    async () => {
      const project = await createInstalled(
        'e2e-starter-ssr',
        '--architecture',
        'screaming',
        '--routing',
        'starter',
        '--rendering',
        'starter-ssr',
        '--icons',
        'none',
        '--components',
        'none',
      );
      const config = await read(project, 'src/app/app.config.ts');
      expect(config).toContain('withIncrementalHydration()');
      expect(await read(project, 'src/app/features/home/home.html')).toContain(
        '@defer (hydrate on viewport)',
      );
      expect(existsSync(join(project, 'src', 'main.server.ts'))).toBe(true);

      await ng(project, 'build');
      await ng(project, 'test', '--watch=false');
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

      const config = JSON.parse(await read(project, 'angular-starter.config.json'));
      expect(config.options).toMatchObject({
        routing: 'starter',
        icons: 'lucide',
        rendering: 'starter-ssr',
        components: 'recommended',
      });
      expect(existsSync(join(project, 'src/app/shared/components/as-button/as-button.ts'))).toBe(
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
        'src/app/shared/components/as-button/as-button.ts',
        'src/app/shared/components/as-modal/as-modal.ts',
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

      await ng(project, 'build');
      await ng(project, 'test', '--watch=false');
    },
    INSTALL_TIMEOUT_MS,
  );

  it(
    'creates a project with every component and the Starter SSR that builds and passes its tests',
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
        'src/app/shared/components/as-table/as-table.ts',
        'src/app/shared/components/as-datepicker/as-datepicker.ts',
        'src/app/shared/components/as-theme-color-picker/as-theme-color-picker.ts',
        'src/app/shared/components/as-weekly-schedule/as-weekly-schedule.ts',
        'src/app/features/home/home-details/home-details.ts',
      ]) {
        expect(existsSync(join(project, file)), file).toBe(true);
      }

      await ng(project, 'build');
      await ng(project, 'test', '--watch=false');
    },
    INSTALL_TIMEOUT_MS,
  );

  it(
    'adds the App Shell to an existing project and generates a feature inside it that build and test',
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

      const config = JSON.parse(await read(project, 'angular-starter.config.json'));
      expect(config.options).toMatchObject({
        appShell: 'starter',
        icons: 'lucide',
        components: 'all',
      });
      const routes = await read(project, 'src/app/app.routes.ts');
      expect(routes.indexOf("path: 'billing'")).toBeGreaterThan(routes.indexOf('children: ['));
      expect(existsSync(join(project, 'src/app/shared/components/as-table/as-table.ts'))).toBe(
        true,
      );

      await ng(project, 'build');
      await ng(project, 'test', '--watch=false');
    },
    INSTALL_TIMEOUT_MS,
  );

  it(
    'creates a project with presence and the welcome home that builds and passes its tests',
    async () => {
      const project = await createInstalled('e2e-presence', '--presence', 'starter');
      for (const file of [
        'src/app/core/presence/presence.service.ts',
        'src/app/core/presence/web-socket-presence.transport.ts',
        'src/app/features/app-shell/layout/sidebar/user-menu/user-status.ts',
        'src/styles/features/presence-styles.css',
        'docs/presence.md',
        'src/app/core/theme/README.md',
        'src/app/shared/components/README.md',
        'src/styles/README.md',
      ]) {
        expect(existsSync(join(project, file)), file).toBe(true);
      }
      expect(await read(project, 'src/app/app.config.ts')).toContain('providePresence()');
      expect(await read(project, 'src/app/features/home/home.html')).toContain(
        '@for (card of cards',
      );
      expect(await read(project, 'src/app/features/home/home.data.ts')).toContain("id: 'presence'");

      await ng(project, 'build');
      await ng(project, 'test', '--watch=false');
    },
    INSTALL_TIMEOUT_MS,
  );

  it(
    'adds presence to an existing project that builds and passes its tests',
    async () => {
      const project = await createInstalled('e2e-add-presence');
      await asProject(project, 'add', 'presence');
      expect(JSON.parse(await read(project, 'angular-starter.config.json')).options.presence).toBe(
        'starter',
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
    'creates the default Angular structure as plain Angular: no Lucide, no shell, no layout',
    async () => {
      const project = await createInstalled('e2e-plain', '--architecture', 'angular-default');
      const config = JSON.parse(await read(project, 'angular-starter.config.json'));
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
    'creates a project with the design preferences page and the UI System that builds and passes its tests',
    async () => {
      const project = await createInstalled('e2e-ui-system', '--ui-system', 'starter');
      for (const file of [
        'src/app/features/preference-design/preference-design.ts',
        'src/app/features/preference-design/ui-system/ui-system.catalog.ts',
        'src/app/core/design-preferences/design-preferences.service.ts',
        'src/styles/features/design-preferences-styles.css',
      ]) {
        expect(existsSync(join(project, file)), file).toBe(true);
      }
      expect(await read(project, 'src/app/app.config.ts')).toContain('provideDesignPreferences()');
      expect(await read(project, 'src/app/features/preference-design/tabs/ui-tab.html')).toContain(
        '<app-ui-system />',
      );
      const config = JSON.parse(await read(project, 'angular-starter.config.json'));
      expect(config.options).toMatchObject({ uiSystem: 'starter', layout: 'floating-wide' });

      await ng(project, 'build');
      await ng(project, 'test', '--watch=false');
    },
    INSTALL_TIMEOUT_MS,
  );

  it(
    'adds the UI System to an existing project that builds and passes its tests',
    async () => {
      const project = await createInstalled('e2e-add-ui-system');
      await asProject(project, 'add', 'ui-system');
      expect(JSON.parse(await read(project, 'angular-starter.config.json')).options.uiSystem).toBe(
        'starter',
      );

      await ng(project, 'build');
      await ng(project, 'test', '--watch=false');
    },
    INSTALL_TIMEOUT_MS,
  );

  it(
    'installs the Lucide Icons package and still builds',
    async () => {
      const project = await createInstalled('e2e-lucide', '--icons', 'lucide');
      expect(
        JSON.parse(await read(project, 'package.json')).dependencies['@lucide/angular'],
      ).toMatch(/^\^1\./);
      expect(existsSync(join(project, 'node_modules', '@lucide', 'angular'))).toBe(true);
      await ng(project, 'build');
    },
    INSTALL_TIMEOUT_MS,
  );
});
