# app-shell

The application shell: the layout that frames every page. It follows the reference application
(ADR-0008) in its first mode, a wide sidebar that floats with the header and the content floating too.

```
app-shell/
  layout/
    main/                 the layout route: sidebar + header + the routed page (<router-outlet>)
    empty/                a layout with no chrome, for pages such as a sign-in
    header/               sidebar toggle, breadcrumb, colour picker and light/dark mode
    sidebar/              brand, search, the navigation tree, user menu and preferences drawer
    enums/                SidebarStatus (expanded, collapsed)
  components/breadcrumb/  breadcrumb of the current page, with a menu for the crumbs that do not fit
  providers/              provideLayout(tree, state): what the layout needs in app.ts
  services/               LayoutService (sidebar state, mobile), the state of the folders, dropdowns
  navigation/             the navigation tree: titles, breadcrumbs and the sidebar read it
```

- The sidebar draws `navigation/navigation.data.ts`. Add a page there and it shows up, with its
  breadcrumb and title (`as generate feature <name>` does both for you).
- `app.ts` provides the layout (`provideLayout`) and `app.routes.ts` loads every page inside the
  `Main` layout route. To show a page without the shell, add a route outside of it that loads `Empty`.
- The user menu and the preferences drawer show an example identity held in the component: replace
  it with the user of your session when the project has authentication.
- The shell is client-side only for now: it reads `window` while it is built.
- The `dashboard`, `users`, `reports` and `settings` pages are examples to try the navigation; replace
  them with your product.
