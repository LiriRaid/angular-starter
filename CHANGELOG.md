# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project intends to adhere to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) once released.

## [Unreleased]

### Added

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
