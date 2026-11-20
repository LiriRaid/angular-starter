# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project intends to adhere to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) once released.

## [Unreleased]

### Changed

- The wizard of `as new` is a chained flow (ADR-0010 and plan 0008): architecture, routing, stylesheet,
  rendering, the purpose of Starter SSR, shell, layout, presence, components, UI System, icons and
  package manager, each answer deciding what comes next. With the Angular default structure it only
  asks the stylesheet and the rendering (Client-Side Rendering or Default Angular SSR): no routing,
  shell, components, icons or Starter SSR, and `--defaults --architecture angular-default` no longer
  adds Lucide. The registry gets `offeredWith`, next to `requires`: it shapes the wizard and the
  defaults without making an existing project invalid.
- The "Preferencias" drawer of the user menu is now "Preferencias de Diseño", a page at
  `/preference-design` (`features/preference-design`, with a navigation entry and breadcrumb). The
  drawer component is removed and the presence edits anchor on the new button.
- The component collections say what they bring: the essential collection has 16 components and
  "All available components" 26.
- `as add app-shell` and `as add rendering starter-ssr` also settle the layout and the purpose.

- `--defaults` and the wizard now include the Angular Starter App Shell when the project can take it
  (Screaming Architecture, Angular Starter Routing, Tailwind CSS and Lucide Icons); `--app-shell none`
  keeps the previous result. `NavigationItem` gets an optional, mutable `unfolded`, and the `Home`
  entry of the starter tree uses the `Home` icon name that `as-icon` knows.
- The design base and the `as-` components are now the structure of the reference application
  without its business (ADR-0007, which supersedes ADR-0005): `src/styles.css` imports the
  `src/styles/**/*-styles.css` files (theme, base elements, mixins, scrollbars, typography, one
  stylesheet per component) and `shared/animations/animations.css`; `core/theme`,
  `core/common/icons`, `shared/utils`, `shared/data` and the 26 generic components are ported whole
  (the ripple of the button, the config and entity files and the specs included), not rewritten.
  They need Tailwind CSS, add `@angular/cdk`, and a test setup provides the icons to the specs.
- The wizard no longer marks Architecture, Routing or Components as recommended and preselects
  nothing there; `--defaults` still picks Screaming, Angular Starter Routing and the essential
  components. The Screaming Architecture option links to this repository's ADR-0002 and the
  collection is called "Essential component collection".
- `style: tailwind` is accepted in a configuration file, like `--style tailwind`.

### Added

- Design preferences page (`/preference-design`) with the tabs Apariencia, Tema, UI and Otros of the
  maintainer's demo: layout cards (only Floating wide is built; the other five say "En construcción"),
  colour scheme, light or dark, and UI tokens (radius, button size, density, font size) and toggles
  (breadcrumb, animations) that apply in real time through `core/design-preferences` and persist with
  "Guardar cambios"; "Restablecer" goes back to the defaults. The variables are applied by
  `src/styles/features/design-preferences-styles.css`.
- Angular Starter UI System (`--ui-system starter`, `as add ui-system`), an option on top of the shell
  and a component collection that is not part of `--defaults`: the UI tab lists the 16 essential
  components with a live preview, its code, the tokens that change it, a search and a visibility
  toggle.
- Three options in the registry, `--help`, `as list`, `angular-starter.config.json` and `as add`:
  `ssrPurpose` (`--ssr-purpose`: landing, ecommerce and backoffice; only backoffice is built),
  `layout` (`--layout`: the six modes of the demo; only floating-wide is built) and `uiSystem`
  (`--ui-system`). The layouts and the purposes under construction are listed disabled in the wizard.
  A project made before them still works: `findProject` fills what is missing.
- Angular Starter Presence (`--presence starter`, `as add presence`; ADR-0009 and plan 0007), an option of
  the App Shell that is not part of `--defaults`: `core/presence` with the `PresenceService` of the
  reference application without its authentication, HTTP client and vendor socket (status with a
  duration, automatic away on inactivity or a hidden tab, the status of the other users), the
  `PresenceTransport` contract with an in-memory transport and a WebSocket transport with a JSON
  protocol, `LivePresenceService`, the status row and sub-panels of the user menu (added by planned
  edits that stop with the file named when the menu was reshaped) and `docs/presence.md`, which
  explains the protocol, the Redis keys with their TTL, the snapshot, the grace period and a minimal
  Node server.
- A README next to each piece a project brings: `core/theme`, `core/common/icons`,
  `shared/animations`, `shared/components` and `src/styles` (the lists of components and stylesheets
  are a generated block that `as add` refreshes) and `core/presence`.
