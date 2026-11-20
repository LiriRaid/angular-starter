import { readFile } from 'node:fs/promises';
import { join } from 'node:path';
import { BLUEPRINTS_ROOT, copyBlueprint, renderTemplate } from '../blueprint.js';
import { componentsProfile } from '../components/components.js';
import { addComponentProvider, addNavigationGroups, wrapRoutesInLayout } from '../edits/layout.js';
import { planEdit, writeEdits, type PlannedEdit } from '../edits/planned.js';
import { addFeatureStyles } from '../edits/styles.js';
import { addNavigationItem, addProvider, addRoutes, type RouteSpec } from '../edits/typescript.js';
import { pathExists } from '../fs.js';
import { refreshGeneratedReadmes } from '../readme.js';

const APP = 'src/app/app.ts';
const APP_CONFIG = 'src/app/app.config.ts';
const APP_ROUTES = 'src/app/app.routes.ts';
const STYLES = 'src/styles.css';
const TREE = 'src/app/features/app-shell/navigation/navigation.data.ts';

/** The components the shell draws with (ADR-0008); what they import comes with them. */
export const SHELL_COMPONENTS: readonly string[] = [
  'icon',
  'button',
  'search',
  'tooltip',
  'popover',
  'drawer',
  'tabs',
  'toggle',
  'avatar',
  'theme-color-picker',
  'toast',
];

/** The example pages that give the navigation something to show: `home` already exists. */
export const SHELL_FEATURES = ['dashboard', 'users', 'reports', 'settings'] as const;

/** The design preferences page of the user menu (ADR-0010); it is not one of the example pages. */
export const PREFERENCE_DESIGN_FEATURE = 'preference-design';

/** Global stylesheets of the shell below `src/styles/features`, in the order they are imported. */
const SHELL_STYLES = [
  'sidebar-styles',
  'breadcrumb-styles',
  'user-menu-styles',
  'design-preferences-styles',
];

const FEATURE_ROUTES: readonly RouteSpec[] = [
  ...SHELL_FEATURES.map((feature) => ({
    path: feature,
    lazy: {
      file: `@features/${feature}/${feature}.routes`,
      exportName: `${feature.toUpperCase()}_ROUTES`,
    },
  })),
  {
    path: PREFERENCE_DESIGN_FEATURE,
    lazy: {
      file: `@features/${PREFERENCE_DESIGN_FEATURE}/${PREFERENCE_DESIGN_FEATURE}.routes`,
      exportName: 'PREFERENCE_DESIGN_ROUTES',
    },
  },
];

const LAYOUT = { file: '@features/app-shell/layout/main/main', exportName: 'Main' };

export interface AppShellProject {
  targetDir: string;
  /** The project name, as typed by the user. */
  name: string;
  /** Selector prefix of the application components. */
  prefix: string;
}

/**
 * The App Shell (ADR-0008): the layout, sidebar, header and breadcrumb of the reference application
 * without its business, the `provideLayout` providers of the root component, the layout route that
 * wraps the routes of the application, the stylesheets of the shell, five example pages (the
 * `home` the architecture already has plus `dashboard`, `users`, `reports` and `settings`) in the
 * navigation tree and the design preferences page the user menu opens (ADR-0010) with its
 * `core/design-preferences` and the `provideDesignPreferences()` of the application config. It brings the components it draws with; the design base and the starter routing
 * must be there already.
 */
export const appShellProfile = {
  /** Project files (forward slashes) that must exist once the shell has been applied. */
  requiredFiles: [
    'src/app/features/app-shell/layout/main/main.ts',
    'src/app/features/app-shell/layout/sidebar/sidebar.ts',
    'src/app/features/app-shell/layout/header/header.ts',
    'src/app/features/app-shell/components/breadcrumb/breadcrumb.ts',
    'src/app/features/app-shell/providers/layout.providers.ts',
    'src/app/features/app-shell/services/layout.service.ts',
    ...SHELL_STYLES.map((name) => `src/styles/features/${name}.css`),
    ...SHELL_FEATURES.map((feature) => `src/app/features/${feature}/${feature}.ts`),
    `src/app/features/${PREFERENCE_DESIGN_FEATURE}/${PREFERENCE_DESIGN_FEATURE}.ts`,
    'src/app/core/design-preferences/design-preferences.service.ts',
    ...componentsProfile.requiredFilesFor(SHELL_COMPONENTS),
  ],

  async apply({ targetDir, name, prefix }: AppShellProject): Promise<void> {
    // Plan every edit first: a file that does not have the expected shape stops the stage before
    // anything is written.
    await planEdits(targetDir);

    // The blueprint goes first: it refuses to overwrite (a feature of the same name, for example)
    // before anything else has been written.
    await copyBlueprint({
      source: join(BLUEPRINTS_ROOT, 'app-shell'),
      target: targetDir,
      variables: { PROJECT_NAME: name, PREFIX: prefix },
    });
    await componentsProfile.apply({ targetDir, name, prefix, set: SHELL_COMPONENTS });
    // Planned again: the components have added their own stylesheets to `styles.css` meanwhile.
    await writeEdits(await planEdits(targetDir));
    await applyWelcomeHome({ targetDir, name, prefix });
    await refreshGeneratedReadmes(targetDir);
  },
};

