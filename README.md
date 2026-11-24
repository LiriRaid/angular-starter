# Starter Angular

> **Status: pre-alpha.** The CLI creates Angular applications with the recommended structure (Screaming Architecture, navigation tree, design base and native `sa-` components) and can add or generate more in an existing project. The app shell (sidebar, header, breadcrumb) is available in its first layout mode. Names, scope and commands are provisional.

Starter Angular is an independent, community-driven ecosystem of developer tools for [Angular](https://angular.dev/). Its goal is to remove the repetitive work every Angular team redoes when starting an application: architecture, routing, app shell, layouts, theming and reusable UI.

Starter Angular is an independent project by [LiriRaid](https://github.com/LiriRaid). It is not affiliated with, sponsored by, or endorsed by Google or the Angular team: "Angular" is a trademark of Google, used here only to describe what the tools are for.

The generated code belongs entirely to the developer. Starter Angular is not a runtime dependency of the applications it creates, and the official Angular CLI keeps working as usual.

**Starter Angular and Starter for Angular.** The project, the CLI, the package and the repository are called **Starter Angular** (`sa`). The website uses **Starter for Angular** because that is what it is: a starter for Angular applications that is already built, with its architecture, structure, conventions, styles and native components, so a team only writes its business. The developer can change the styles, the colors and the properties of any component, but never has to build a button from scratch. It follows the conventions of Angular and the ones the community uses, and it never presents itself as Angular or as an official tool.

## Planned scope

| Piece                                  | Purpose                                                                            |
| -------------------------------------- | ---------------------------------------------------------------------------------- |
| CLI (`sa`)                             | Create applications and add capabilities to existing ones                          |
| Schematics                             | Official Angular extension mechanism for generating and transforming code          |
| Native UI                              | Source-available components built only with Angular, HTML, CSS and Signals         |
| Layout / Theme / Runtime configuration | One configurable app shell, design tokens, and settings applied without a redeploy |
| Component registry                     | A single metadata source for the CLI, docs, playground and AI skills               |
| Documentation site                     | Interactive docs built with the project's own components                           |

## What `sa new` generates

`sa new Demo` asks for each option with its official documentation and a description, or takes the **default set** with `--defaults`. Only what has one best answer is marked _Recommended_ (and preselected); the shape of the project is your call. The questions are chained ([ADR-0010](docs/adr/0010-routed-wizard-layout-modes-and-design-preferences.md)): the architecture comes first and each answer decides what follows. With the **Angular default structure** the wizard only asks the stylesheet and the rendering (Client-Side Rendering or Default Angular SSR); with the **Screaming Architecture** everything opens, in this order:

| Option          | Default of `--defaults`                  | Other choices                                                                                                  |
| --------------- | ---------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| Architecture    | Screaming Architecture                   | Angular default structure                                                                                      |
| Routing         | Starter Angular Routing                  | Default Angular Routing                                                                                        |
| Stylesheet      | **Tailwind CSS** (recommended)           | CSS, SCSS, Sass (indented), Less                                                                               |
| Rendering       | **Client-Side Rendering** (recommended)  | Default Angular SSR; Starter Angular SSR + Incremental Hydration (Screaming only)                              |
| Starter SSR for | Backoffice (only with Starter SSR)       | Landing page, Ecommerce (under construction: listed, not selectable)                                           |
| App shell       | Starter Angular App Shell                | None (the default Angular look)                                                                                |
| Layout          | **Floating (wide)** (recommended)        | Wide sidebar, compact sidebar, floating compact, transparent (joined, floating): under construction            |
| Presence        | None (opt in with `--presence starter`)  | Starter Angular Presence (needs the app shell)                                                                 |
| Components      | Essential collection (16 `sa-`)          | All available (26), none; then a checklist of the 26 to tick or untick (`--components button,modal`)           |
| UI System       | None (opt in with `--ui-system starter`) | Starter Angular UI System: the components catalog in the design preferences (needs the shell and a collection) |
| Icons           | **Lucide Icons** (recommended)           | None                                                                                                           |

**Press Esc to go back.** Every question of the wizard (lists, the components checklist, yes/no) goes back to the one before it with its answer selected, and what depends on the change is asked again; the first question has nothing before it. The last question lists _Create the project_, _Change an answer_ (pick which one from the answers so far) and _Cancel_ ([ADR-0013](docs/adr/0013-wizard-can-go-back.md)). Values given with flags or `--config` are never asked, so never revisited.

What you get, without any business logic: the **Screaming Architecture** ([ADR-0002](docs/adr/0002-screaming-architecture-profile.md)); a navigation tree with page titles and breadcrumbs ([ADR-0003](docs/adr/0003-starter-routing.md)); and, with the components, the structure of the reference application ([ADR-0007](docs/adr/0007-omni-structure-design-and-components.md)): `src/styles.css` importing the `src/styles/**/*-styles.css` files (theme tokens, typography, scrollbars, one stylesheet per component) and `shared/animations`, `core/theme` (`ThemeService`, palettes), `core/common/icons` (Lucide registration), the generic utilities of `shared`, and the **`sa-` components** (button, input, select, modal, drawer, toast, tabs, table, datepicker, ...) ported whole, each with its spec. The design and the components are Tailwind CSS code, so they need Tailwind CSS, the Screaming Architecture and Lucide Icons; the wizard enforces it ([ADR-0004](docs/adr/0004-explicit-wizard-and-recommended-defaults.md)). With the **App Shell** ([ADR-0008](docs/adr/0008-app-shell.md)), a new project opens in the reference application's layout without its business: a wide sidebar that floats, with the header and the content floating too, reading the navigation tree, plus five example pages (`home`, `dashboard`, `users`, `reports` and a `settings` with two sections) to try the sidebar, the search, the breadcrumb and the titles before building your product. It brings the `sa-` components it draws with. The user menu's **Preferencias de Diseño** opens `/preference-design` ([ADR-0010](docs/adr/0010-routed-wizard-layout-modes-and-design-preferences.md)), a page with the tabs Apariencia, Tema, UI and Otros whose changes (layout cards, colours, light or dark, radius, button size, density, font size, breadcrumb, animations) apply in real time and are kept with _Guardar cambios_; with the **UI System** its UI tab also lists every installed component with a live preview, its code and the tokens that change it. It is client-side only for now, and `home` becomes a welcome page (the logo, the project name, cards to explore, links to Starter Angular and GitHub) while the developer has not changed it; it brings the documentation of Starter Angular inside the application (`/docs`, with a side menu, the topics and step-by-step tutorials; [ADR-0015](docs/adr/0015-ui-system-final-fixes-and-starter-docs.md)). **Presence** ([ADR-0009](docs/adr/0009-presence-documentation-and-welcome-home.md)) adds the status of the user menu (online, away, busy, invisible, with a duration) with a `PresenceService` that talks to the server through a `PresenceTransport` (an in-memory one that works with no backend, and a WebSocket one) and a guide, `docs/presence.md`, to connect it to Redis and your API. Every piece a project brings has a README next to it. The root component is composed in `app.ts` (`<router-outlet />`). Authentication, guards and interceptors are yours to build.

## Install the CLI

The package is not published yet. Once it is, any package manager works:

| Package manager | Install globally                            | Run without installing                          |
| --------------- | ------------------------------------------- | ----------------------------------------------- |
| npm             | `npm install -g @liriraid/starter-angular`  | `npx @liriraid/starter-angular new my-app`      |
| pnpm            | `pnpm add -g @liriraid/starter-angular`     | `pnpm dlx @liriraid/starter-angular new my-app` |
| Yarn            | `yarn global add @liriraid/starter-angular` | `yarn dlx @liriraid/starter-angular new my-app` |

Yarn 2 and later have no global installs; use `yarn dlx`. Then run `sa new my-app` (or `starter-angular new my-app`). Until
the package is published, install it from a clone (see below). The package manager of the
generated project is chosen separately, with `--package-manager` or in the wizard.

## Try the CLI (development)

Requires Node.js `^22.22.3 || ^24.15.0 || >=26.0.0` (the range of the Angular CLI it runs) and pnpm.

```sh
pnpm install
pnpm build
node packages/cli/dist/bin.js new my-app            # interactive wizard
node packages/cli/dist/bin.js new my-app --defaults # default set, no prompts
node packages/cli/dist/bin.js new my-app --dry-run  # show the plan, create nothing
node packages/cli/dist/bin.js new my-app --style scss --rendering ssr
node packages/cli/dist/bin.js new my-app --defaults --architecture angular-default --routing angular --components none
```

`sa new` runs the official `ng new` (Angular CLI 22.3.0, the tested version) with every option set
explicitly, then installs dependencies and creates the initial Git commit. Interactive and
non-interactive runs (`--defaults`, flags, `--config <file>`) produce the same validated
configuration, which is saved in `starter-angular.config.json` inside the new project.

`as --help` lists the commands and the options, like `ng --help`; `sa <command> --help` shows the flags and examples of each one:

| Command                            | What it does                                                                              |
| ---------------------------------- | ----------------------------------------------------------------------------------------- |
| `new`                              | Create a project (wizard, flags, `--defaults`, `--config`, `--dry-run`)                   |
| `add <capability> [value]`         | Add `icons`, `components`, `routing`, `app-shell`, `presence` or `rendering` to a project |
| `generate` (`g`) `<kind> <name>`   | Create a `feature` (folder, lazy route, navigation entry) or a `component`                |
| `list`, `info`, `config`, `doctor` | See what each option is, the project's options and the environment                        |
| `update`                           | Planned                                                                                   |

`sa version` (or `-v`) prints the version of the CLI and the one of the Angular CLI that `sa new` runs (the tested one, not the latest on npm). `sa list` prints one table: the id of each option, the commands that add it and ask for it (`sa add ...`, `sa new --...`, none while it is planned) and its name, description and documentation.

Only `sa new` decides the architecture, the stylesheet format, Tailwind CSS, the package manager and
the selector prefix. Only options that can really be generated are offered; `sa list` shows what each
one is, its official documentation and what is planned ([ADR-0006](docs/adr/0006-project-commands.md)). The package installs two binaries with the same behavior: the short `sa` and the full name
`starter-angular`.

> **`sa` on some Linux systems.** The `acct` / `psacct` package installs `sa`, the process accounting
> summary tool, and it can sit before the CLI in your `PATH`. `starter-angular` works whatever `sa`
> points to, so use it there (or `npx @liriraid/starter-angular`).

To install your clone as a global command (no publishing involved), after `pnpm build`:
`pnpm add -g ./packages/cli`, or `npm pack` inside `packages/cli` and `npm install -g` the `.tgz`.

Tests: `pnpm test`. End-to-end tests that run the real Angular CLI (network required) are opt-in:
`SA_E2E=1 pnpm --filter @liriraid/starter-angular exec vitest run tests/e2e.spec.ts` (PowerShell:
`$env:SA_E2E=1`).

## What this project is not

- Not a component library such as PrimeNG, Angular Material or NG-ZORRO.
- Not an admin template or a visual app builder.
- Not a fork or replacement of Angular CLI or Tailwind CSS.
- **Not affiliated with, sponsored by, or endorsed by Google or the Angular team.** "Angular" is used only to describe compatibility. Trademark and naming policies are being reviewed before any public release.

## Roadmap

1. Research and definition (licences, names, compatibility matrix, CLI architecture)
2. Analysis of reference projects
3. CLI core and the first architecture profile (Screaming Architecture)
4. Infrastructure capabilities, app shell, layouts and design system
5. Runtime configuration, more architectures, advanced generators
6. Testing, documentation and public release

## License

[MIT](LICENSE). Third-party software notices live in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
