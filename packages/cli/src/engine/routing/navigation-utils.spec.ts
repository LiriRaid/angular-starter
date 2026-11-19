import { rm } from 'node:fs/promises';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { loadBlueprintModule } from '../../../tests/helpers/blueprint-module.js';

/** The generated `core/navigation/navigation.utils.ts`, compiled here as plain TypeScript. */
interface Item {
  id: string;
  title: string;
  link?: string;
  icon?: string;
  type?: 'basic' | 'collapsable';
  permission?: string;
  hidden?: (item: Item) => boolean;
  children?: Item[];
}
interface Group {
  label: string;
  items: Item[];
}
interface Crumb {
  label: string;
  link?: string;
  icon?: string;
  isLast: boolean;
}
interface Utils {
  normalizeUrl(url: string): string;
  humanizeSegment(segment: string): string;
  findNavigationMatch(tree: Group[], url: string): { groupLabel: string; path: Item[] } | null;
  buildBreadcrumbs(
    tree: Group[],
    url: string,
    dynamic?: { label: string; icon?: string } | null,
  ): Crumb[];
  filterNavigation(tree: Group[], canAccess?: (permission: string) => boolean): Group[];
}

let utils: Utils;
let directory: string;

beforeAll(async () => {
  const loaded = await loadBlueprintModule<Utils>(
    'routing/starter',
    'src/app/core/navigation',
    'navigation.utils.ts',
  );
  utils = loaded.module;
  directory = loaded.directory;
});

afterAll(async () => {
  await rm(directory, { recursive: true, force: true });
});

const TREE: Group[] = [
  {
    label: 'Inbox',
    items: [
      {
        id: 'inbox',
        title: 'Inbox',
        link: '/inbox',
        icon: 'inbox',
        children: [
          { id: 'mine', title: 'My inbox', link: '/inbox/mine', icon: 'user' },
          {
            id: 'all',
            title: 'Everything',
            link: '/inbox/all',
            children: [{ id: 'archived', title: 'Archived', link: '/inbox/all/archived' }],
          },
        ],
      },
      {
        id: 'profile',
        title: 'Profile',
        link: '/profile',
        type: 'collapsable',
        hidden: () => true,
      },
    ],
  },
  {
    label: 'Admin',
    items: [
      { id: 'users', title: 'Users', link: '/admin/users', permission: 'users.view' },
      { id: 'teams', title: 'Teams', link: '/admin/teams' },
    ],
  },
];

const ids = (items: Item[] | undefined): string[] => (items ?? []).map((item) => item.id);

describe('normalizeUrl', () => {
  it('drops the query string and the fragment', () => {
    expect(utils.normalizeUrl('/inbox/mine?tab=1#top')).toBe('/inbox/mine');
    expect(utils.normalizeUrl('/inbox#top')).toBe('/inbox');
  });
});

describe('humanizeSegment', () => {
  it('turns a route segment into a readable label', () => {
    expect(utils.humanizeSegment('my-profile')).toBe('My Profile');
    expect(utils.humanizeSegment('users')).toBe('Users');
  });
});

describe('findNavigationMatch', () => {
  it('returns the item chain from the root and the label of its group', () => {
    const match = utils.findNavigationMatch(TREE, '/inbox/all/archived');
    expect(ids(match?.path)).toEqual(['inbox', 'all', 'archived']);
    expect(match?.groupLabel).toBe('Inbox');
  });

  it('ignores the query string and the fragment', () => {
    expect(ids(utils.findNavigationMatch(TREE, '/inbox/mine?x=1#top')?.path)).toEqual([
      'inbox',
      'mine',
    ]);
  });

  it('matches routes below an item but only on a segment boundary', () => {
    expect(ids(utils.findNavigationMatch(TREE, '/admin/users/42')?.path)).toEqual(['users']);
    expect(utils.findNavigationMatch(TREE, '/inboxes')).toBeNull();
  });

  it('prefers the longest link over a shorter sibling listed first', () => {
    const tree: Group[] = [
      {
        label: 'G',
        items: [
          { id: 'a', title: 'A', link: '/a' },
          { id: 'ab', title: 'AB', link: '/a/b' },
        ],
      },
    ];
    expect(ids(utils.findNavigationMatch(tree, '/a/b')?.path)).toEqual(['ab']);
    expect(ids(utils.findNavigationMatch(tree, '/a/c')?.path)).toEqual(['a']);
  });

  it('still matches hidden items, so their pages get a title and breadcrumbs', () => {
    expect(ids(utils.findNavigationMatch(TREE, '/profile')?.path)).toEqual(['profile']);
  });

  it('returns null when nothing matches', () => {
    expect(utils.findNavigationMatch(TREE, '/nowhere')).toBeNull();
    expect(utils.findNavigationMatch(TREE, '/')).toBeNull();
    expect(utils.findNavigationMatch([], '/inbox')).toBeNull();
  });
});

