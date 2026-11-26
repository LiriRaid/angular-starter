# Documentation

This folder holds the decisions of Starter Angular (`adr/`) and the plans that carried them out (`plans/`).
Both are records: an accepted ADR is never edited, it is superseded by a later one, and the names it uses
are the ones of its time (the CLI was `as` and the package `angular-starter` before
[ADR-0021](adr/0021-starter-angular-name-sa-command-and-prefix.md)). This page says how the CLI is today.

## The CLI today

The package is `@liriraid/starter-angular` and installs two binaries, `sa` and `starter-angular`. The
selector prefix of the native components is `sa-`, and a project records its choices in
`starter-angular.config.json`.

| Command                             | What it does                                                                                                                       |
| ----------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| `sa new <name>`                     | Creates a project: a chained wizard, flags, `--defaults`, `--config`, `--dry-run`                                                  |
| `sa init`                           | Sets up an Angular project `sa new` did not make; reads what it has and writes the configuration, changing no code                 |
| `sa add <capability> [value]`       | Adds `architecture`, `routing`, `app-shell`, `presence`, `components`, `ui-system`, `icons`, `rendering` or `tooling` to a project |
| `sa generate <kind> <name>`         | Creates a `feature` or a `component`                                                                                               |
| `sa test [args...]`                 | Runs `ng test` of any Angular project through its package manager, with your arguments and its exit code                           |
| `sa list [category]`                | Lists every option, the commands that add it and its documentation                                                                 |
| `sa info`, `sa config`, `sa doctor` | Shows the options of the project, reads or changes its configuration, checks the environment                                       |
| `sa version`                        | Prints the version of the CLI and of the Angular CLI it runs                                                                       |

How `sa add` works, which is what a person trying a project piece by piece meets:

- It looks at what the project has and adds only what is missing, without overwriting your code.
- A capability that needs others (the shell needs the routing and the Screaming Architecture) says which,
  asks once in a terminal and adds them in order; outside a terminal it names the commands
  ([ADR-0023](adr/0023-sa-add-completes-what-a-capability-needs.md)).
- `sa add architecture` adds only the structure and lists what it left for you to review
  ([ADR-0022](adr/0022-adding-an-architecture-to-an-existing-project.md)).
- The components are always chosen by the developer: `sa add components` opens a checklist of the 26, with
  what the project has blocked and the recommended ones marked; the UI System needs them and is built from
  the ones the project has, and it is completed when more arrive
  ([ADR-0024](adr/0024-ui-system-by-installed-components-budgets-and-project-readme.md)).
- The README of the project says what it has between `<!-- sa:project -->` and `<!-- /sa:project -->` and is
  refreshed by `sa new` and every `sa add`; what you write outside the block is never touched.
- Every project has ESLint and Prettier ready (`lint`, `lint:fix`, `format`, `format:check`); `sa add tooling` adds them
  to one that lacks them without replacing an ESLint setup it has, and `sa test` runs its tests
  ([ADR-0027](adr/0027-default-eslint-prettier-and-sa-test.md)).
- With the shell or the components the budget of the initial bundle goes to 1 MB (warning) and 2 MB (error),
  unless you changed the one Angular writes.

## Decisions

| ADR                                                                                                                                                            | Decides                                                                                |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| [0001](adr/0001-cli-architecture-and-toolchain.md)                                                                                                             | The CLI: Node.js, TypeScript, a stage pipeline and the official `ng new`               |
| [0002](adr/0002-screaming-architecture-profile.md)                                                                                                             | The Screaming Architecture profile                                                     |
| [0003](adr/0003-starter-routing.md)                                                                                                                            | One navigation tree for titles, breadcrumbs and the sidebar                            |
| [0004](adr/0004-explicit-wizard-and-recommended-defaults.md)                                                                                                   | An explicit wizard and the recommended defaults                                        |
| [0005](adr/0005-design-base-and-native-components.md)                                                                                                          | The design base and the native components                                              |
| [0006](adr/0006-project-commands.md)                                                                                                                           | `add`, `generate`, `config` and a categorized help                                     |
| [0007](adr/0007-omni-structure-design-and-components.md)                                                                                                       | The structure of the reference application, without its business                       |
| [0008](adr/0008-app-shell.md)                                                                                                                                  | The application shell, in its first layout mode                                        |
| [0009](adr/0009-presence-documentation-and-welcome-home.md)                                                                                                    | Presence, the documentation inside the application and the welcome home                |
| [0010](adr/0010-routed-wizard-layout-modes-and-design-preferences.md)                                                                                          | The chained wizard, the layout modes and the design preferences page                   |
| [0011](adr/0011-components-picker-and-design-preferences-tabs.md)                                                                                              | The components picker and the tabs of the design preferences                           |
| [0012](adr/0012-ui-system-variants-and-synced-components.md)                                                                                                   | Every variant in the UI System                                                         |
| [0013](adr/0013-wizard-can-go-back.md)                                                                                                                         | Going back in the wizard                                                               |
| [0014](adr/0014-ui-system-polish.md), [0015](adr/0015-ui-system-final-fixes-and-starter-docs.md)                                                               | Polish and final fixes of the UI System, and the docs inside the application           |
| [0016](adr/0016-faster-install-and-leaner-e2e.md), [0017](adr/0017-package-verification-and-clear-tool-errors.md), [0018](adr/0018-lazy-startup-of-the-cli.md) | A faster install and a leaner e2e, package checks, and a lazy start of the CLI         |
| [0019](adr/0019-commands-for-existing-projects.md)                                                                                                             | `sa init` and the commands on a project `sa new` did not make                          |
| [0020](adr/0020-angular-starter-name-list-table-and-short-help.md), [0021](adr/0021-starter-angular-name-sa-command-and-prefix.md)                             | The name, `sa`, the `sa-` prefix, the list table and the short help                    |
| [0022](adr/0022-adding-an-architecture-to-an-existing-project.md)                                                                                              | Adding an architecture to an existing project                                          |
| [0023](adr/0023-sa-add-completes-what-a-capability-needs.md)                                                                                                   | `sa add` lists the choices and completes what a capability needs                       |
| [0024](adr/0024-ui-system-by-installed-components-budgets-and-project-readme.md)                                                                               | The UI System from the installed components, the budgets and the project README        |
| [0025](adr/0025-ui-system-modes-button-severities-filled-icons-and-avatar-scale.md)                                                                            | The mode of a field per card, the button severities, filled icons and the avatar scale |
| [0026](adr/0026-floating-panels-follow-their-anchor-and-collapsed-search-opens.md)                                                                             | Floating panels centred on their anchor and following it; the collapsed search opens   |
| [0027](adr/0027-default-eslint-prettier-and-sa-test.md)                                                                                                        | Every project comes with ESLint and Prettier ready; `sa test` runs the tests           |

Each plan in `plans/` has the number of its decision's step list and ends with its gates; the one of
[ADR-0024](adr/0024-ui-system-by-installed-components-budgets-and-project-readme.md) is
[plan 0021](plans/0021-ui-system-by-installed-components.md).
