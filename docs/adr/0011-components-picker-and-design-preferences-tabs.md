# ADR-0011: A components picker in the wizard, and the tabs of the design preferences

- Status: accepted
- Date: 2026-11-21
- Deciders: project maintainer

## Context

ADR-0010 left the component collections as one question with three answers (none, essential, all).
After using the wizard the maintainer wants what `ng new` does at its last step, where the AI tool
folders to create are ticked from a list: once a collection is chosen, a list of every available
component, with the collection already ticked, so that a project gets exactly the components it will
use. The same use of the design preferences page showed two things to fix: the Apariencia tab carries
the colour scheme and the light or dark mode, which belong to the Tema tab (Apariencia is where more
layouts will be added, by the starter or by a developer), and the colour swatches are squares with a
white gap around the selected one, where the reference application draws round swatches with a ring.

## Decision

1. **A list with checkboxes after the collection.** When the answer of the components question is
   the essential collection or all of them, the wizard asks which components to generate, from a list
   of the 26 with each one's description, what it brings with it (the components it imports) and the
   global stylesheet it adds. The list starts with the 16 ticked for the essential collection and all
   26 for "all components"; the developer unticks or ticks, and an empty list is "none". "None" asks
   nothing. A new prompter method, `checkbox`, backs it.
2. **What is recorded.** The configuration keeps `components: none | recommended | all | custom`.
   Exactly the 16 essential ids is `recommended`, exactly the 26 is `all`, anything else is `custom`
   with the ids in a new `componentList`, which only exists then. A project made before this change
   is unchanged. The ids and the two sets are data of `config/components.ts`, which the manifest of the
   engine reads, so the configuration never imports the engine.
3. **Flags and commands.** `--components` takes the three words or a comma list of ids (`--components
button,modal,toast`), which is `custom`; `custom` without a list is refused. `as add components`
   takes the same, and adds to what the project has (the union is recorded, and normalised to
   `recommended` or `all` when it becomes one of them). Components that others import come with them
   whatever the list says, and the application shell brings the ones it draws with.
4. **The UI System keeps needing a whole collection.** Its catalog previews the 16 essential
   components, so `uiSystem: starter` still requires `components` to be `recommended` or `all`; a
   `custom` project does not get it yet.
5. **The icon library stays as it is.** The shell and the components draw with Lucide and the wizard
   implies it. Letting `as-icon` adapt to other libraries is a later change.
6. **Apariencia is the layout.** The tab keeps the layout cards and the transparent sidebar width;
   the colour scheme and the light/dark mode are only in the Tema tab.
7. **Round swatches with a ring.** The colour swatches are circles with a faint inner outline and, for
   the selected one, a ring of the panel colour and then one of the primary colour, with a check, as the
   brands and roles forms of the reference application do.

## Alternatives considered

- Keep three answers and no list: rejected, a project that needs five components gets twenty-six.
- Always record a list of ids: rejected, it breaks the configuration of existing projects and the
  texts of the help that name the collections.
- Ask the list for every collection, even none: rejected, an empty list is already "none".
- Let the list untick the components the shell draws with: rejected, the shell would not build; they
  come with it and the list says so.

## Consequences

- Positive: a project gets only the components its developer picked; the wizard reads like `ng new`;
  Apariencia is free for more layouts; the swatches match the reference.
- Negative: one more option in the schema and the flags; a `custom` project has no UI System until its
  catalog can follow the installed components.
- Follow-up: the catalog following the installed components, `as-icon` with other icon libraries,
  and the package of the components alone.
