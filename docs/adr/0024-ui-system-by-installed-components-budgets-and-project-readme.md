# ADR-0024: The UI System is built from the components a project has; budgets and the README follow what it has

- Status: accepted
- Date: 2026-11-25
- Deciders: project maintainer
- Supersedes in part: [ADR-0010](0010-routed-wizard-layout-modes-and-design-preferences.md) and
  [ADR-0012](0012-ui-system-variants-and-synced-components.md) (the UI System needing a whole collection
  and describing a fixed list of 16 components) and [ADR-0023](0023-sa-add-completes-what-a-capability-needs.md)
  (`sa add` adding the component collection the UI System needs)

## Context

Trying `sa add architecture` on a default Angular project that already had the shell and the recommended
collection showed gaps in the pieces that sit on top of the components.

- The catalog of the UI System was a fixed list of 16 entries and the code that draws it imported the 16
  classes. The project had 18 components (the shell brings `sa-search` and `sa-theme-color-picker`, which the
  configuration does not record) and the catalog showed 16: it was not intentional, the catalog never knew
  those two or the other eight components of the collection `all`. And with a few components it did not
  compile, so the option only accepted a whole collection.
- The UI System asked for a component collection, but the shell brings components without recording them, and
  `sa add ui-system` in a project without a collection added the essential one on its own.
- The checklist of `sa add components` hid the components the project had, the real checkbox ignored
  `disabled` (the prompter did not pass it on), and nothing said which components are recommended.
- A project with the shell and the UI System built with `bundle initial exceeded maximum budget` (901 kB
  against 500 kB) and `sa-tabs.css` passed the 4 kB of `anyComponentStyle` by 1.48 kB.
- The README of a generated project was still the one `ng new` writes.

## Decision

1. **The catalog shows what is installed.** What is installed is what is in the folders of
   `shared/components`, not what the configuration says: the shell and the components bring others with them.
   The templates of the UI System mark what belongs to each component (`uis:begin(id)` ... `uis:end`, or
   `// uis(id)` at the end of a line; `a,b` is both, `a|b` either) and `sa add ui-system` generates the files
   for the components the project has. With every component the files are the ones that were written by hand
   before; with a few they have only those. Every one of the 26 components has an entry: the 18 with a live
   preview (the 16 of the essential collection, `sa-search` and `sa-theme-color-picker`) and the other eight
   as a card with the selector, the description and how it is used, marked `noPreview`.
2. **The UI System needs components, and `sa add` never picks them.** It accepts a collection or a custom
   selection and refuses `components: none`, naming `sa add components`, even in a terminal and before
   adding anything else: which components a project gets is the developer's choice. The shell brings
   `sa-button` and `sa-toggle`, which the UI System draws its own interface with, and the UI System brings
   them if they are missing and says so.
3. **The catalog is completed, never overwritten.** After `sa add components`, a project with the UI System
   whose catalog lacks installed components gets, in a terminal, a question (yes by default) and, outside one,
   a `Next:` line with `sa add ui-system`, which in such a project completes the catalog instead of refusing.
   The UI System is generated again from the blueprint only when its files are exactly as the CLI left them
   for the components they describe; if the developer edited one, nothing is written and the warning names the
   files and the components that are missing.
4. **The checklist shows everything.** `sa add components` lists the 26 components: the ones the project has
   come ticked and blocked with `(already in the project)` (the prompter now passes `disabled` to inquirer,
   which the real checkbox ignored), the recommended ones carry `(recommended)`, and `sa list components`
   marks the recommended ones the same way (before, `(essential)`).
5. **Budgets.** The design base, which arrives with the first collection or the shell, raises the budget of
   the initial bundle from the `500kB` and `1MB` of `ng new` to `1MB` and `2MB`, only when angular.json still
   has the values of Angular: a budget the developer changed is not touched, and a project without the shell
   or the components keeps Angular's. The budget of each component stylesheet stays at 4 kB: `sa-tabs.css`
   (5.4 kB) went down to 3.6 kB by nesting its rules under the host and writing the layout in the classes of
   its template, with no visual change. The next largest are `sa-input` (3.3 kB) and `sa-theme-color-picker`
   (3.1 kB).
6. **The README describes the project.** Every `sa new` and `sa add` (not `sa init`, which changes no code)
   refreshes the README: the one `ng new` writes (its signature line and only its own headings) becomes a
   Starter Angular README with a block between `<!-- sa:project -->` and `<!-- /sa:project -->` that lists
   what the project has and its commands in the syntax of its package manager; a README with the block gets
   only the block rewritten; any other README is the developer's and is left as it is. It is idempotent.

## Alternatives considered

- **A catalog in a folder per component** (an entry and its preview in files of their own, and an index that
  registers them), which would add only the missing entries and never regenerate. Cleaner in the long run, but
  it rewrites the catalog, the page, the class and the spec of the UI System (about 1,600 lines) with the
  risk of visual regressions; the marks keep today's files as they are.
- **Count the components of the shell as a collection**, so a project with only the shell could have the UI
  System. It contradicts the choice that a project without a collection gets none.
- **Raise the limit of each component stylesheet** to fit `sa-tabs.css`. It hides the next component that
  grows; the stylesheet is smaller instead.
- **Overwrite the catalog on every `sa add components`.** It loses whatever the developer changed in it.
- **Write the README only when the project is created.** It would be out of date after the first `sa add`.

## Consequences

- Positive: a project with a few components has a UI System that compiles and shows them; adding components
  later is a question and not a manual edit; the build of the project with the shell and the UI System has no
  budget warning; the README says what the project has.
- Negative: the templates carry markers that have to stay balanced (a spec checks every component is
  generated alone); a catalog the developer edited is not completed by the CLI, and neither is one made by another version of the CLI whose blueprint differs (it counts as edited); an entry whose component was deleted stays in the catalog. A project made before keeps
  its README unless it still is the one `ng new` wrote.
- Follow-up: curated previews for the eight components that only have a usage card, and a UI System that
  does not need the starter routing.
