# ADR-0019: Commands that work on any Angular project, not only on one made by `as new`

- Status: accepted
- Date: 2026-11-24
- Deciders: project maintainer

## Context

Everything the CLI can do after `as new` (`add`, `generate`, `config`) needs an
`angular-starter.config.json`, so it only works in a project that `as new` created. A developer who has an
Angular application half built, or who wants only the native components, or only the architecture, cannot
use the CLI at all. `as list` also describes each option but never says which command installs it.

Components in particular were tied to the Screaming Architecture (`requires: architecture: screaming`),
although what they need is a place to live (`shared/components`) and two path aliases, and the project may
follow any architecture.

## Decision

1. **`as init` adopts a project.** In the folder of an Angular workspace (`angular.json`) it detects what
   the project already has (architecture, routing, stylesheet format, Tailwind CSS, rendering, shell,
   presence, components, UI System, icons, package manager, selector prefix), prints it and writes
   `angular-starter.config.json`. It never changes code. `--dry-run` only prints. `as add` and
   `as generate` in a project without the file say to run `as init`.
2. **Components do not need an architecture.** They keep needing Tailwind CSS and Lucide, but the
   architecture requirement of the three component options moves from `requires` to `offeredWith`: the
   wizard still offers them with the Screaming Architecture only, while `as add components` and
   `as new --components ...` work with any. A project that has no `@shared` and `@core` aliases gets them
   (`tsconfig.json`), plus `src/app/shared/components/index.ts`; folders that exist are used as they are
   and nothing of the developer's is moved.
3. **`as add architecture screaming`** applies the Screaming profile only to a project that still is what
   `ng new` generates: no `src/app/core`, `features` or `shared`, and `app.ts`, `app.config.ts`,
   `app.routes.ts` and `tsconfig.json` with the expected shape. Otherwise it stops before writing and says
   why. The architecture is not asked for again in `as add` when the project has one.
4. **`as generate component <name>` works like `ng generate` in any project that is not Screaming:** it
   creates `src/app/<name>/` (or `--path <folder>` below `src/app`) with the `.ts`, `.html`, `.css` and
   `.spec.ts` of the component, using the project's prefix. `generate feature` and the `--feature` and
   `--shared` flags stay Screaming only.
5. **`as list` shows the command of each option**: `Add: as add <capability> <id>` and
   `New: as new --<flag> <id>`, with only the ones that exist for that category, and accepts `app-shell`,
   `ui-system` and `ssr-purpose` besides the camel-case names.
6. **The recommended marks of the wizard stay as they are** (Tailwind CSS, CSR and Lucide).

## Alternatives considered

- **Detect the project on the first `as add`.** It would write the file without being asked; `as init` is
  one explicit step and shows what it found.
- **A flat `src/app/components` with relative imports for default projects.** It respects the default
  structure more, but the blueprints import through `@shared` and `@core`, so it would mean a second
  version of every component.
- **Applying an architecture over a project that has code.** It moves or overwrites the developer's files;
  it needs its own design and is not part of this decision.

## Consequences

- Positive: the CLI serves an unfinished application: `as init`, then `as add components button,modal`.
  The commands follow what `as list` prints.
- Negative: detection is a heuristic. What it cannot tell it records as the option that adds nothing
  (`none`, `angular-default`, `csr`), so `as add` can offer it again; it reports what it assumed.
- The Starter SSR with its shell is the next piece (ADR-0010); it is not part of this one.