const HOME_FOLDER = 'src/app/features/home';
const HOME_FILES = ['home.ts', 'home.html', 'home.css', 'home.spec.ts'] as const;
const SCREAMING_HOME = join(BLUEPRINTS_ROOT, 'architectures', 'screaming', HOME_FOLDER);

/** The blueprint file of a home file: TypeScript carries the `.tpl` suffix, the markup and styles do not. */
const templateOf = (file: string): string => (file.endsWith('.ts') ? `${file}.tpl` : file);

const escapeRegExp = (text: string): string => text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

/**
 * True when `current` is the file of the architecture's blueprint, whatever the project name was
 * when it was generated (`as add app-shell` knows the package name, `as new` the name typed).
 */
async function isPristine(targetDir: string, file: string, prefix: string): Promise<boolean> {
  const current = await readFile(join(targetDir, HOME_FOLDER, file), 'utf8').catch(() => undefined);
  if (current === undefined) return false;
  const template = await readFile(join(SCREAMING_HOME, templateOf(file)), 'utf8');
  const sentinel = '\u0000';
  const rendered = renderTemplate(template, { PROJECT_NAME: sentinel, PREFIX: prefix });
  const pattern = escapeRegExp(rendered).replaceAll(sentinel, '[^\\r\\n]*?');
  return new RegExp(`^${pattern}$`).test(current.replaceAll('\r\n', '\n'));
}

/**
 * Replaces the neutral home of the architecture with the welcome page (ADR-0009), only while the
 * four files of `home` are still the ones the architecture wrote: a home the developer changed, or
 * that Starter SSR added its deferred section to, is theirs and stays as it is.
 */
async function applyWelcomeHome({ targetDir, name, prefix }: AppShellProject): Promise<void> {
  // A home.data.ts already there is the developer's: the copy would refuse it after the edits.
  if (await pathExists(join(targetDir, HOME_FOLDER, 'home.data.ts'))) return;
  for (const file of HOME_FILES) {
    if (!(await isPristine(targetDir, file, prefix))) return;
  }
  await copyBlueprint({
    source: join(BLUEPRINTS_ROOT, 'welcome'),
    target: targetDir,
    variables: { PROJECT_NAME: name, PREFIX: prefix },
    overwrite: HOME_FILES.map((file) => `${HOME_FOLDER}/${file}`),
  });
}

async function planEdits(targetDir: string): Promise<PlannedEdit[]> {
  return [
    await planEdit(targetDir, STYLES, (text) => addFeatureStyles(text, SHELL_STYLES)),
    await planEdit(targetDir, APP, (text) =>
      addComponentProvider(
        text,
        'App',
        '...provideLayout(APP_NAVIGATION, SidebarStatus.EXPANDED)',
        [
          { module: '@features/app-shell/providers/layout.providers', names: ['provideLayout'] },
          { module: '@features/app-shell/navigation/navigation.data', names: ['APP_NAVIGATION'] },
          {
            module: '@features/app-shell/layout/enums/sidebar-status.enum',
            names: ['SidebarStatus'],
          },
        ],
      ),
    ),
    await planEdit(targetDir, APP_CONFIG, (text) =>
      addProvider(text, 'provideDesignPreferences()', [
        {
          module: '@core/design-preferences/design-preferences.providers',
          names: ['provideDesignPreferences'],
        },
      ]),
    ),
    await planEdit(targetDir, APP_ROUTES, (text) =>
      addRoutes(wrapRoutesInLayout(text, LAYOUT), FEATURE_ROUTES),
    ),
    await planEdit(targetDir, TREE, (text) =>
      addNavigationGroups(
        addNavigationItem(text, {
          id: 'dashboard',
          title: 'Dashboard',
          link: '/dashboard',
          icon: 'LayoutGrid',
        }),
        [
          {
            label: 'Management',
            items: [
              { id: 'users', title: 'Users', icon: 'Users', link: '/users' },
              { id: 'reports', title: 'Reports', icon: 'FileText', link: '/reports' },
            ],
          },
          {
            label: 'System',
            items: [
              {
                id: 'settings',
                title: 'Settings',
                icon: 'Settings',
                children: [
                  { id: 'settings-general', title: 'General', link: '/settings/general' },
                  {
                    id: 'settings-notifications',
                    title: 'Notifications',
                    link: '/settings/notifications',
                  },
                ],
              },
              {
                id: PREFERENCE_DESIGN_FEATURE,
                title: 'Preferencias de Diseño',
                icon: 'SlidersHorizontal',
                link: `/${PREFERENCE_DESIGN_FEATURE}`,
              },
            ],
          },
        ],
      ),
    ),
  ];
}
