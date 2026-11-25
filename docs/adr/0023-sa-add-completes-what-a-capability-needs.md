# ADR-0023: `sa add` lists the choices, completes what a capability needs and offers what comes next

- Status: accepted
- Date: 2026-11-24
- Deciders: project maintainer
- Supersedes in part: [ADR-0022](0022-adding-an-architecture-to-an-existing-project.md) (the question after
  the architecture) and [ADR-0019](0019-commands-for-existing-projects.md) (what `sa add` does when a
  capability needs another one)

## Context

Trying `sa add` on a project that had taken the components showed three gaps. `sa add architecture` applied
Screaming at once, so a person never saw which architectures exist. The shell it added called the project
`angular-aplication-defect`, the package name Angular writes, and not `AngularAplicationDefect`, the name
the developer typed. And the UI tab of the design preferences did not show the components the project
already had, because the UI System is another capability that nothing mentioned. Behind the three is one
idea of the maintainer: a project is built piece by piece with `sa add` the way `sa new` builds it at once,
and each command must see what the project has, add what it lacks and tie the pieces together, without
forcing what the developer does not want.

## Decision

1. **A list of architectures.** In a terminal, `sa add architecture` shows every architecture with the
   planned ones listed and not selectable, even when only one can be chosen. A project that already has one
   gets the usual "already in this project".
2. **The name is the folder's.** A project's name, which the generated code shows as its application name,
   is the name of its folder, which is what `sa new <name>` typed, and no longer the `name` of `package.json`
   (Angular lowercases it with hyphens).
3. **A capability completes what it needs.** What each option requires is in the registry, so `sa add`
   derives what is missing (the architecture for the routing, the routing for the shell, the shell and the
   components for the UI System) and the order to add it. In a terminal it says which and asks once; on a yes
   it adds them in order and then the capability, installing only at the last step that installs; on a no it
   changes nothing. A dry run lists the chain. Outside a terminal it stops and names the commands to run. A
   requirement `sa add` cannot bring (the rendering, Tailwind CSS) is still reported as it was.
4. **The UI System is offered.** After `sa add app-shell` or `sa add components`, if the project has the
   shell and a component collection and no UI System, a terminal asks whether to add the catalog of the
   components to the UI tab (yes by default); outside a terminal the next-step line names `sa add ui-system`.
5. A command that another one runs to bring a prerequisite asks nothing more.

## Alternatives considered

- **Add the UI System whenever the shell and the components are there.** Fewer steps, but `sa new` makes it
  optional and a developer may not want the catalog.
- **Only print the commands that are missing.** The error would be clearer, but the developer would type
  what the CLI already knows.
- **Store the typed name in the configuration.** It would survive a renamed folder, but a project made
  before has none and the folder is already the name a person gave.

## Consequences

- Positive: each `sa add` works from what the project has; a person can add the shell, the components or
  the UI System alone or all at once, and sees the choices before taking one.
- Negative: the shell and the UI System still need the Screaming architecture and the starter routing, so
  they cannot be had without them; making them independent is a larger change. A project renamed after
  its creation shows its new folder name.
- Follow-up: an `all` option for the design of the app shell, `sa add app-shell` completing only the parts
  the shell lacks, and shell and UI System that do not need the starter routing.
