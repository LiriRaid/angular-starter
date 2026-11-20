import { NavigationGroup, NavigationItem } from '@core/navigation/navigation.types';

function buildItemKey(prefix: string, item: NavigationItem, index: number): string {
  return `${prefix}${item.id || item.title}_${index}`;
}

export function saveExpansionState(groups: readonly NavigationGroup[]): Map<string, boolean> {
  const state = new Map<string, boolean>();

  const saveRecursively = (items: readonly NavigationItem[], prefix = ''): void => {
    items.forEach((item, index) => {
      const itemKey = buildItemKey(prefix, item, index);
      state.set(itemKey, item.unfolded || false);

      if (item.children?.length) {
        saveRecursively(item.children, `${itemKey}_`);
      }
    });
  };

  groups.forEach((group, groupIndex) => {
    saveRecursively(group.items, `group_${groupIndex}_`);
  });

  return state;
}

export function restoreExpansionState(groups: readonly NavigationGroup[], state: Map<string, boolean>): void {
  const restoreRecursively = (items: readonly NavigationItem[], prefix = ''): void => {
    items.forEach((item, index) => {
      const itemKey = buildItemKey(prefix, item, index);
      const wasExpanded = state.get(itemKey);

      if (wasExpanded !== undefined) {
        item.unfolded = wasExpanded;
      }

      if (item.children?.length) {
        restoreRecursively(item.children, `${itemKey}_`);
      }
    });
  };

  groups.forEach((group, groupIndex) => {
    restoreRecursively(group.items, `group_${groupIndex}_`);
  });
}

export function expandParentsOfActiveItem(groups: readonly NavigationGroup[], currentUrl: string, initialExpansionState: Map<string, boolean>): void {
  const expandRecursively = (items: readonly NavigationItem[], prefix = ''): boolean => {
    for (let index = 0; index < items.length; index++) {
      const item = items[index];
      const itemKey = buildItemKey(prefix, item, index);

      if (item.children?.length) {
        const found = expandRecursively(item.children, `${itemKey}_`);
        const wasInitiallyExpanded = initialExpansionState.get(itemKey) || false;

        item.unfolded = found || wasInitiallyExpanded;

        if (found) {
          return true;
        }
      }

      if (item.link && (currentUrl === item.link || currentUrl.startsWith(`${item.link}/`))) {
        return true;
      }
    }

    return false;
  };

  groups.forEach((group, groupIndex) => {
    expandRecursively(group.items, `group_${groupIndex}_`);
  });
}

export function hasAnyManualExpansion(groups: readonly NavigationGroup[], currentUrl: string, initialExpansionState: Map<string, boolean>): boolean {
  const checkItems = (items: readonly NavigationItem[], prefix = ''): boolean => {
    for (let index = 0; index < items.length; index++) {
      const item = items[index];
      const itemKey = buildItemKey(prefix, item, index);

      if (item.unfolded) {
        const isActiveRoute = !!item.link && (currentUrl === item.link || currentUrl.startsWith(`${item.link}/`));
        const hasActiveChild = item.children?.some((child) => !!child.link && (currentUrl === child.link || currentUrl.startsWith(`${child.link}/`)));
        const wasInitiallyExpanded = initialExpansionState.get(itemKey) || false;

        if (!isActiveRoute && !hasActiveChild && !wasInitiallyExpanded) {
          return true;
        }
      }

      if (item.children?.length && checkItems(item.children, `${itemKey}_`)) {
        return true;
      }
    }

    return false;
  };

  return groups.some((group, groupIndex) => checkItems(group.items, `group_${groupIndex}_`));
}

export function collapseItemsNotContainingRoute(groups: readonly NavigationGroup[], currentUrl: string): void {
  const collapseRecursively = (items: readonly NavigationItem[]): void => {
    items.forEach((item) => {
      if (!item.children?.length) {
        return;
      }

      if (!itemContainsRoute(item, currentUrl) && item.unfolded) {
        item.unfolded = false;
      }

      collapseRecursively(item.children);
    });
  };

  groups.forEach((group) => collapseRecursively(group.items));
}

export function collapseAllItems(groups: readonly NavigationGroup[]): void {
  groups.forEach((group) => {
    group.items.forEach((item) => recursivelyCollapse(item));
  });
}

function itemContainsRoute(item: NavigationItem, route: string): boolean {
  if (item.link && (route === item.link || route.startsWith(`${item.link}/`))) {
    return true;
  }

  return item.children?.some((child) => itemContainsRoute(child, route)) ?? false;
}

function recursivelyCollapse(item: NavigationItem): void {
  item.unfolded = false;

  if (item.children?.length) {
    item.children.forEach((child) => recursivelyCollapse(child));
  }
}
