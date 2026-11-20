# ADR-0008: The App Shell of the reference application, first layout mode

- Status: accepted
- Date: 2026-11-20
- Deciders: project maintainer

## Context

ADR-0002 reserved `features/app-shell` for the layout, sidebar and header, ADR-0003 left the
navigation tree ready for a sidebar and ADR-0007 ported the design tokens (`--app-sidebar-*`,
`--app-breadcrumb-*`, `--app-shell-bg`, `--app-container-*`) and the `as-` components. What is still
missing is the shell itself. The maintainer's requirement is the one of ADR-0007: a generated project
is the reference application "100% the same, except the business". The first layout mode is the
reference's: a wide sidebar that floats, with the header and the content also floating (the "Flotante
(ancho)" mode of the maintainer's demo). The other modes (compact sidebar, transparent sidebar) and
the settings drawer that switches them at run time come later, one by one.

## Decision

1. **A new option, `appShell`: `none` or `starter`.** It is chosen like the architecture or the
   routing: a question of the wizard with its documentation link, `--app-shell <id>`, `as list`,
   `as add app-shell`. `none` keeps the project as it is without a shell. `starter` is the
   default of `--defaults` (the complete build) when the project can take it.
2. **Requirements.** `starter` needs the Screaming Architecture (it lives in `features/app-shell`),
   Angular Starter Routing (the sidebar and the breadcrumb read its tree), Tailwind CSS and Lucide
   Icons (the design and the components), and Client-Side Rendering (decision 10). The registry declares them, so the wizard forces or hides
   what it cannot take and `as new` rejects the rest. New requirement keys, `routing` and `rendering`, are added.
3. **Structure, as in the reference** (`src/app/features/app-shell`): `layout/main`, `layout/empty`,
   `layout/header`, `layout/sidebar` (with `user-menu` and `user-preferences`), `layout/enums`,
   `components/breadcrumb`, `providers/layout.providers.ts`, and `services/` (`LayoutService`, its
   navigation-state utilities, `DropdownCoordinatorService`), each with its spec. Selectors keep the
   reference's pattern (`<prefix>-main`, `<prefix>-sidebar`, ...). The `navigation/` folder and the
   title strategy already exist from ADR-0003 and are not duplicated. The call widget is not ported.
4. **Styles.** `src/styles/features/{sidebar,breadcrumb,user-menu}-styles.css`, imported from
   `styles.css` after the component styles, as in the reference; the layout, header and preferences
   keep their component stylesheets. Classes and variables are renamed like ADR-0007 (`omni-btn` to
   `as-btn`, `--omni-*` to `--as-*`).
5. **No business.** Not ported: authentication and permissions, presence and statuses, the profile
   modal and logout, notifications, "new ticket", the AWS ecosystem panel, the help button, the unread
   badges of tickets and conversations, the welcome toast, and the GSAP animation of the profile
   buttons. What remains is the structure: the user menu shows an example identity held in signals
   of the component (name, role, user name) and opens the preferences drawer; the header has the
   sidebar toggle, the breadcrumb, the colour picker and the light/dark toggle; the brand is the
   project name. The texts and comments of the ported files stay in the reference's language, as in
   ADR-0007. The example identity in the reference's drawer is replaced by neutral text.
6. **Composition.** `app.ts` gets `providers: [...provideLayout(APP_NAVIGATION, SidebarStatus.EXPANDED)]`
   and keeps its `<router-outlet />`. `provideLayout` provides the sidebar tree token, the initial
   state and `LayoutService`; the breadcrumb service and the tree token already come from
   `provideNavigation`. `app.routes.ts` wraps the routes in the `Main` layout route (a lazy
   component with the existing routes as `children`), and `as generate feature` adds its lazy route to
   those children when the layout route is there.
7. **A tree to try.** The routing's tree has one page, so the shell adds four mock features to
   `home` (which already exists): `dashboard`, `users`, `reports` and `settings` (with the children
   `general` and `notifications`). Each has routes, a component with example data and a spec, a
   lazy route and its navigation entry, in three groups (General, Management, System), so the first
   thing a developer sees is the shell, and can try the sidebar, nested items, the search, the
   breadcrumb and the titles before replacing the examples with the product.
8. **`NavigationItem.unfolded`.** The sidebar keeps its expanded folders on the tree, as the
   reference does, so the item type gets an optional, mutable `unfolded`.
9. **Components.** The shell brings the design base and the components it uses (icon, button,
   search, tooltip, popover, drawer, tabs, toggle, avatar, theme-color-picker, toast and what those
   import), whatever `components` says; `as add components` completes the rest without
   touching them. Lucide Icons is implied, as for the components.
10. **Client-side only for now.** The shell is the reference's code: it reads `window` while it is
    built, and `ng build` of a server-rendered project fails prerendering it (verified). Adapting it
    is left to a later change, following the maintainer's portfolio project; until then the
    option requires `rendering: csr`, so `--defaults --rendering ssr` leaves the shell out and an
    explicit `--app-shell starter --rendering ssr` is refused with a message. Dropping that one
    requirement is the change that enables it.

## Alternatives considered

- A yes/no flag outside the option lists: rejected, the maintainer wants it chosen like the other
  options, with its explanation and link.
- Require the whole `all` collection: rejected, it would generate 26 components for 12 used.
- Port the shell without example features: rejected by the maintainer, there would be nothing to
  navigate.
- Keep the expansion state of the folders in a signal of `LayoutService` instead of on the tree:
  cleaner, but not the reference's structure.
- Port the business pieces behind interfaces (auth, presence): rejected, the starter ships no
  business.

## Consequences

- Positive: a generated project opens in the reference's look and feel with working navigation; the
  next layout modes are changes to one folder; `as add app-shell` brings the shell to a project made
  with the routing and the design.
- Negative: more files in a new project (the shell, the components it needs, five features); the
  texts stay in Spanish; the shell does not render on the server (see decision 10).
- Follow-up: the other layout modes and the settings drawer; server rendering; the demo's "Mostrar
  breadcrumb" and density preferences; translating texts and comments.
