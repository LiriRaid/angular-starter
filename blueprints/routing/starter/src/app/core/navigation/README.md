# navigation

Infrastructure that turns the navigation tree into page titles and breadcrumbs.

- `navigation.types.ts` — the tree (`NavigationGroup`, `NavigationItem`).
- `navigation.utils.ts` — pure functions: find the item of a URL, build breadcrumbs, filter the tree.
- `navigation.tokens.ts` / `navigation.providers.ts` — `provideNavigation(tree, { appName })` registers
  the tree, `NavigationTitleStrategy` and `BreadcrumbService`.
- The tree itself lives in `features/app-shell/navigation/navigation.data.ts`; `core` receives it
  through `NAV_TREE_TOKEN` and never imports it.
