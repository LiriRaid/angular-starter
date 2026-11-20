# ADR-0006: Commands for an existing project (`add`, `generate`, `config`) and a categorized help

- Status: accepted
- Date: 2026-11-19
- Deciders: project maintainer

## Context

`generate`, `add` and `config` were registered as "not available yet", and `as --help` listed every
command in one flat list. Someone who accepted Angular's defaults has no way to add what the starter
provides (routing, icons, components, SSR) or to scaffold a feature that follows the architecture.

## Decision

1. **Help by category** (`as --help`): Create (`new`), Modify an existing project (`add`,
   `generate`/`g`), Inspect (`list`, `info`, `config`, `doctor`, `version`), Planned (`update`),
   each with its flags, examples and the list of what only `as new` can decide. Each command has its
   own examples (`as <command> --help`).
2. **`as add <capability> [value]`**, run from the root of a project that has
   `angular-starter.config.json` (found by walking up). Capabilities that can be applied to an
   existing project: `icons lucide`, `components recommended|all` (also adds icons and the design
   base when missing), `routing starter` and `rendering ssr|starter-ssr` (runs the official
   `ng add @angular/ssr`, then the starter edits). It refuses what the project's architecture or
   style cannot take, never overwrites an existing file, edits through `ts-morph`/`jsonc-parser`,
   updates the config file, and installs dependencies unless `--no-install`. `--dry-run` shows the
   plan.
3. **`as generate feature <name>`** (`g`): `features/<name>/` with component, routes
   (`<NAME>_ROUTES`) and spec; a lazy route in `app.routes.ts`; a navigation entry when the starter
   routing is present. **`as generate component <name> [--feature <f>|--shared]`** creates a
   standalone component with the project's prefix. Both need the Screaming architecture.
4. **`as config list|get <key>`** reads `angular-starter.config.json`. It is read-only: values that
   shape the project (architecture, style, package manager, prefix) are decided by `as new`;
   `as config` and `--help` say so.
5. **Cannot be applied later** (listed in `--help`): architecture, stylesheet format, Tailwind
   toggle, package manager and selector prefix; they rewrite too many files to do it safely.
6. All commands share the capability registry (ADR-0004), the stage pipeline and the edit helpers;
   exit codes follow ADR-0001.

## Alternatives considered

- Wrapping `ng add` and `ng generate` blindly: rejected, they know nothing about the architecture
  layers, the lazy-route pattern or the navigation tree.
- `config set` for every key: rejected by the maintainer's scope choice; rewriting selectors or
  styles in place is risky and belongs to a later migration capability.
- One `as add` per capability (`as add-icons`): rejected, one verb with the registry keeps the help
  short and extensible.

## Consequences

- Positive: "change or add my own later" is real for the capabilities that can be applied safely.
- Negative: `add rendering` depends on the official `ng add @angular/ssr` and the network; the
  architecture and style remain decisions of the first run.
- Follow-up: `as update`, `as config set` for safe keys, more `generate` kinds (service, guard) once
  the auth capability exists.