describe('buildBreadcrumbs', () => {
  it('lists the group, then the item chain, and marks the last crumb', () => {
    expect(utils.buildBreadcrumbs(TREE, '/admin/users')).toEqual([
      { label: 'Admin', isLast: false },
      { label: 'Users', isLast: true },
    ]);
  });

  it('skips the group when it repeats the first item', () => {
    expect(utils.buildBreadcrumbs(TREE, '/inbox/mine').map((crumb) => crumb.label)).toEqual([
      'Inbox',
      'My inbox',
    ]);
  });

  it('links every crumb but the last one and gives the icon to the last item only', () => {
    expect(utils.buildBreadcrumbs(TREE, '/inbox/mine')).toEqual([
      { label: 'Inbox', link: '/inbox', isLast: false },
      { label: 'My inbox', icon: 'user', isLast: true },
    ]);
  });

  it('does not link collapsable items', () => {
    const tree: Group[] = [
      {
        label: 'G',
        items: [
          {
            id: 'settings',
            title: 'Settings',
            link: '/settings',
            type: 'collapsable',
            children: [{ id: 'security', title: 'Security', link: '/settings/security' }],
          },
        ],
      },
    ];
    const [group, settings, security] = utils.buildBreadcrumbs(tree, '/settings/security');
    expect(group).toMatchObject({ label: 'G', isLast: false });
    expect(settings).toEqual({ label: 'Settings', isLast: false });
    expect(security).toMatchObject({ label: 'Security', isLast: true });
  });

  it('leaves the group out when the first item is hidden', () => {
    expect(utils.buildBreadcrumbs(TREE, '/profile').map((crumb) => crumb.label)).toEqual([
      'Profile',
    ]);
  });

  it('appends a dynamic crumb after the item chain and keeps the chain linked', () => {
    expect(utils.buildBreadcrumbs(TREE, '/admin/users/42', { label: 'Ada', icon: 'user' })).toEqual(
      [
        { label: 'Admin', isLast: false },
        { label: 'Users', link: '/admin/users', isLast: false },
        { label: 'Ada', icon: 'user', isLast: true },
      ],
    );
  });

  it('falls back to the route segments when no item matches', () => {
    expect(utils.buildBreadcrumbs(TREE, '/my-profile/edit-data?x=1')).toEqual([
      { label: 'My Profile', isLast: false },
      { label: 'Edit Data', isLast: true },
    ]);
  });

  it('puts the dynamic crumb after humanized segments too, and is empty for the root', () => {
    expect(
      utils.buildBreadcrumbs([], '/reports', { label: 'Q4' }).map((crumb) => crumb.label),
    ).toEqual(['Reports', 'Q4']);
    expect(utils.buildBreadcrumbs(TREE, '/')).toEqual([]);
  });
});

describe('filterNavigation', () => {
  it('drops hidden items and groups that end up empty', () => {
    const filtered = utils.filterNavigation(TREE);
    expect(ids(filtered[0]?.items)).toEqual(['inbox']);
    expect(filtered).toHaveLength(2);
  });

  it('drops the items whose permission is denied, children included', () => {
    const filtered = utils.filterNavigation(TREE, (permission) => permission !== 'users.view');
    expect(ids(filtered[1]?.items)).toEqual(['teams']);
  });

  it('keeps an item without permission whatever the check says', () => {
    const filtered = utils.filterNavigation(TREE, () => false);
    expect(ids(filtered[1]?.items)).toEqual(['teams']);
  });

  it('drops a parent without link when every child is gone, and the empty group', () => {
    const tree: Group[] = [
      {
        label: 'G',
        items: [
          {
            id: 'parent',
            title: 'Parent',
            children: [{ id: 'child', title: 'Child', link: '/c', permission: 'c.view' }],
          },
        ],
      },
    ];
    expect(utils.filterNavigation(tree, () => false)).toEqual([]);
    expect(ids(utils.filterNavigation(tree, () => true)[0]?.items)).toEqual(['parent']);
  });

  it('does not change the tree it receives', () => {
    const before = JSON.stringify(TREE);
    utils.filterNavigation(TREE, () => false);
    expect(JSON.stringify(TREE)).toBe(before);
  });
});
