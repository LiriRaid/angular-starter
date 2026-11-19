import type { BreadcrumbItem, DynamicBreadcrumb } from './breadcrumb.types';
import type { NavigationGroup, NavigationItem } from './navigation.types';

/** The item chain (root first) that matches a URL, and the label of the group it belongs to. */
export interface NavigationMatch {
  readonly groupLabel: string;
  readonly path: readonly NavigationItem[];
}

export function normalizeUrl(url: string): string {
  return url.split('?')[0]?.split('#')[0] ?? '';
}

/** `my-profile` becomes `My Profile`. */
export function humanizeSegment(segment: string): string {
  return segment
    .split('-')
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');
}

/**
 * Finds the item for a URL. An item matches when the URL equals its link or continues it after a
 * `/`; the longest link wins, then the deepest item, then the first one in the tree.
 */
export function findNavigationMatch(
  tree: readonly NavigationGroup[],
  url: string,
): NavigationMatch | null {
  const target = normalizeUrl(url);
  let best: NavigationMatch | null = null;

  const visit = (
    items: readonly NavigationItem[],
    parents: readonly NavigationItem[],
    groupLabel: string,
  ): void => {
    for (const item of items) {
      const path = [...parents, item];
      const matches = item.link && (target === item.link || target.startsWith(`${item.link}/`));
      if (matches && (!best || isBetter(path, best.path))) best = { groupLabel, path };
      if (item.children) visit(item.children, path, groupLabel);
    }
  };
  for (const group of tree) visit(group.items, [], group.label);
  return best;
}

function isBetter(
  candidate: readonly NavigationItem[],
  current: readonly NavigationItem[],
): boolean {
  const candidateLink = candidate.at(-1)?.link?.length ?? 0;
  const currentLink = current.at(-1)?.link?.length ?? 0;
  if (candidateLink !== currentLink) return candidateLink > currentLink;
  return candidate.length > current.length;
}

/**
 * The breadcrumbs of a URL: the group, the item chain and an optional dynamic crumb. A URL that
 * matches no item falls back to its route segments.
 */
export function buildBreadcrumbs(
  tree: readonly NavigationGroup[],
  url: string,
  dynamic: DynamicBreadcrumb | null = null,
): BreadcrumbItem[] {
  const match = findNavigationMatch(tree, url);
  const crumbs: Omit<BreadcrumbItem, 'isLast'>[] = [];

  if (match) {
    const group = match.groupLabel.trim();
    const [first] = match.path;
    const repeatsFirst = group.toLowerCase() === first?.title.trim().toLowerCase();
    if (group && first && !isHidden(first) && !repeatsFirst) crumbs.push({ label: group });

    match.path.forEach((item, index) => {
      const isLastItem = index === match.path.length - 1;
      crumbs.push({
        label: item.title,
        link: item.type === 'collapsable' ? undefined : item.link,
        icon: isLastItem ? item.icon : undefined,
      });
    });
  } else {
    for (const segment of normalizeUrl(url).split('/').filter(Boolean)) {
      crumbs.push({ label: humanizeSegment(segment) });
    }
  }

  if (dynamic) crumbs.push({ label: dynamic.label, icon: dynamic.icon });

  return crumbs.map((crumb, index) => {
    const isLast = index === crumbs.length - 1;
    return { ...crumb, link: isLast ? undefined : crumb.link, isLast };
  });
}

/**
 * The tree a sidebar shows: without hidden items, without the ones `canAccess` denies, and without
 * the groups or link-less parents that end up empty. The tree it receives is not changed.
 */
export function filterNavigation(
  tree: readonly NavigationGroup[],
  canAccess: (permission: string) => boolean = () => true,
): NavigationGroup[] {
  const filterItems = (items: readonly NavigationItem[]): NavigationItem[] =>
    items.flatMap((item) => {
      const denied = item.permission !== undefined && !canAccess(item.permission);
      if (isHidden(item) || denied) return [];
      if (!item.children) return [item];
      const children = filterItems(item.children);
      return children.length === 0 && !item.link ? [] : [{ ...item, children }];
    });

  return tree.flatMap((group) => {
    const items = filterItems(group.items);
    return items.length === 0 ? [] : [{ ...group, items }];
  });
}

function isHidden(item: NavigationItem): boolean {
  return item.hidden?.(item) ?? false;
}
