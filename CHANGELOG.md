# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project intends to adhere to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) once released.

## [Unreleased]

### Added

- In a terminal, `sa add components` with no value opens a checklist of the components the project does
  not have yet, with the essential ones ticked, and `sa add rendering` with no value opens a selector
  (Angular SSR or the Starter SSR). Outside a terminal they still ask for the value, now listing the ids.
- `sa list components` lists the 26 components one by one (id, `sa add components <id>`, name and
  description, the essential ones marked) after the collections, and `sa --help` has a `Lists:` section
  with every `sa list <category>`. The help of `add` and `generate` point to the lists and to each other.
- `as init` sets up an Angular project that `as new` did not make: it reads what the project has
  (architecture, routing, stylesheet format, Tailwind CSS, rendering, shell, presence, components, icons,
  package manager, prefix), shows it and writes `angular-starter.config.json` without touching code, so
  `as add`, `as generate` and `as config` work on it (ADR-0019 and plan 0016).
- `as add architecture screaming` gives the Screaming Architecture to a project that is still what
  `ng new` generates, and stops before writing when it has folders or changes of its own.
- `as generate component <name>` works in a project that is not Screaming, like `ng generate component`:
  `src/app/<name>/`, or below `--path <folder>`.
- `as list` shows the command of each option (`Add: as add ...`, `New: as new --...`) and takes
  `app-shell`, `ui-system`, `ssr-purpose` and `package-manager` as category names.
- `as version` (and `-v`, `--version`) prints the version of the CLI and the version of the Angular CLI
  that `as new` runs, not the latest one on npm.

### Changed

- `sa add architecture screaming` now adds the structure to a project at any point: the folders and READMEs
  that are missing and the `@core`, `@features` and `@shared` aliases, without overwriting or moving
  anything, so it works after the components (before, `core` and `shared` stopped it). It adapts `app.ts`,
  `app.config.ts` and Angular's welcome page only while they are as `ng new` leaves them, lists what it
  left for the developer to review, gives no starting page, and in a terminal asks whether to add the
  routing and the app shell too (ADR-0022 and plan 0019).
- `sa add components` and `sa add app-shell` say, before they run, that Lucide Icons is installed too and
  why (`sa-icon` draws the icons with it); `sa add icons lucide` on a project with no components suggests
  `sa add components icon`; and `sa add components` with no value lists every component id next to the
  collections. Nothing else about the commands changes.
- The project is now called **Starter Angular** (the website says Starter for Angular): the package is
  `@liriraid/starter-angular` (0.1.0), the binaries are `sa` and `starter-angular` (`as` and `angular-starter`
  are gone), the selector prefix of the native components is `sa-` (`sa-button`, `SaButton`, `--sa-*`), the
  environment variables are `SA_*` and a project's configuration file is `starter-angular.config.json`. The
  README explains the two names and warns that some Linux systems install their own `sa`. The entries below
  keep the names of their time (ADR-0021 and plan 0018).
- `as --help` lists the commands as `as <command>`, each with a one-sentence description, paints the
  `Commands:` and `Options:` headings blue like `ng --help` and ends with where to read more; the headers of
  the `as list` table (`ID`, `Commands`, `Option`) are blue too. Colors only show on a terminal.
- The project is now called **angular-starter**: the package is `@liriraid/angular-starter` (0.1.0), the
  binaries are `as` and `angular-starter` (`as-starter` is gone), and the repository links, the README and the
  welcome and docs pages of the generated applications say Angular Starter. The README warns that `as` is the
  GNU assembler on Linux and macOS and that the project is not affiliated with Google (ADR-0020 and plan 0017).
- `as list` prints one table, with the same columns in every category: the id, the commands (`as add ...` and
  `as new --...`, none while an option is planned) and the name with its description and link. On a narrow
  terminal the description goes under the row.
- `as --help` lists only the commands and the options, like `ng --help`; the examples are in
  `as <command> --help`.
- The native components no longer need the Screaming Architecture: `as add components` and
  `as new --components` work with any, creating `src/app/shared` and `src/app/core` and the `@shared` and
  `@core` aliases when the project has none. The wizard still offers them with the Screaming Architecture.

- `as --version`, `as list` and every help start in about 0.5 s instead of 2.1 s: `ts-morph` and
  `execa` load when `new`, `add` or `generate` need them (ADR-0018).
- `as new` installs with `npm install --no-audit --no-fund --prefer-offline` or `pnpm install
--prefer-offline` (yarn stays plain), so the install reaches for the local cache first
  (ADR-0016 and plan 0014).
- The end-to-end suite installs seven projects instead of fifteen, each covering a family of options
  and keeping the assertions of the ones it replaces, and installs them with pnpm.

### Added

