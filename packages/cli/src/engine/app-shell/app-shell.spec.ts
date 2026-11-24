import { mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { writeGeneratedWorkspace } from '../../../tests/helpers/generated-workspace.js';
import { screamingProfile } from '../architectures/screaming.js';
import { BLUEPRINTS_ROOT, listBlueprintFiles } from '../blueprint.js';
import { COMPONENTS, componentsOfIds } from '../components/manifest.js';
import { designProfile } from '../design/design.js';
import { starterRoutingProfile } from '../routing/starter.js';
import { SHELL_COMPONENTS, SHELL_FEATURES, appShellProfile } from './app-shell.js';

const SHELL_BLUEPRINT = join(BLUEPRINTS_ROOT, 'app-shell');
const SHELL = 'src/app/features/app-shell';

let project: string;

beforeEach(async () => {
  project = await mkdtemp(join(tmpdir(), 'sa-shell-'));
  await writeGeneratedWorkspace(project);
  await screamingProfile.apply({ targetDir: project, name: 'demo', prefix: 'app' });
  await starterRoutingProfile.apply({ targetDir: project, name: 'demo', prefix: 'app' });
  await designProfile.apply({ targetDir: project, name: 'demo', prefix: 'app' });
});

afterEach(async () => {
  await rm(project, { recursive: true, force: true });
});

const read = (file: string): Promise<string> => readFile(join(project, file), 'utf8');
const apply = (name = 'demo', prefix = 'app') =>
  appShellProfile.apply({ targetDir: project, name, prefix });

describe('App Shell profile', () => {
  it('creates the structure of the reference application', async () => {
    await apply();
    for (const file of [
      'components/breadcrumb/breadcrumb.ts',
      'layout/main/main.ts',
      'layout/main/main.html',
      'layout/main/main.css',
      'layout/empty/empty.ts',
      'layout/header/header.ts',
      'layout/header/header.html',
      'layout/header/header.css',
      'layout/sidebar/sidebar.ts',
      'layout/sidebar/sidebar.html',
      'layout/sidebar/sidebar.css',
      'layout/sidebar/sidebar-navigation.utils.ts',
      'layout/sidebar/user-menu/user-menu.ts',
      'layout/enums/sidebar-status.enum.ts',
      'providers/layout.providers.ts',
      'services/layout.service.ts',
      'services/layout-navigation-state.utils.ts',
      'services/dropdown-coordinator.service.ts',
    ]) {
      await expect(read(`${SHELL}/${file}`), file).resolves.toBeTypeOf('string');
    }
    for (const file of [
      'src/styles/features/sidebar-styles.css',
      'src/styles/features/breadcrumb-styles.css',
      'src/styles/features/user-menu-styles.css',
    ]) {
      await expect(read(file), file).resolves.toContain('{');
    }
  });

  describe('design preferences page (ADR-0010)', () => {
    const PAGE = 'src/app/features/preference-design';
    const CORE = 'src/app/core/design-preferences';

    it('replaces the preferences drawer: no drawer, no output, no preferences component', async () => {
      await apply();
      await expect(
        read(`${SHELL}/layout/sidebar/user-preferences/user-preferences.ts`),
      ).rejects.toThrow();
      const sidebar = await read(`${SHELL}/layout/sidebar/sidebar.ts`);
      expect(sidebar).not.toMatch(/UserPreferences|openUserPreferences/);
      expect(await read(`${SHELL}/layout/sidebar/sidebar.html`)).not.toContain('user-preferences');
      expect(await read(`${SHELL}/layout/sidebar/user-menu/user-menu.ts`)).not.toContain(
        'preferencesClick',
      );
    });

    it('opens the page from the user menu with a button called "Preferencias de Diseño"', async () => {
      await apply();
      const html = await read(`${SHELL}/layout/sidebar/user-menu/user-menu.html`);
      expect(html).toContain('label="Preferencias de Diseño"');
      expect(html).not.toContain('label="Preferencias"');
      const ts = await read(`${SHELL}/layout/sidebar/user-menu/user-menu.ts`);
      expect(ts).toContain("navigateByUrl('/preference-design')");
    });

    it('creates the feature with its routes, tabs, service and specs', async () => {
      await apply();
      for (const file of [
        'preference-design.ts',
        'preference-design.html',
        'preference-design.routes.ts',
        'preference-design.spec.ts',
        'tabs/appearance-tab.ts',
        'tabs/theme-tab.ts',
        'tabs/ui-tab.ts',
        'tabs/other-tab.ts',
      ]) {
        await expect(read(`${PAGE}/${file}`), file).resolves.toBeTypeOf('string');
      }
      expect(await read(`${PAGE}/preference-design.routes.ts`)).toContain(
        'PREFERENCE_DESIGN_ROUTES',
      );
      for (const file of [
        'design-preferences.service.ts',
        'design-preferences.service.spec.ts',
        'design-preferences.providers.ts',
        'README.md',
      ]) {
        await expect(read(`${CORE}/${file}`), file).resolves.toBeTypeOf('string');
      }
      await expect(read('src/styles/features/design-preferences-styles.css')).resolves.toContain(
        '--sa-ui-radius-scale',
      );
    });

    it('shows the four tabs of the demo with sa-tabs, and the reset and save buttons', async () => {
      await apply();
      const html = await read(`${PAGE}/preference-design.html`);
      expect(html).toContain('<sa-tabs');
      expect(html).toContain('Restablecer');
      expect(html).toContain('Guardar cambios');
      const ts = await read(`${PAGE}/preference-design.ts`);
      for (const label of ['Apariencia', 'Tema', 'UI', 'Otros']) {
        expect(ts).toContain(`label: '${label}'`);
      }
      expect(await read(`${PAGE}/tabs/appearance-tab.ts`)).toContain('Flotante (ancho)');
      expect(await read(`${PAGE}/tabs/appearance-tab.html`)).toContain('En construcción');
      // The width of the transparent sidebar is the project's own select, not a native one.
      const appearance = await read(`${PAGE}/tabs/appearance-tab.html`);
      expect(appearance).toContain('<sa-select');
      expect(appearance).not.toContain('<select');
    });

    it('applies the preferences at start and in real time, persisting what is saved', async () => {
      await apply();
      const service = await read(`${CORE}/design-preferences.service.ts`);
      expect(service).toContain('localStorage');
      for (const token of [
        '--sa-ui-radius-scale',
        '--sa-ui-button-scale',
        '--sa-ui-density-scale',
        '--sa-ui-font-scale',
      ]) {
        expect(service).toContain(token);
      }
      expect(service).toContain('data-animations');
      expect(await read('src/app/app.config.ts')).toContain('provideDesignPreferences()');
    });

    it('adds the route and a navigation entry with its breadcrumb', async () => {
      await apply();
      const routes = await read('src/app/app.routes.ts');
      expect(routes).toContain('preference-design.routes');
      expect(routes).toContain('PREFERENCE_DESIGN_ROUTES');
      const tree = await read(`${SHELL}/navigation/navigation.data.ts`);
      expect(tree).toContain("link: '/preference-design'");
      expect(tree).toContain('Preferencias de Diseño');
      // Only the button of the user menu opens the page: the sidebar does not list it.
      expect(tree).toContain('hidden: () => true');
      const styles = await read('src/styles.css');
      expect(styles).toContain("@import './styles/features/design-preferences-styles.css';");
    });

    it('keeps the radius and size rules in the layer of the components, so utility classes win', async () => {
      await apply();
      const css = await read('src/styles/features/design-preferences-styles.css');
      const layered = css.slice(css.indexOf('@layer legacy-overrides {'));
      expect(layered).toContain(':root .sa-btn.sa-btn-medium');
      expect(css.slice(0, css.indexOf('@layer legacy-overrides {'))).not.toContain('.sa-btn');
    });

    it('keeps only the layout in Apariencia: colours and light or dark live in Tema (ADR-0011)', async () => {
      await apply();
      const appearance = await read(`${PAGE}/tabs/appearance-tab.html`);
      expect(appearance).toContain('Diseño (Layout)');
      expect(appearance).toContain('Sidebar transparente');
      expect(appearance).not.toMatch(/Esquema de colores|color-swatches|mode-switch|Claro|Oscuro/);
      expect(await read(`${PAGE}/tabs/appearance-tab.ts`)).not.toMatch(
        /ThemeService|theme-controls/,
      );

      const theme = await read(`${PAGE}/tabs/theme-tab.html`);
      expect(theme).toContain('Color principal');
      expect(theme).toContain('Superficie');
      expect(theme).toContain('mode-switch');
      expect(await read(`${PAGE}/tabs/theme-tab.ts`)).toContain("from '@core/theme/theme.service'");
    });

    it('draws the swatches round, with the ring of the reference application and a check', async () => {
      await apply();
      const controls = await read(`${PAGE}/tabs/theme-controls.ts`);
      expect(controls).toContain('rounded-full');
      expect(controls).not.toContain('border-white');
      expect(controls).toContain('CheckCircle');
      // A ring of the panel colour, then one of the primary colour.
      expect(controls).toContain('--app-panel-bg');
      expect(controls).toContain('--sa-primary-color');
    });

    it('leaves a marker in the UI tab where the UI System puts its catalog', async () => {
      await apply();
      expect(await read(`${PAGE}/tabs/ui-tab.html`)).toContain('<!-- as:ui-system -->');
    });

    it('lists its files for the verification stage', () => {
      expect(appShellProfile.requiredFiles).toEqual(
        expect.arrayContaining([
          'src/app/features/preference-design/preference-design.ts',
          'src/app/core/design-preferences/design-preferences.service.ts',
          'src/styles/features/design-preferences-styles.css',
        ]),
      );
    });
  });

  it('does not port the call widget or the business of the reference', async () => {
    await apply();
    await expect(read(`${SHELL}/layout/call-widget/call-widget.ts`)).rejects.toThrow();
    for (const file of await listBlueprintFiles(SHELL_BLUEPRINT)) {
      const text = await readFile(join(SHELL_BLUEPRINT, file), 'utf8');
      expect(text, file).not.toMatch(
        /omni|yalo|gabriel|AuthService|PresenceService|TicketBadge|ConversationBadge|NotificationsService|call-widget|gsap/i,
      );
    }
  });

  it('ships a spec for every piece that has logic', async () => {
    await apply();
    for (const file of [
      'components/breadcrumb/breadcrumb.spec.ts',
      'layout/main/main.spec.ts',
      'layout/empty/empty.spec.ts',
      'layout/header/header.spec.ts',
      'layout/sidebar/sidebar.spec.ts',
      'layout/sidebar/sidebar-navigation.utils.spec.ts',
      'layout/sidebar/user-menu/user-menu.spec.ts',
      'services/layout.service.spec.ts',
      'services/layout-navigation-state.utils.spec.ts',
    ]) {
      await expect(read(`${SHELL}/${file}`), file).resolves.toContain("describe('");
    }
  });

  it('generates the components the shell uses, and only them and what they import', async () => {
    await apply();
    const expected = componentsOfIds(SHELL_COMPONENTS).map((component) => component.id);
    for (const id of expected) {
      await expect(read(`src/app/shared/components/sa-${id}/sa-${id}.ts`), id).resolves.toBeTypeOf(
        'string',
      );
    }
    await expect(read('src/app/shared/components/sa-table/sa-table.ts')).rejects.toThrow();
    const barrel = await read('src/app/shared/components/index.ts');
    expect(barrel).toContain('SaSearch');
    expect(barrel).toContain('SaThemeColorPicker');
    expect(barrel).not.toContain('SaTable');
  });

  it('only imports components that the shell brings', async () => {
    const allowed = new Set(
      componentsOfIds(SHELL_COMPONENTS).flatMap((component) =>
        component.exports.flatMap(({ names }) => names.map((name) => name.replace(/^type /, ''))),
      ),
    );
    const everyExport = new Set(
      COMPONENTS.flatMap((component) =>
        component.exports.flatMap(({ names }) => names.map((name) => name.replace(/^type /, ''))),
      ),
    );
    const files = [
      ...(await listBlueprintFiles(SHELL_BLUEPRINT)).filter(
        (file) => file.endsWith('.ts.tpl') || file.endsWith('.html.tpl'),
      ),
    ];
    for (const file of files) {
      const text = await readFile(join(SHELL_BLUEPRINT, file), 'utf8');
      for (const [, names] of text.matchAll(/import \{([^}]*)\} from '@shared\/components'/g)) {
        for (const name of (names ?? '')
          .split(',')
          .map((entry) => entry.trim().replace(/^type /, ''))) {
          if (!name) continue;
          expect(everyExport.has(name), `${file}: ${name} is not a component`).toBe(true);
          expect(allowed.has(name), `${file}: ${name} is not brought by the shell`).toBe(true);
        }
      }
    }
  });

  it('creates the example features with routes, a component and a spec', async () => {
    await apply();
    expect(SHELL_FEATURES).toEqual(['dashboard', 'users', 'reports', 'settings']);
    for (const feature of SHELL_FEATURES) {
      const routes = await read(`src/app/features/${feature}/${feature}.routes.ts`);
      expect(routes).toContain(`${feature.toUpperCase()}_ROUTES`);
      await expect(read(`src/app/features/${feature}/${feature}.ts`)).resolves.toContain(
        '@Component',
      );
      await expect(read(`src/app/features/${feature}/${feature}.spec.ts`)).resolves.toContain(
        "describe('",
      );
    }
    const settings = await read('src/app/features/settings/settings.routes.ts');
    expect(settings).toContain("path: 'general'");
    expect(settings).toContain("path: 'notifications'");
  });

  it('gives the layout the routes, the providers and the styles', async () => {
    await apply('demo', 'shop');
    const routes = await read('src/app/app.routes.ts');
    expect(routes).toContain("import('@features/app-shell/layout/main/main')");
    for (const feature of SHELL_FEATURES) expect(routes).toContain(`${feature}.routes`);
    expect(routes.indexOf('HOME_ROUTES')).toBeGreaterThan(routes.indexOf('children: ['));

    const app = await read('src/app/app.ts');
    expect(app).toContain('providers: [...provideLayout(APP_NAVIGATION, SidebarStatus.EXPANDED)]');
    expect(app).toContain('<router-outlet />');

    const styles = await read('src/styles.css');
    for (const name of ['sidebar', 'breadcrumb', 'user-menu']) {
      expect(styles).toContain(`@import './styles/features/${name}-styles.css';`);
    }
    expect(styles.indexOf('user-menu-styles.css')).toBeLessThan(styles.indexOf('animations.css'));
  });

  it('adds the example pages to the navigation tree, in groups', async () => {
    await apply();
    const tree = await read(`${SHELL}/navigation/navigation.data.ts`);
    for (const link of ['/home', '/dashboard', '/users', '/reports', '/settings/general']) {
      expect(tree).toContain(`link: '${link}'`);
    }
    expect(tree).toContain("label: 'Management'");
    expect(tree).toContain("label: 'System'");
    expect(tree).toContain("type: 'collapsable'");
  });

  it('uses the selector prefix of the project', async () => {
    await apply('demo', 'shop');
    expect(await read(`${SHELL}/layout/main/main.ts`)).toContain("selector: 'shop-main'");
    expect(await read(`${SHELL}/layout/sidebar/sidebar.ts`)).toContain("selector: 'shop-sidebar'");
    expect(await read('src/styles/features/sidebar-styles.css')).toContain('shop-sidebar');
    expect(await read('src/app/features/dashboard/dashboard.ts')).toContain(
      "selector: 'shop-dashboard'",
    );
  });

  it('draws the brand of the sidebar from the project name, not from a literal', async () => {
    await apply('Inventory System');
    expect(await read(`${SHELL}/layout/sidebar/sidebar.ts`)).toContain(
      'inject(NAV_APP_NAME_TOKEN)',
    );
    expect(await read(`${SHELL}/layout/sidebar/sidebar.html`)).toContain('{{ brandTitle }}');
  });

  it('leaves the components alone when the blueprint cannot be copied', async () => {
    await mkdir(join(project, 'src/app/features/dashboard'), { recursive: true });
    await writeFile(join(project, 'src/app/features/dashboard/dashboard.ts'), 'export {};');
    await expect(apply()).rejects.toThrow(/overwrite/);
    await expect(read('src/app/shared/components/sa-search/sa-search.ts')).rejects.toThrow();
  });

  it('keeps the layer rules: the shell imports core and shared, never another feature', async () => {
    await apply();
    for (const file of await listBlueprintFiles(SHELL_BLUEPRINT)) {
      if (!file.startsWith('src/app/features/')) continue;
      const text = await read(file.replace(/\.tpl$/, ''));
      expect(text, file).not.toMatch(/from '@features\//);
    }
  });

  it('leaves no unresolved placeholder in any generated file', async () => {
    await apply();
    for (const file of await listBlueprintFiles(SHELL_BLUEPRINT)) {
      const generated = file.replace(/\.tpl$/, '');
      expect(await read(generated), generated).not.toMatch(/__[A-Z_]+__/);
    }
  });

  it('writes nothing when app.ts does not have the expected shape', async () => {
    await writeFile(join(project, 'src/app/app.ts'), 'export class App {}\n');
    await expect(apply()).rejects.toThrow(/app\.ts/);
    await expect(read(`${SHELL}/layout/main/main.ts`)).rejects.toThrow();
    await expect(read('src/app/features/dashboard/dashboard.ts')).rejects.toThrow();
  });

  it('asks for the design base first', async () => {
    await writeFile(join(project, 'src/styles.css'), "@import 'tailwindcss';\n");
    await expect(apply()).rejects.toThrow(/styles\.css/);
  });

  it('refuses to overwrite files that already exist', async () => {
    await apply();
    await expect(apply()).rejects.toThrow(/overwrite/);
  });

  describe('welcome home', () => {
    const HOME = 'src/app/features/home';

    it('replaces the neutral home with a welcome page: logo, name, cards, Starter Angular and GitHub', async () => {
      await apply('Inventory System');
      const html = await read(`${HOME}/home.html`);
      expect(html).toContain('<svg');
      expect(html).toContain('{{ projectName() }}');
      expect(html).toContain('@for (card of cards');
      expect(html).toContain('Starter Angular');
      expect(html).toContain('socialLinks');
      const ts = await read(`${HOME}/home.ts`);
      expect(ts).toContain("selector: 'app-home'");
      expect(ts).toContain("signal('Inventory System')");
      const data = await read(`${HOME}/home.data.ts`);
      expect(data).toContain('WELCOME_CARDS');
      expect(data).toContain('https://github.com/LiriRaid/starter-angular');
      expect(data).not.toMatch(/twitter|linkedin|facebook|instagram/i);
      expect(await read(`${HOME}/home.spec.ts`)).toContain('Inventory System');
    });

    it('links the cards to the pages the project really has', async () => {
      await apply();
      const data = await read(`${HOME}/home.data.ts`);
      const tree = await read(`${SHELL}/navigation/navigation.data.ts`);
      const routes = [...data.matchAll(/route: '([^']+)'/g)].map((match) => match[1] ?? '');
      expect(routes).toContain('/dashboard');
      for (const route of routes) {
        const page = `/${route.split('/')[1]}`;
        expect(tree, route).toContain(`link: '${page}'`);
      }
      expect(data).not.toContain('/presence');
    });

    it('sends the documentation and tutorials cards to the pages of Starter Angular, not to Angular', async () => {
      await apply();
      const data = await read(`${HOME}/home.data.ts`);
      expect(data).not.toContain('angular.dev');
      expect(data).toContain("id: 'starter-docs'");
      expect(data).toContain("route: '/docs'");
      expect(data).toContain("id: 'starter-tutorials'");
      expect(data).toContain("route: '/docs/tutorials'");
    });

    describe('documentation', () => {
      const DOCS = 'src/app/features/docs';

      it('brings the documentation of Starter Angular with its pages, its tutorials and its README', async () => {
        await apply('Inventory System');
        for (const file of [
          'docs.ts',
          'docs.html',
          'docs.data.ts',
          'docs.routes.ts',
          'docs.spec.ts',
          'README.md',
        ]) {
          await expect(read(`${DOCS}/${file}`), file).resolves.toBeTypeOf('string');
        }
        const data = await read(`${DOCS}/docs.data.ts`);
        for (const page of [
          'getting-started',
          'design-base',
          'components',
          'app-shell',
          'tutorials',
        ]) {
          expect(data, page).toContain(`id: '${page}'`);
        }
        expect(data).toContain('starter-angular');
        expect(data).not.toContain('angular.dev');
        expect(await read(`${DOCS}/docs.ts`)).toContain("selector: 'app-docs'");
      });

      it('loads it lazily from the routes and lists it in the navigation tree', async () => {
        await apply();
        const routes = await read('src/app/app.routes.ts');
        expect(routes).toContain("path: 'docs'");
        expect(routes).toContain('@features/docs/docs.routes');
        expect(await read(`${SHELL}/navigation/navigation.data.ts`)).toContain("link: '/docs'");
      });

      it('leaves no unresolved placeholder in it', async () => {
        await apply();
        for (const file of [
          'docs.ts',
          'docs.html',
          'docs.data.ts',
          'docs.routes.ts',
          'docs.spec.ts',
          'README.md',
        ]) {
          expect(await read(`${DOCS}/${file}`), file).not.toMatch(/__[A-Z_]+__/);
        }
      });

      it('is not written over a documentation feature the developer already has', async () => {
        await mkdir(join(project, DOCS), { recursive: true });
        await writeFile(join(project, DOCS, 'docs.ts'), '// mine\n');
        await apply();
        expect(await read(`${DOCS}/docs.ts`)).toBe('// mine\n');
        await expect(read(`${HOME}/home.data.ts`)).rejects.toThrow();
      });
    });

    it('keeps the routes of the home as the architecture wrote them', async () => {
      const before = await read(`${HOME}/home.routes.ts`);
      await apply();
      expect(await read(`${HOME}/home.routes.ts`)).toBe(before);
    });

    it.each([
      ['home.ts', '// mine\n'],
      ['home.html', '<main>mine</main>\n'],
      ['home.css', '/* mine */\n'],
      ['home.spec.ts', '// mine\n'],
    ])('leaves the home alone when the developer changed %s', async (file, text) => {
      await writeFile(join(project, HOME, file), text);
      await apply();
      expect(await read(`${HOME}/${file}`)).toBe(text);
      await expect(read(`${HOME}/home.data.ts`)).rejects.toThrow();
      await expect(read('src/app/features/docs/docs.ts')).rejects.toThrow();
      for (const other of ['home.ts', 'home.html', 'home.css', 'home.spec.ts']) {
        if (other !== file) expect(await read(`${HOME}/${other}`)).not.toContain('WELCOME');
      }
      // The shell itself is there: only the welcome page was skipped.
      await expect(read(`${SHELL}/layout/main/main.ts`)).resolves.toBeTypeOf('string');
    });

    it('leaves a home alone that Starter SSR changed with its deferred section', async () => {
      const html = await read(`${HOME}/home.html`);
      await writeFile(
        join(project, HOME, 'home.html'),
        `${html}\n@defer (hydrate on viewport) {\n  <app-home-details />\n}\n`,
      );
      await apply();
      expect(await read(`${HOME}/home.html`)).toContain('@defer (hydrate on viewport)');
      expect(await read(`${HOME}/home.html`)).not.toContain('@for (card of cards');
    });

    it('leaves no unresolved placeholder in the welcome page', async () => {
      await apply();
      for (const file of ['home.ts', 'home.html', 'home.css', 'home.spec.ts', 'home.data.ts']) {
        expect(await read(`${HOME}/${file}`), file).not.toMatch(/__[A-Z_]+__/);
      }
    });
  });

  it('lists the files the verification stage must find', () => {
    expect(appShellProfile.requiredFiles).toEqual(
      expect.arrayContaining([
        'src/app/features/app-shell/layout/main/main.ts',
        'src/app/features/app-shell/services/layout.service.ts',
        'src/styles/features/sidebar-styles.css',
        'src/app/features/dashboard/dashboard.ts',
      ]),
    );
  });
});
