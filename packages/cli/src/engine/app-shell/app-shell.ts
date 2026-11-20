import { join } from 'node:path';
import { BLUEPRINTS_ROOT, copyBlueprint } from '../blueprint.js';
import { componentsProfile } from '../components/components.js';
import { addComponentProvider, addNavigationGroups, wrapRoutesInLayout } from '../edits/layout.js';
import { planEdit, writeEdits, type PlannedEdit } from '../edits/planned.js';
import { addFeatureStyles } from '../edits/styles.js';
import { addNavigationItem, addRoutes, type RouteSpec } from '../edits/typescript.js';

const APP = 'src/app/app.ts';
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

/** Global stylesheets of the shell below `src/styles/features`, in the order they are imported. */
const SHELL_STYLES = ['sidebar-styles', 'breadcrumb-styles', 'user-menu-styles'];

const FEATURE_ROUTES: readonly RouteSpec[] = SHELL_FEATURES.map((feature) => ({
  path: feature,
  lazy: {
    file: `@features/${feature}/${feature}.routes`,
    exportName: `${feature.toUpperCase()}_ROUTES`,
  },
}));

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
 * wraps the routes of the application, the stylesheets of the shell and five example pages (the
 * `home` the architecture already has plus `dashboard`, `users`, `reports` and `settings`) in the
 * navigation tree. It brings the components it draws with; the design base and the starter routing
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
  },
};

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
            ],
          },
        ],
      ),
    ),
  ];
}