- The welcome page brings the documentation of AS Starter (`features/docs`, ADR-0015 and plan 0013): a
  side menu and pages for getting started, the design base, the native components and the app shell, and
  a tutorials page with numbered steps, at `/docs` and `/docs/<page>`, with a Documentation item in the
  navigation tree. The cards "AS Starter documentation" and "Learn with tutorials" open them instead of
  angular.dev.
- `as-modal` gets `draggable` (default `true`): with `false` the header does not move the panel. The
  UI System has a "Se puede mover" switch for it.

### Fixed

- `as add rendering ssr|starter-ssr` works in a pnpm project on Windows: `ng add @angular/ssr` now runs
  from the project's own Angular CLI with node. Through the `.bin` shim, pnpm rewrote it while `cmd.exe`
  was reading it, and the command ran twice and stopped with "A merge conflicted on path /src/server.ts"
  (ADR-0016 and ADR-0017).
- `as new` and `as doctor` say why a package manager that is installed refuses to run (corepack does it
  for yarn inside a folder whose `package.json` names another manager) instead of calling it not found.
- The UI System chips (variant names and tokens) use the dark field surface in dark mode; the chosen
  chip is marked by colour. The tabs of every example are independent again (`sharedGroups` is gone).
- `as-textarea`: in `in` the text starts under the label, a left or right icon reserves its side and
  lines up with the first line.
- `as-input` with `isTagInput` in `in` and `over`: the label follows the variant (no dark box) and the
  box has the height of a plain input, so rows of fields line up.
- The label background of `as-input` and `as-textarea` rounds on every corner; the `over` label no
  longer moves for a left icon.
- The tooltip on a component host (`as-button`) anchors `top` and `bottom` to the whole button, as
  `left` and `right` already did.
- The readonly `as-select` of the catalog shows a chosen value in each mode.

### Changed

- The design preferences page is reached only from the user menu: its navigation entry is `hidden`
  (it keeps its title and breadcrumb), and the sidebar width of Apariencia is an `as-select`
  (ADR-0014 and plan 0012).
- The UI System catalog (ADR-0014): the previews of every component are apart (no overlaps), show
  every property in each mode (`required variant="on"`, `in`, `over`), the tooltip on the host and on
  the text, tabs (their active tab is independent again since ADR-0015), icons and counters, the password with
  its eye, the modal and the drawer with `flush` and a padded inner content, and every input of each
  component or the reason it is not shown. The cards and the code of all the variants collapse with the
  accordion animation.
- `as-modal` gets `flush`; the disabled toggle is visible in dark mode and the `contrast` toast has the
  inverse text of the theme, both with theme tokens.
- The `as-input` blueprint brings the country flags sprite (flag-icons, MIT) to
  `public/assets/flags-sprite.svg`.

### Added

- The UI System shows every variant of every essential component (ADR-0012 and plan 0010): the sizes,
  severities and states of the button; the `in` / `on` / `over` modes and the types of the field; the
  positions of the tooltip, the popover and the drawer; the states of the toggle and the checkbox; the
  types and positions of the toast. A chip under each variant chooses it and the code block shows its
  snippet; modal and drawer open over the whole page with switches for their options. The variants live
  only in the catalog: the tokens of the UI tab keep changing every preview through CSS variables.
- The `as-drawer` is mounted through the CDK overlay (it paints over the whole page, like the modal) and
  gets `density`, `flush`, `closeIcon`, `closeLabel`, `styleClass` and a `[drawer-header]` slot; the
  `as-select` gets `optionIconSize`, `hideOptionLabel`, `accentColor` and `panelStyleClass`; the
  `as-modal` gets `titleDotColor`; the `as-button` gets `rounded`.

### Changed

- The wizard can go back (ADR-0013 and plan 0011): Esc returns to the previous question in every kind of
  prompt (lists, the components checklist, text and yes/no), shown as `esc back` in the help line, with the
  previous answer selected, and what the changed answer decides is asked again (the answers are kept in a
  history and the flow replays). The first question has nothing before it. The final confirmation is now
  _Create the project_, _Change an answer_ (it lists the answers and jumps to the one chosen) or _Cancel_.
  Flags and `--config` values are never asked, so never revisited.
- After the components question the wizard lists every component with a checkbox, like the last
  question of `ng new` (ADR-0011 and plan 0009): the essential collection starts with its 16 ticked and
  "all" with the 26; each line says what the component is, what it brings with it and the stylesheet it
  adds. What ends ticked is recorded as `recommended` or `all` when it equals one of them, otherwise
  as `components: custom` with the ids in `componentList`. `--components` also takes ids
  (`--components button,modal,toast`) and `as add components` adds components by id to what the
  project has. The UI System still needs a whole collection.
- The Apariencia tab of the design preferences keeps only the layout; the colour scheme and light or
  dark mode are in Tema. The colour swatches are round, with the ring and the check of the reference
  application.

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
