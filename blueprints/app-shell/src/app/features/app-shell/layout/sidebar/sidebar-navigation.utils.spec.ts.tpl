import { NavigationItem } from '@core/navigation/navigation.types';
import { filterNavigationGroups, getFolderRootLink, hasActiveDescendant, isNavigationItemActive, normalizeSidebarUrl } from './sidebar-navigation.utils';

describe('sidebar-navigation.utils', () => {
  const navigationTree = [
    {
      label: 'Sistema',
      items: [
        {
          id: '1',
          title: 'Configuración',
          children: [
            {
              id: '11',
              title: 'General',
              link: '/settings/general',
            },
            {
              id: '12',
              title: 'Notificaciones',
              link: '/settings/notifications',
            },
          ],
        },
      ],
    },
  ];

  it('normalizes URLs by removing query params and fragments', () => {
    expect(normalizeSidebarUrl('/dashboard?tab=open#stats')).toBe('/dashboard');
  });

  it('detects active items and descendants from the current URL', () => {
    const folder = navigationTree[0].items[0];

    expect(isNavigationItemActive(folder, '/settings/notifications')).toBe(true);
    expect(hasActiveDescendant(folder.children, '/settings/notifications')).toBe(true);
  });

  it('filters navigation groups while keeping matching parents unfolded', () => {
    const filtered = filterNavigationGroups(navigationTree, 'notificaciones', () => false);

    expect(filtered.length).toBe(1);
    expect(filtered[0].items[0].unfolded).toBe(true);
    expect(filtered[0].items[0].children?.map((item) => item.title)).toEqual(['Notificaciones']);
  });

  it('builds the common root link for a folder from its leaf links', () => {
    const folder = navigationTree[0].items[0] as NavigationItem;

    expect(getFolderRootLink(folder)).toBe('/settings');
  });
});
