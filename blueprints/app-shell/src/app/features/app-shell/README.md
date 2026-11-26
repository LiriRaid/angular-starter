# app-shell

The application shell: the layout that frames every page. It starts as the reference application
(ADR-0008): a wide sidebar that floats with the header and the content floating too. The shell has more
than one layout (ADR-0029) and the administrator switches between them at run time, from the design
preferences page.

```
app-shell/
  layout/
    main/                 the layout route: sidebar + header + the routed page (<router-outlet>)
    empty/                a layout with no chrome, for pages such as a sign-in
    header/               sidebar toggle, breadcrumb (or the search of the compact layouts), colour picker
                          and light/dark mode
    sidebar/              brand, search, the navigation tree and the user menu; sidebar-rail/ is the
                          compact version: the logo and the icon above the text of each page
    design-update-notice/ the alert that tells the users the design changed, with a button to reload
    enums/                SidebarStatus (expanded, collapsed)
  components/breadcrumb/  breadcrumb of the current page, with a menu for the crumbs that do not fit
  providers/              provideLayout(tree, state): what the layout needs in app.ts
  services/               LayoutService (sidebar state, mobile), the state of the folders, dropdowns
  navigation/             the navigation tree: titles, breadcrumbs and the sidebar read it
```

- The sidebar draws `navigation/navigation.data.ts`. Add a page there and it shows up, with its
  breadcrumb and title (`sa generate feature <name>` does both for you).
- `app.ts` provides the layout (`provideLayout`) and `app.routes.ts` loads every page inside the
  `Main` layout route. To show a page without the shell, add a route outside of it that loads `Empty`.
- The user menu shows an example identity held in the component: replace it with the user of your
  session when the project has authentication.
- "Preferencias de Diseño" in the user menu opens `/preference-design` (`features/preference-design`):
  a page with the tabs Apariencia, Tema, UI and Otros whose changes apply in real time. The logic is
  `core/design-preferences` (ADR-0010 and ADR-0029).
- **The layout is a variant, not a set of files.** Each layout is a mix of three traits (compact,
  floating, transparent). `DesignPreferencesService.layoutTraits()` is a signal the components read
  (`Sidebar.compact`, `Header.compact`) and the same traits are on `html`, where
  `src/styles/features/layout-modes-styles.css` reads them. `compact-joined` and `floating-wide` are
  built; the others are shown as under construction. The compact layouts show a search in the header
  instead of the breadcrumb, and the user menu (with its presence) is in the header instead of the sidebar. Below 1024 px every layout uses the same drawer.
- What the administrator saves is kept by your server, not by the browser, and the users who are online
  get an alert to reload: `docs/design-preferences.md` explains how to connect it.
- `sa add presence` adds the status of the user (online, away, busy, invisible) to the user menu and the
  presence dot to its avatars; see `core/presence`.
- `features/home` is a welcome page (`home.data.ts` holds its cards and links): edit it or replace it
  with your own start page.
- The shell is client-side only for now: it reads `window` while it is built.
- The `dashboard`, `users`, `reports` and `settings` pages are examples to try the navigation; replace
  them with your product.