- The `home` page is a welcome page when the project has the App Shell: the logo, the project name,
  cards to explore, links to AS Starter and a GitHub link. It replaces the neutral home only while
  its four files are still the ones the architecture generated.
- The design base (components or App Shell) loads the Inter font of the reference application from
  `src/index.html`, so the text is no longer drawn with the fallback font; a project without the design
  base keeps Angular's own `index.html`.
- Angular Starter App Shell (`--app-shell starter`, `as add app-shell`; ADR-0008 and plan 0006), first
  layout mode of the reference application without its business: `features/app-shell` with the
  `Main` and `Empty` layouts, the sidebar (brand, search, navigation tree, user menu, preferences
  drawer), the header, the breadcrumb, `provideLayout`, `LayoutService` and their specs, the
  `sidebar`, `breadcrumb` and `user-menu` stylesheets imported from `styles.css`, the components the
  shell draws with, and the example pages `dashboard`, `users`, `reports` and `settings` in the
  navigation tree. The routes are wrapped in the `Main` layout route and `as generate feature` adds
  its route there. It is a new option of the wizard, `--help`, `as list` and `as add`.
- Explicit wizard: every option shows its name, the official documentation of what it installs
  (`[ url ]`, aligned like `ng new`) and a description while highlighted. One stylesheet list
  (CSS, Tailwind CSS, SCSS, Sass, Less); `--style tailwind` is accepted. The registry holds the
  texts and the requirements of each option (ADR-0004).
- Recommended defaults: `--defaults` and the wizard preselect Screaming, Angular Starter Routing,
  Tailwind CSS, Client-Side Rendering, Lucide and the recommended components; defaults are derived
  from what was given so they never conflict.
- Angular Starter SSR + Incremental Hydration (`--rendering starter-ssr`): the default SSR plus
  `withIncrementalHydration()`, event replay, view transitions and a `@defer (hydrate on viewport)`
  example.
- Design base (plain CSS, works with and without Tailwind CSS): tokens, light and dark theme,
  typography, animations and form styles; `ThemeService`, icon registration, utilities and pipes
  (ADR-0005).
- Native `as-` components with specs: `recommended` (icon, button, input, textarea, checkbox,
  toggle, select, avatar, divider, skeleton, tooltip, modal, drawer, toast, tabs, popover) and
  `all` (plus table, search, datepicker, section-nav, selectable-item, reorder-list, preview,
  media-preview, theme-color-picker, weekly-schedule).
- `as add` (icons, components, routing, rendering), `as generate` (feature, component),
  `as config list|get` and a categorized `as --help` with examples (ADR-0006).
- Initial repository with README, MIT license and community files.
- CLI core (`@as-starter/cli`, binaries `as-starter` and `as`): `new` (interactive wizard,
  flags, `--defaults`, `--config`, `--dry-run`), `list`, `info`, `doctor`, `version` and help.
  `new` runs the official `ng new` (Angular CLI 22.3.0) and writes `angular-starter.config.json`.
- Capability registry: options that cannot be generated yet are hidden from the wizard and help and
  rejected with a clear message.
- ADR-0001 documenting the CLI architecture and toolchain.
- Screaming Architecture profile (`as new --architecture screaming`): `core/`, `features/` and
  `shared/` skeleton with a lazy-routed `home` feature, `@core/*`, `@features/*` and `@shared/*`
  aliases, and `app.config.ts` / `app.routes.ts` adjusted through the TypeScript compiler
  (`ts-morph`). New `apply-architecture` stage of the generation engine; templates live in
  `blueprints/`. ADR-0002 and its implementation plan.
- Angular Starter Routing (`as new --architecture screaming --routing starter`): one navigation
  tree (`features/app-shell/navigation/navigation.data.ts`) feeding a `TitleStrategy` and a
  `BreadcrumbService` in `core/navigation`, registered with a single `provideNavigation(...)` call
  in `app.config.ts` (edited through `ts-morph`, new `addProvider` edit). New `apply-routing` stage;
  capabilities can declare `requiresArchitecture`, which `as new` enforces and the wizard honours.
  The generated project ships specs for the services. ADR-0003 and its plan.
- Icon library option `--icons lucide` (official `@lucide/angular`): added to the generated
  project's `dependencies` before installation, recommended in the wizard.

### Changed

- `--defaults` now generates the recommended set instead of the plain Angular structure; use
  `--architecture angular-default --routing angular --components none` for the previous behavior.
- The Screaming profile no longer leaves the welcome page of Angular: the root component is composed
  in `app.ts` with an inline `<router-outlet />`, and the home page is neutral.
- `as list` prints the label, description and documentation of every option.
