import { buildBreadcrumbs, filterNavigation, findNavigationMatch } from './navigation.utils';
import type { NavigationGroup } from './navigation.types';

const TREE: NavigationGroup[] = [
  {
    label: 'General',
    items: [
      { id: 'home', title: 'Home', link: '/home', icon: 'house' },
      { id: 'secret', title: 'Secret', link: '/secret', hidden: () => true },
    ],
  },
  {
    label: 'Admin',
    items: [
      {
        id: 'users',
        title: 'Users',
        link: '/admin/users',
        permission: 'users.view',
        children: [{ id: 'roles', title: 'Roles', link: '/admin/users/roles' }],
      },
    ],
  },
];

describe('findNavigationMatch', () => {
  it('finds the item chain and the group of a URL', () => {
    const match = findNavigationMatch(TREE, '/admin/users/roles?tab=1');
    expect(match?.path.map((item) => item.id)).toEqual(['users', 'roles']);
    expect(match?.groupLabel).toBe('Admin');
  });

  it('matches routes below an item and nothing else', () => {
    expect(findNavigationMatch(TREE, '/admin/users/42')?.path.at(-1)?.id).toBe('users');
    expect(findNavigationMatch(TREE, '/homes')).toBeNull();
  });
});

describe('buildBreadcrumbs', () => {
  it('lists the group and the items, and only the last crumb has no link', () => {
    expect(buildBreadcrumbs(TREE, '/admin/users/roles')).toEqual([
      { label: 'Admin', isLast: false },
      { label: 'Users', link: '/admin/users', isLast: false },
      { label: 'Roles', isLast: true },
    ]);
  });

  it('adds a dynamic crumb at the end', () => {
    const crumbs = buildBreadcrumbs(TREE, '/admin/users/42', { label: 'Ada' });
    expect(crumbs.map((crumb) => crumb.label)).toEqual(['Admin', 'Users', 'Ada']);
    expect(crumbs.at(-1)?.isLast).toBe(true);
  });

  it('uses the route segments when the tree has no item for the URL', () => {
    expect(buildBreadcrumbs(TREE, '/my-reports').map((crumb) => crumb.label)).toEqual([
      'My Reports',
    ]);
  });
});

describe('filterNavigation', () => {
  it('drops hidden items and the ones the user cannot access', () => {
    const visible = filterNavigation(TREE, (permission) => permission !== 'users.view');
    expect(visible.map((group) => group.label)).toEqual(['General']);
    expect(visible[0]?.items.map((item) => item.id)).toEqual(['home']);
  });
});
