# ADR-0001: CLI architecture and toolchain

- Status: accepted
- Date: 2026-11-19
- Deciders: project maintainer

## Context

AS Starter needs a real, installable CLI (`as new`, `as generate`, `as add`, ...) that produces
ordinary Angular applications. The CLI must not replace or wrap the official Angular CLI in a way
that breaks it, must work the same in interactive and non-interactive modes, and must start small
so that architecture profiles, the app shell and the native UI can be added in later phases
without rewriting the core.

## Decision

1. **One package for now.** `packages/cli` holds the command layer and the generation engine as
   separate folders. It is split into more packages only when a second real consumer (for example
   the Angular Schematics collection) needs the engine.
2. **Libraries.** `commander` for commands, options and help; `@inquirer/prompts` for the
   interactive wizard (the same prompt library the official Angular CLI uses); `zod` (v4) for the
   configuration schema; `execa` to run child processes (`npx`, package managers, `git`) on every
   operating system. All are MIT licensed.
3. **Build.** Plain `tsc`, ESM output in `dist/`, no bundler. Revisit only if start-up time or
   packaging requires it.
4. **Binaries.** `as-starter` and the short alias `as`. On macOS and Linux `as` is normally the
   system assembler, so documentation recommends `npx @as-starter/cli` or `as-starter` and treats
   `as` as a convenience.
5. **Tooling.** pnpm workspaces. TypeScript is kept on the newest version that Angular and
   `typescript-eslint` both support (6.0.x today; 7.0 is not yet supported by either). Raising it is
   a deliberate change made when that support exists; `as doctor` will report when a newer stable
   Angular release is available.
6. **Node.js.** The CLI declares the same `engines` range as the Angular CLI version it runs
   (`^22.22.3 || ^24.15.0 || >=26.0.0` for Angular CLI 22.3), since it delegates to it.
7. **Angular integration.** The engine runs the official `ng new` through `npx` with an exact,
   tested version (compatibility matrix in `src/compat.ts`) and always passes every option it
   models explicitly (`--defaults`, `--skip-install`, `--skip-git`, ...). Installation and the
   initial Git commit are done afterwards by the engine so that future stages can change
   `package.json` before dependencies are installed.
8. **One configuration, one engine.** The interactive wizard, command-line flags and
   `--config <file>` all produce the same `StarterConfig`, validated by one zod schema, and the same
   stage pipeline consumes it. Precedence: defaults < config file < flags < wizard answers for
   anything still missing.
9. **Capability registry.** Every selectable option is declared once with an `available` flag.
   Options that do not exist yet are rejected with a clear message in non-interactive mode and are
   hidden by the wizard, so the CLI never offers something it cannot generate.
10. **Safety.** The CLI never overwrites an existing path, never claims success when a mandatory
    stage fails, and never stores secrets in `angular-starter.config.json`.
11. **Exit codes.** `0` success, `1` runtime failure, `2` usage or validation error, `130` cancelled.

## Alternatives considered

- Separate `cli` and `generator` packages from day one: more publishing and versioning work with no
  second consumer yet.
- `@clack/prompts` or `yargs`: viable, but `@inquirer/prompts` shares dependencies and the look and
  feel of the Angular CLI, and `commander` has the simplest custom help.
- `tsdown` / `tsup` bundlers: extra moving parts with no clear benefit for a CLI of this size.
- TypeScript 7.0 now: not supported by Angular 22.3 (`>=6.0 <6.1`) or `typescript-eslint`.
- Always running `@angular/cli@latest`: a new Angular major could break blueprints the day it is
  released, before they are tested.

## Consequences

- Adding a capability means registering it, adding its stage(s) and tests; the wizard, `--help`,
  `as list` and validation pick it up from the registry.
- The tested Angular CLI version is a single constant, bumped together with the compatibility
  tests.
- Generated applications are ordinary Angular projects and do not depend on this CLI at runtime.
