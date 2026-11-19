/** One entry of the navigation tree. The same tree feeds page titles, breadcrumbs and the sidebar. */
export interface NavigationItem {
  readonly id: string;
  readonly title: string;
  /** Absolute route of the item. Items that only group other items can leave it out. */
  readonly link?: string;
  /** Name of the icon; the icon component decides what the names mean. */
  readonly icon?: string;
  /** `collapsable` items open their children instead of navigating, so breadcrumbs do not link them. */
  readonly type?: 'basic' | 'collapsable';
  /** Used as the `<meta name="description">` of the page. */
  readonly description?: string;
  /** Opaque permission name. `filterNavigation` hands it to the `canAccess` function you provide. */
  readonly permission?: string;
  /** Items hidden from the sidebar still get a page title and breadcrumbs. */
  readonly hidden?: (item: NavigationItem) => boolean;
  readonly children?: readonly NavigationItem[];
}

export interface NavigationGroup {
  readonly label: string;
  readonly items: readonly NavigationItem[];
}
