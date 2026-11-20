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
