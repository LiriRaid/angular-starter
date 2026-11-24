# ADR-0022: Adding an architecture to an existing project adds the structure, never replaces anything

- Status: accepted
- Date: 2026-11-24
- Deciders: project maintainer
- Supersedes in part: [ADR-0019](0019-commands-for-existing-projects.md) (what `sa add architecture` does)

## Context

ADR-0019 let `sa add architecture screaming` run only on a project that was still what `ng new`
generates: it stopped when `src/app/core`, `features` or `shared` existed, and when any of four files had
changes. That left a hole. Adding the native components creates `core` and `shared` (ADR-0019 found that
the components need those folders and two aliases, not an architecture), so a project that took the
components first could never take the architecture afterwards. The maintainer wants the architecture to be
the structure only, applied to a project at any point of its life: if the project has components, routes or
a shell already, it keeps them and only what is missing is added.

What the documentation and other tools do points the same way:

- The [Angular style guide](https://next.angular.dev/style-guide) asks to organize `src` by feature or by
  common theme and does not impose `core`, `shared` or `features`: they are a community convention, so a
  profile must help and never limit.
- Good schematics are additive: they check whether a file exists and skip it instead of overwriting it, so
  running them twice is safe ([schematics authoring](https://angular.dev/tools/cli/schematics-authoring)).
- Nx migrates an existing Angular CLI project keeping its current layout
  ([Nx](https://nx.dev/migration/migration-angular)), and Sheriff treats any folder with an `index.ts` as a
  module without moving it ([Angular Architects](https://www.angulararchitects.io/en/?p=7366)).

## Decision

1. **The structure, added.** `sa add architecture <id>` creates the folders of the architecture that are
   missing (with their README), adds its path aliases, and never overwrites or moves a file. An alias that
   already points somewhere else stops the command before anything is written, as it does for the
   components. Folders that exist, with the developer's code in them, are fine.
2. **The Angular skeleton, adapted while it is untouched.** `app.ts` (root with only `<router-outlet />`),
   `app.config.ts` (router with `withComponentInputBinding()`), and Angular's welcome page (`app.html`,
   an empty `app.css`, the welcome test) are adapted or removed only while they are as `ng new` leaves them
   (the welcome template is recognised by the placeholder text Angular writes in it). A file with changes of
   its own is left as it is and listed after the steps ("Review ...") with what to do by hand.
3. **No starting page.** The project is a clean canvas: the app is blank until the developer creates a
   feature with `sa generate feature`. `sa new` still gives the home page, as before.
4. **The next step is asked, not assumed.** In a terminal, after the structure, the command asks whether to
   add the Starter Angular routing and the app shell too; on a no it stops. It always prints what it adapted,
   what it removed, what to review and the commands that come next.
5. **A contract for every architecture.** `ArchitectureProfile` has `apply` (a new project, the whole
   architecture) and `adopt` (an existing project, the structure). Each architecture that is added later
   implements both.
6. The developer's own code in `src/app` is never moved. A guided move into `features/` is a separate,
   later piece of work.

## Alternatives considered

- **Keep refusing when the folders exist.** It is the ADR-0019 behavior and the hole above.
- **Convert the project: move the existing code into the architecture.** Nx and Sheriff do not do it, and an
  automatic move breaks imports and decisions only the developer can take.
- **Overwrite what the blueprint brings.** It is what a schematic does with `MergeStrategy.Overwrite`; it
  would replace the barrel of the components the project already has.
- **A full architecture, with its home page, when the project is empty.** Two behaviors for one command;
  the maintainer chose the clean canvas.

## Consequences

- Positive: components and architecture can be added in either order; the command is safe to run on a
  project with code; a future architecture only has to say what its structure is.
- Negative: a project that took the architecture shows a blank page until it has a feature, and a root
  component with changes needs a manual edit that the notice names.
- Follow-up: an `all` option for the design of the app shell and `sa add app-shell` completing only what
  the shell lacks; a guided move of existing code into `features/` and `shared/`.
