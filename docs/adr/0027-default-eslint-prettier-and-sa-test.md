# ADR-0027: Every project comes with ESLint and Prettier ready, and `sa test` runs the tests

- Status: accepted
- Date: 2026-11-26
- Deciders: project maintainer
- Refines: [ADR-0019](0019-commands-for-existing-projects.md), which made `sa add` build a project piece by piece

## Context

`ng new` (Angular CLI 22.3) already leaves a project with the tools that make it Angular today: zoneless change
detection (no `zone.js`), the unit test runner of the CLI (`ng test`, Vitest 5 with jsdom and a `test-setup.ts`),
Prettier with its `.prettierrc`, `.editorconfig` and TypeScript 6. What it does not leave is a linter, and it has no
`lint` or `format` scripts. The two reference applications (OmniInbox and YaloAtiendo Chat) both ship ESLint 10 with
`typescript-eslint` and `@angular-eslint`, a flat `eslint.config.js`, and the `lint`, `lint:fix`, `format` and
`format:check` scripts, so a project that starts from Starter Angular was missing the first thing a team asks for.

Two more facts shaped the decision.

- The code the stages write does not follow the `.prettierrc` of `ng new` (width 100, trailing commas): in a project
  with every piece, `prettier --check` marked 150 of its 290 files, and no other width or comma setting gave zero.
  On Windows `ng new` also writes CRLF line endings, which Prettier flags too.
- The `sa-` components name their outputs the way their API reads (`onClick`, `input`, `change`), which two rules of
  `@angular-eslint` forbid (`no-output-on-prefix`, `no-output-native`); every other rule of the recommended sets
  passes on everything the starter generates.

## Decision

1. **Every project has lint and format, whatever its architecture.** `sa new` runs a stage, `apply-tooling`, for the
   default Angular structure as for the Screaming Architecture. It writes `eslint.config.mjs` (a flat configuration
   with ESLint's, `typescript-eslint`'s and Angular's recommended sets for code and templates, the selector prefix of
   the project and `sa`, and the reference rules: `no-explicit-any` and `no-unused-vars` as warnings, `no-console`
   allowing `warn` and `error`, `banana-in-box` as an error), adds `eslint`, `@eslint/js`, `typescript-eslint`,
   `angular-eslint` and `prettier` as dev dependencies, and adds the scripts `lint`, `lint:fix`, `format` and
   `format:check`. The file is `.mjs` so it works whether the project is CommonJS or ESM, and it uses the
   `angular-eslint` umbrella package, which the Angular team keeps in step with the Angular version.
2. **The versions are the latest stable that work together, pinned in one place.** `TOOLING_PACKAGES` in `compat.ts`
   holds the ranges, next to the Angular CLI version they were tested with, and is raised the same way. Prettier is
   the project's own when `ng new` wrote it.
3. **The `sa-` components keep their output names.** The configuration turns the two output naming rules off for
   `src/app/shared/components/sa-*/**` only; the code of the developer is checked by them.
4. **Nothing the developer has is replaced.** A project with an ESLint setup of its own (any `eslint.config.*`, an
   `.eslintrc*` or `eslintConfig` in `package.json`) keeps it, and then gets neither the ESLint packages nor the lint
   scripts, only the format scripts; a script that exists keeps its command.
5. **The generated code is formatted once.** After `install-dependencies` and before the first commit, the stage
   `format-project` runs the `format` script of the project, so `format:check` starts green and the line endings are
   LF. With `--no-install` Prettier is not there yet, and the command says to run `<package manager> run format` after
   installing. A formatting failure is a warning: the project is complete without it. `sa add` never reformats code
   that already belongs to the developer.
6. **`sa add tooling` completes a project that lacks it.** It plans the edit first and refuses, like the other
   additions, when the project has everything; `--dry-run` shows the steps and `--no-install` skips the install. It is
   not an option of the project (every new project has it), so it has no entry in `starter-angular.config.json`.
7. **`sa test` runs the tests of any Angular project.** It finds the workspace from any folder, runs the `ng` the
   project has installed through the package manager of its lockfile (`pnpm exec ng test`, `npm exec -- ng test`,
   `yarn ng test`), hands over every argument and option as typed, shows the output as `ng test` prints it and exits
   with its exit code. It does not need the project to have been created or prepared by Starter Angular, so a project
   works the same with `ng` and with `sa`: whoever created it, the runner is the Angular one.

## Alternatives considered

- **`ng add angular-eslint`**: less code of ours, but it generates its own configuration, depends on the network and
  on its prompts, and is harder to test on projects that already exist. Writing the file keeps one result for every
  architecture and for `sa add`.
- **The test setup of OmniInbox** (`vitest.config.ts` with `@analogjs/vitest-angular`): it would replace the runner
  of Angular and change how every spec of the starter runs; `ng test` already is Vitest 5, zoneless.
- **The Prettier width of OmniInbox (700)**: it leaves 53 files that still differ and overwrites a file `ng new`
  wrote. Formatting once keeps the configuration of Angular.
- **Leave `format:check` red until the developer runs `format`**: no risk of rewriting files, but a CI with lint and
  format would fail on the first day.

## Consequences

- Positive: a new project lints and formats with no setup, in any architecture; `pnpm lint` and `pnpm format:check`
  pass on everything the starter generates (the e2e runs both); `sa test` gives the same `ng test` from the CLI that
  made the project.
- Negative: a new project installs four more packages (about a dozen seconds with a warm store), and `sa new` runs
  Prettier over `src` once, which adds a few seconds.
- Follow-up: `sa lint` and `sa format` could be the same kind of pass-through as `sa test`; a CI workflow like the one
  of OmniInbox is not generated (it only makes sense for a project that goes to a given host).
