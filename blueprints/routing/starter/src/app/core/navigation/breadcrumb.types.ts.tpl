export interface BreadcrumbItem {
  readonly label: string;
  /** Absent for the last crumb and for entries that cannot be navigated to. */
  readonly link?: string;
  readonly icon?: string;
  readonly isLast: boolean;
}

/** The crumb a detail page adds after the ones the navigation tree provides (for example a name). */
export interface DynamicBreadcrumb {
  readonly label: string;
  readonly icon?: string;
}
