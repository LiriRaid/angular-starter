import { describe, expect, it } from 'vitest';
import { addComponentProvider, addNavigationGroups, wrapRoutesInLayout } from './layout.js';
import { addRoutes } from './typescript.js';

/** `app.ts` as the Screaming profile leaves it. */
const APP = `import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';

@Component({
  imports: [RouterOutlet],
  selector: 'app-root',
  template: '<router-outlet />',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class App {}
`;

/** `app.routes.ts` as the Screaming profile leaves it. */
const ROUTES = `import { Routes } from '@angular/router';

export const routes: Routes = [
  { path: '', pathMatch: 'full', redirectTo: 'home' },
  { path: 'home', loadChildren: () => import('@features/home/home.routes').then((m) => m.HOME_ROUTES) },
];
`;

const MAIN = {
  file: '@features/app-shell/layout/main/main',
  exportName: 'Main',
};

const TREE = `import type { NavigationGroup } from '@core/navigation/navigation.types';

export const APP_NAVIGATION: readonly NavigationGroup[] = [
  {
    label: 'General',
    items: [{ id: 'home', title: 'Home', icon: 'Home', type: 'basic', link: '/home' }],
  },
];
`;

const PROVIDER = '...provideLayout(APP_NAVIGATION, SidebarStatus.EXPANDED)';
const IMPORTS = [
  { module: '@features/app-shell/providers/layout.providers', names: ['provideLayout'] },
  { module: '@features/app-shell/navigation/navigation.data', names: ['APP_NAVIGATION'] },
  { module: '@features/app-shell/layout/enums/sidebar-status.enum', names: ['SidebarStatus'] },
];

