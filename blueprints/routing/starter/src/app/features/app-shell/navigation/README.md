# navigation

`navigation.data.ts` is the one navigation tree of the application: groups, items and children.
Page titles and breadcrumbs read it already; the sidebar will read it with the App Shell.

- Add an item with an `id`, a `title` and the absolute `link` of its route. `children` nest to any
  depth. `hidden` keeps an item out of the sidebar while it still gets a title and breadcrumbs.
  `permission` is an opaque name: pass your own check to `filterNavigation`
  (`@core/navigation/navigation.utils`) to decide what a user sees.
- Links are plain strings. The routes stay in each feature's `<feature>.routes.ts`; `app.routes.ts`
  only loads them.
- The services live in `core/navigation` and receive the tree through `provideNavigation(...)` in
  `app.config.ts`, so `core` never imports from here.
- A detail page can add a last crumb with `inject(BreadcrumbService).setDynamicLabel('Ada')`,
  once it has its data.
