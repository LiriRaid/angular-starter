import { NavigationGroup, NavigationItem } from '@core/navigation/navigation.types';

export function normalizeSidebarUrl(url: string): string {
  return url.split('?')[0].split('#')[0];
}

export function isNavigationItemActive(item: NavigationItem, currentUrl: string): boolean {
  if (item.link && (currentUrl === item.link || currentUrl.startsWith(item.link + '/'))) {
    return true;
  }

  return !!item.children?.some((child) => isNavigationItemActive(child, currentUrl));
}

export function hasActiveDescendant(items: readonly NavigationItem[] | undefined, currentUrl: string): boolean {
  return !!items?.some((item) => isNavigationItemActive(item, currentUrl));
}

export function filterNavigationGroups(groups: readonly NavigationGroup[], query: string, isHidden: (item: NavigationItem) => boolean): readonly NavigationGroup[] {
  if (!query) return groups;

  return groups
    .map((group) => ({
      ...group,
      items: group.items.map((item) => filterNavigationItem(item, query, isHidden)).filter((item): item is NavigationItem => !!item),
    }))
    .filter((group) => group.items.length > 0);
}

export function filterNavigationItem(item: NavigationItem, query: string, isHidden: (item: NavigationItem) => boolean): NavigationItem | null {
  if (isHidden(item)) return null;

  const title = (item.title ?? '').toLowerCase();
  const matchesSelf = title.includes(query);

  if (!item.children?.length) return matchesSelf ? item : null;

  const filteredChildren = item.children.map((child) => filterNavigationItem(child, query, isHidden)).filter((child): child is NavigationItem => !!child);

  if (matchesSelf || filteredChildren.length) {
    return {
      ...item,
      unfolded: true,
      children: filteredChildren.length ? filteredChildren : item.children,
    };
  }

  return null;
}

export function getFolderRootLink(folder: NavigationItem): string | null {
  const leafLinks = collectLeafLinks(folder);
  if (!leafLinks.length) return null;

  const split = leafLinks.map((link) => link.split('/').filter(Boolean));
  const minLen = Math.min(...split.map((segments) => segments.length));

  const prefix: string[] = [];
  for (let index = 0; index < minLen; index++) {
    const segment = split[0][index];
    if (split.every((segments) => segments[index] === segment)) {
      prefix.push(segment);
    } else {
      break;
    }
  }

  return prefix.length ? `/${prefix.join('/')}` : null;
}

function collectLeafLinks(item: NavigationItem): string[] {
  const stack: NavigationItem[] = [...(item.children ?? [])];
  const links: string[] = [];

  while (stack.length) {
    const current = stack.shift()!;
    if (current.link) {
      links.push(current.link);
    } else if (current.children?.length) {
      stack.unshift(...current.children);
    }
  }

  return links;
}

/** An item of the navigation that leads somewhere, with the titles of the folders that hold it. */
export interface NavigationEntry {
  readonly id: string;
  readonly title: string;
  readonly link: string;
  readonly icon?: string;
  /** The titles of the folders it is inside, outermost first. */
  readonly trail: readonly string[];
}

/** Every item with a link, in the order of the tree; hidden items and what they hold are left out. */
export function flattenNavigation(groups: readonly NavigationGroup[], isHidden: (item: NavigationItem) => boolean): readonly NavigationEntry[] {
  const entries: NavigationEntry[] = [];

  const visit = (item: NavigationItem, trail: readonly string[], inheritedIcon: string | undefined): void => {
    if (isHidden(item)) return;
    const icon = item.icon ?? inheritedIcon;
    if (item.link) entries.push({ id: item.id, title: item.title, link: item.link, icon, trail });
    for (const child of item.children ?? []) visit(child, [...trail, item.title], icon);
  };

  for (const group of groups) for (const item of group.items) visit(item, [], undefined);
  return entries;
}

const plain = (text: string): string => text.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase();

/** The entries whose title, or the title of a folder that holds them, contains `query` (case and accents do not matter). */
export function searchNavigation(entries: readonly NavigationEntry[], query: string): readonly NavigationEntry[] {
  const needle = plain(query.trim());
  if (!needle) return [];
  return entries.filter((entry) => [entry.title, ...entry.trail].some((title) => plain(title).includes(needle)));
}