describe('addComponentProvider', () => {
  it('creates the providers of the component and imports what the expression uses', () => {
    const result = addComponentProvider(APP, 'App', PROVIDER, IMPORTS);
    expect(result).toContain(`providers: [${PROVIDER}]`);
    expect(result).toContain(
      "import { provideLayout } from '@features/app-shell/providers/layout.providers';",
    );
    expect(result).toContain(
      "import { SidebarStatus } from '@features/app-shell/layout/enums/sidebar-status.enum';",
    );
    expect(result).toContain("template: '<router-outlet />'");
  });

  it('appends to the providers the component already has', () => {
    const own = APP.replace('selector:', 'providers: [Existing],\n  selector:');
    const result = addComponentProvider(own, 'App', PROVIDER, IMPORTS);
    expect(result).toMatch(/providers: \[Existing, \.\.\.provideLayout\(/);
  });

  it('is idempotent', () => {
    const once = addComponentProvider(APP, 'App', PROVIDER, IMPORTS);
    expect(addComponentProvider(once, 'App', PROVIDER, IMPORTS)).toBe(once);
  });

  it('fails clearly when the class is not a component', () => {
    expect(() => addComponentProvider('export class App {}\n', 'App', PROVIDER, [])).toThrow(
      /@Component/,
    );
  });
});

describe('wrapRoutesInLayout', () => {
  it('moves the routes into the children of a lazy layout route', () => {
    const result = wrapRoutesInLayout(ROUTES, MAIN);
    expect(result).toMatch(
      /path: ''[\s\S]*loadComponent: \(\) => import\('@features\/app-shell\/layout\/main\/main'\)\.then\(\(m\) => m\.Main\)/,
    );
    expect(result).toMatch(/children: \[[\s\S]*redirectTo: 'home'[\s\S]*HOME_ROUTES[\s\S]*\]/);
    // The layout route is the only top-level route.
    expect(result.match(/loadComponent/g)).toHaveLength(1);
  });

  it('wraps an empty routes array', () => {
    const result = wrapRoutesInLayout('export const routes: Routes = [];\n', MAIN);
    expect(result).toContain('children: []');
  });

  it('is idempotent', () => {
    const once = wrapRoutesInLayout(ROUTES, MAIN);
    expect(wrapRoutesInLayout(once, MAIN)).toBe(once);
  });

  it('fails clearly when there is no routes array', () => {
    expect(() => wrapRoutesInLayout('export const other = [];\n', MAIN)).toThrow(/routes/);
  });
});

describe('addRoutes with a layout route', () => {
  const FEATURE = {
    path: 'dashboard',
    lazy: { file: '@features/dashboard/dashboard.routes', exportName: 'DASHBOARD_ROUTES' },
  } as const;

  it('adds the route to the children of the layout route', () => {
    const wrapped = wrapRoutesInLayout(ROUTES, MAIN);
    const result = addRoutes(wrapped, [FEATURE]);
    expect(result.match(/path: 'dashboard'/g)).toHaveLength(1);
    expect(result.indexOf('DASHBOARD_ROUTES')).toBeGreaterThan(result.indexOf('children: ['));
    expect(result.indexOf('DASHBOARD_ROUTES')).toBeGreaterThan(result.indexOf('HOME_ROUTES'));
  });

  it('does not add a route twice inside the layout', () => {
    const once = addRoutes(wrapRoutesInLayout(ROUTES, MAIN), [FEATURE]);
    expect(addRoutes(once, [FEATURE])).toBe(once);
  });

  it('still adds to the top-level array when there is no layout route', () => {
    const result = addRoutes(ROUTES, [FEATURE]);
    expect(result.indexOf('DASHBOARD_ROUTES')).toBeGreaterThan(result.indexOf('HOME_ROUTES'));
    expect(result).not.toContain('children');
  });
});

describe('addNavigationGroups', () => {
  const GROUPS = [
    {
      label: 'Management',
      items: [
        { id: 'users', title: 'Users', icon: 'Users', link: '/users' },
        {
          id: 'settings',
          title: 'Settings',
          icon: 'Settings',
          children: [{ id: 'settings-general', title: 'General', link: '/settings/general' }],
        },
      ],
    },
  ];

  it('appends the groups after the ones the tree has', () => {
    const result = addNavigationGroups(TREE, GROUPS);
    expect(result.indexOf("label: 'General'")).toBeLessThan(result.indexOf("label: 'Management'"));
    expect(result).toContain(
      "{ id: 'users', title: 'Users', icon: 'Users', type: 'basic', link: '/users' }",
    );
  });

  it('hides an item from the sidebar when it asks for it, keeping its title and breadcrumb', () => {
    const result = addNavigationGroups(TREE, [
      {
        label: 'System',
        items: [{ id: 'prefs', title: 'Prefs', icon: 'Settings', link: '/prefs', hidden: true }],
      },
    ]);
    expect(result).toContain(
      "{ id: 'prefs', title: 'Prefs', icon: 'Settings', type: 'basic', link: '/prefs', hidden: () => true }",
    );
    expect(result.split('hidden:')).toHaveLength(2);
  });

  it('hides an item with children too', () => {
    const result = addNavigationGroups(TREE, [
      {
        label: 'System',
        items: [
          {
            id: 'tools',
            title: 'Tools',
            hidden: true,
            children: [{ id: 'tool', title: 'Tool', link: '/tool' }],
          },
        ],
      },
    ]);
    expect(result).toMatch(/type: 'collapsable',\s+hidden: \(\) => true,/);
  });

  it('marks an item with children as collapsable, without a link', () => {
    const result = addNavigationGroups(TREE, GROUPS);
    expect(result).toMatch(/id: 'settings'[\s\S]*type: 'collapsable'[\s\S]*children: \[/);
    expect(result).toContain("link: '/settings/general'");
  });

  it('recognizes a group whose label uses double quotes', () => {
    const double = TREE.replace("label: 'General'", 'label: "Management"');
    expect(addNavigationGroups(double, GROUPS)).toBe(double);
  });

  it('is idempotent: a group with the same label is not added twice', () => {
    const once = addNavigationGroups(TREE, GROUPS);
    expect(addNavigationGroups(once, GROUPS)).toBe(once);
  });

  it('fails clearly when the tree is not there', () => {
    expect(() => addNavigationGroups('export const other = [];\n', GROUPS)).toThrow(
      /APP_NAVIGATION/,
    );
  });
});
