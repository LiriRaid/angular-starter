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
  project = await mkdtemp(join(tmpdir(), 'as-shell-'));
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
      'layout/sidebar/user-preferences/user-preferences.ts',
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
      'layout/sidebar/user-preferences/user-preferences.spec.ts',
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
      await expect(read(`src/app/shared/components/as-${id}/as-${id}.ts`), id).resolves.toBeTypeOf(
        'string',
      );
    }
    await expect(read('src/app/shared/components/as-table/as-table.ts')).rejects.toThrow();
    const barrel = await read('src/app/shared/components/index.ts');
    expect(barrel).toContain('AsSearch');
    expect(barrel).toContain('AsThemeColorPicker');
    expect(barrel).not.toContain('AsTable');
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
    await expect(read('src/app/shared/components/as-search/as-search.ts')).rejects.toThrow();
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
