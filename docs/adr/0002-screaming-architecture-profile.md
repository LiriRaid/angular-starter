# ADR-0002: Screaming Architecture profile

- Status: accepted
- Date: 2026-11-19
- Deciders: project maintainer

## Context

`as new --architecture screaming` must produce an ordinary Angular application whose folder
structure announces what the product does (features) rather than what the framework is. The
reference is a real, production-grade Angular 22 code base (zoneless, standalone, signals, lazy
routes per feature) that follows a `core / features / shared` split. Studying it showed where its
practice and its own documentation diverge: reusable pieces mixed with business services and models
in `shared/`, features importing other features, and `core/` importing from `features/` once.
A second code base had already corrected those points and was used only to confirm the layer rules.

Constraints: the profile is generated on top of the official `ng new` output (ADR-0001), so it must
edit the generated files through the TypeScript compiler and never through text replacement, and it
must not contain business logic or UI-library dependencies.

## Decision

1. **Structure** (`src/app`):
   - `core/` — application infrastructure only (global providers, interceptors, guards, session,
     theme, configuration). No product logic.
   - `features/<feature>/` — everything that belongs to one business capability: components,
     `<feature>.routes.ts`, `models/`, `services/`, `utils/`, `validators/`, `modals/`, `drawers/`
     as needed. The generated skeleton contains one `home` feature.
   - `features/app-shell/` — reserved location of the application shell (layout, sidebar, header)
     when that capability is generated; the shell is a feature composed by the root component.
   - `shared/` — reusable, domain-free pieces. Native UI components live in `shared/components`
     behind the `@shared/components` barrel; `shared/directives`, `shared/utils` and friends are
     created when first needed. A service, model or utility enters `shared/` only when two or more
     features use it. A component used by one feature stays inside that feature.
2. **Dependency rules**: `core` imports nothing from `features` or `shared`; `shared` imports only
   from `core`; a feature imports from `core` and `shared`, never from another feature. The root
   (`app.ts`, `app.config.ts`, `app.routes.ts`) is the composition root and may import from any
   layer. The rules are documented in a README per layer; they are not enforced by tooling because
   `ng new` ships no linter.
3. **Aliases**: `@core/*`, `@features/*` and `@shared/*` in `tsconfig.json` (`paths`). No
   `@environments/*`: Angular 22 generates no environments; they arrive with their own capability.
4. **Routing**: each feature exports an uppercase `<FEATURE>_ROUTES` array from
   `<feature>.routes.ts`; `app.routes.ts` loads it with `loadChildren`, the feature route loads its
   component with `loadComponent`. `provideRouter` gets `withComponentInputBinding()`.
5. **Conventions**: files without a `.component` suffix, standalone components, `input()`/`output()`,
   new control flow and the project selector prefix (`--prefix`) for generated components.
6. **Generation**: the template files live in `blueprints/architectures/screaming/` (a `.tpl`
   suffix keeps them out of the repository's own lint, format and type checks). A build step copies
   `blueprints/` into the package. The new stage `apply-architecture` runs after `create-workspace`
   and before `install`: it copies the blueprint (never overwriting an existing file except the
   Angular placeholders `app.html` and `app.spec.ts`), edits `tsconfig.json` with `jsonc-parser`
   (comments preserved) and `app.ts`, `app.config.ts`, `app.routes.ts` with `ts-morph`.
7. **Availability**: `screaming` is `available: true`; the wizard, `--help` and `as list` follow the
   registry.

## Alternatives considered

- Reproduce the reference code base exactly (shared services and models, features importing
  features): rejected, it contradicts its own documentation and the Screaming principle.
- `shared/ui` instead of `shared/components`: rejected, it departs from the existing convention
  without a gain.
- App shell in `core/layout`: rejected, the established convention puts it in `features/app-shell`;
  the composition root is the only layer allowed to depend on it.
- Text replacement or `ng generate` for `app.config.ts`/`app.routes.ts`: rejected; string
  replacement breaks on formatting changes between Angular releases, and the schematics cannot add
  the router feature or a lazy route.
- Raw `typescript` compiler API instead of `ts-morph`: viable but needs hand-written printers and
  position arithmetic for the same edits; `ts-morph` adds a dependency (it bundles TypeScript) in
  exchange for far smaller, testable edit functions.
- Enforcing the layer rules with a generated architecture test or ESLint: postponed; it adds files
  to the user's project and belongs to a lint capability.

## Consequences

- Positive: a new project starts with the layer rules, aliases and the lazy-route pattern already
  working; each future architecture adds its own blueprint and edits without touching the engine.
- Negative: the CLI gains two runtime dependencies (`ts-morph`, `jsonc-parser`) and a build step for
  the blueprints; the layer rules are convention, not enforcement.
- Follow-up: app shell, native components, `@environments`, and an optional lint rule set.
