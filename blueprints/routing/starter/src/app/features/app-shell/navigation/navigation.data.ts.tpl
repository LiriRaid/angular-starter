import type { NavigationGroup } from '@core/navigation/navigation.types';

/**
 * The navigation tree of the application. Page titles and breadcrumbs read it, and so does the
 * sidebar when the App Shell is added. Links are plain strings: the routes themselves stay in each
 * feature's `<feature>.routes.ts`.
 */
export const APP_NAVIGATION: readonly NavigationGroup[] = [
  {
    label: 'General',
    items: [{ id: 'home', title: 'Home', icon: 'Home', type: 'basic', link: '/home' }],
  },
  // Items nest to any depth, can be hidden from the sidebar and can require a permission:
  // {
  //   label: 'Administration',
  //   items: [
  //     {
  //       id: 'users',
  //       title: 'Users',
  //       type: 'collapsable',
  //       children: [
  //         { id: 'users-list', title: 'All users', link: '/admin/users', permission: 'users.view' },
  //       ],
  //     },
  //   ],
  // },
];
