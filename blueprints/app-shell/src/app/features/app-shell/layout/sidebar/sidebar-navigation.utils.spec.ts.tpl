import { NavigationItem } from '@core/navigation/navigation.types';
import { filterNavigationGroups, flattenNavigation, getFolderRootLink, hasActiveDescendant, isNavigationItemActive, normalizeSidebarUrl, searchNavigation } from './sidebar-navigation.utils';

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

  describe('flattenNavigation', () => {
    const tree = [
      {
        label: 'General',
        items: [
          { id: 'home', title: 'Inicio', link: '/home' },
          { id: 'secret', title: 'Secreto', link: '/secret', hidden: () => true },
        ],
      },
      {
        label: 'Sistema',
        items: [
          {
            id: 'settings',
            title: 'Configuración',
            children: [
              { id: 'general', title: 'General', link: '/settings/general' },
              { id: 'notifications', title: 'Notificaciones', link: '/settings/notifications', children: [{ id: 'email', title: 'Correo', link: '/settings/notifications/email' }] },
            ],
          },
        ],
      },
    ] as const;

    it('lists every item that has a link, with the titles of the folders that hold it', () => {
      const entries = flattenNavigation(tree, () => false);
      expect(entries.map((entry) => entry.link)).toEqual(['/home', '/secret', '/settings/general', '/settings/notifications', '/settings/notifications/email']);
      expect(entries.find((entry) => entry.link === '/settings/notifications/email')?.trail).toEqual(['Configuración', 'Notificaciones']);
      expect(entries.find((entry) => entry.link === '/home')?.trail).toEqual([]);
    });

    it('leaves out the hidden items and what is inside them', () => {
      const entries = flattenNavigation(tree, (item) => !!item.hidden?.(item));
      expect(entries.map((entry) => entry.link)).not.toContain('/secret');
    });

    it('takes the icon of the item, or the one of its folder', () => {
      const withIcons = [{ label: 'A', items: [{ id: 'f', title: 'Folder', icon: 'Settings', children: [{ id: 'c', title: 'Child', link: '/c' }] }] }];
      expect(flattenNavigation(withIcons, () => false)[0].icon).toBe('Settings');
    });
  });

  describe('searchNavigation', () => {
    const entries = [
      { id: 'home', title: 'Inicio', link: '/home', trail: [] as string[] },
      { id: 'general', title: 'General', link: '/settings/general', trail: ['Configuración'] },
      { id: 'email', title: 'Correo', link: '/settings/email', trail: ['Configuración', 'Notificaciones'] },
    ];

    it('matches the title, ignoring case and accents', () => {
      expect(searchNavigation(entries, 'INICIO').map((entry) => entry.id)).toEqual(['home']);
      expect(searchNavigation(entries, 'configuracion').map((entry) => entry.id)).toEqual(['general', 'email']);
    });

    it('matches the folders that hold the item too', () => {
      expect(searchNavigation(entries, 'notific').map((entry) => entry.id)).toEqual(['email']);
    });

    it('finds nothing for an empty query', () => {
      expect(searchNavigation(entries, '   ')).toEqual([]);
    });
  });
});
