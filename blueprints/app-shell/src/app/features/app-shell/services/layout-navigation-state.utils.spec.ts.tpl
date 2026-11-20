import { describe, expect, it } from 'vitest';
import { collapseAllItems, collapseItemsNotContainingRoute, expandParentsOfActiveItem, hasAnyManualExpansion, restoreExpansionState, saveExpansionState } from './layout-navigation-state.utils';
import type { NavigationGroup } from '@core/navigation/navigation.types';

function makeGroups(): readonly NavigationGroup[] {
  return [
    {
      label: 'Group A',
      items: [
        {
          id: 'parent',
          title: 'Parent',
          unfolded: true,
          children: [{ id: 'child', title: 'Child', link: '/settings/general' }],
        },
        { id: 'leaf', title: 'Leaf', link: '/dashboard/overview' },
      ],
    },
  ];
}

describe('saveExpansionState', () => {
  it('captures the unfolded state of each item into a Map', () => {
    const groups = makeGroups();
    const state = saveExpansionState(groups);

    expect(state.size).toBeGreaterThan(0);
    const parentEntry = [...state.entries()].find(([, v]) => v === true);
    expect(parentEntry).toBeDefined();
  });

  it('records false for items that are not unfolded', () => {
    const groups = makeGroups();
    groups[0].items[0].unfolded = false;
    const state = saveExpansionState(groups);

    const falseEntries = [...state.values()].filter((v) => v === false);
    expect(falseEntries.length).toBeGreaterThan(0);
  });
});

describe('restoreExpansionState', () => {
  it('restores unfolded state from the saved Map', () => {
    const groups = makeGroups();
    const state = saveExpansionState(groups);

    groups[0].items[0].unfolded = false;
    restoreExpansionState(groups, state);

    expect(groups[0].items[0].unfolded).toBe(true);
  });
});

describe('expandParentsOfActiveItem', () => {
  it('expands parent items whose children contain the active route', () => {
    const groups = makeGroups();
    groups[0].items[0].unfolded = false;
    const initial = saveExpansionState(groups);

    expandParentsOfActiveItem(groups, '/settings/general', initial);

    expect(groups[0].items[0].unfolded).toBe(true);
  });

  it('does not expand items unrelated to the current route', () => {
    const groups = makeGroups();
    groups[0].items[0].unfolded = false;
    const initial = saveExpansionState(groups);

    expandParentsOfActiveItem(groups, '/dashboard/overview', initial);

    expect(groups[0].items[0].unfolded).toBe(false);
  });
});

describe('hasAnyManualExpansion', () => {
  it('returns false when no items are unfolded beyond what the route requires', () => {
    const groups = makeGroups();
    groups[0].items[0].unfolded = false;
    const initial = saveExpansionState(groups);

    expect(hasAnyManualExpansion(groups, '/settings/general', initial)).toBe(false);
  });

  it('returns true when an item is unfolded that does not belong to the current route', () => {
    const groups = makeGroups();
    const initial = new Map<string, boolean>();

    expect(hasAnyManualExpansion(groups, '/dashboard/overview', initial)).toBe(true);
  });
});

describe('collapseItemsNotContainingRoute', () => {
  it('collapses items whose subtree does not contain the current route', () => {
    const groups = makeGroups();
    groups[0].items[0].unfolded = true;

    collapseItemsNotContainingRoute(groups, '/dashboard/overview');

    expect(groups[0].items[0].unfolded).toBe(false);
  });

  it('leaves items that contain the current route expanded', () => {
    const groups = makeGroups();
    groups[0].items[0].unfolded = true;

    collapseItemsNotContainingRoute(groups, '/settings/general');

    expect(groups[0].items[0].unfolded).toBe(true);
  });
});

describe('collapseAllItems', () => {
  it('sets every item to unfolded = false', () => {
    const groups = makeGroups();

    collapseAllItems(groups);

    const allCollapsed = groups.every((g) =>
      g.items.every((item) => {
        const childrenCollapsed = (item.children ?? []).every((c) => !c.unfolded);
        return !item.unfolded && childrenCollapsed;
      }),
    );
    expect(allCollapsed).toBe(true);
  });
});
