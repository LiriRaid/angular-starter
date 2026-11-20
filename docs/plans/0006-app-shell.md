# Plan 0006: App Shell, first layout mode

Decision: [ADR-0008](../adr/0008-app-shell.md). Each step ends with its gate; tests come first.

| #   | Step                                                                                                                                                                                                                                           | Gate                                                             |
| --- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| 1   | ADR-0008 and this plan                                                                                                                                                                                                                         | `pnpm run format:check`                                          |
| 2   | Tests first, shown red: registry and resolve (`appShell` option, `routing` requirement), wizard, the edits (`addShellStyles`, component provider, layout route, navigation groups, `addRoutes` in the layout), the profile, `as add app-shell` | `pnpm test` fails for the new tests only                         |
| 3   | Registry, schema, resolve, wizard, `--app-shell`, `--help`, `as list`, `as add app-shell`                                                                                                                                                      | `pnpm run typecheck` and the unit tests                          |
| 4   | Edits: styles, `app.ts` providers, layout route, navigation groups, `addRoutes` into the layout, `NavigationItem.unfolded`, components by id                                                                                                   | `vitest run src/engine/edits`                                    |
| 5   | Blueprint `blueprints/app-shell` ported from the reference without business: services, providers, enums, layout, sidebar, header, breadcrumb, styles, specs                                                                                    | `vitest run src/engine/app-shell` and a spec that runs its files |
| 6   | Mock features (`dashboard`, `users`, `reports`, `settings`) with routes, specs and the navigation tree                                                                                                                                         | same                                                             |
| 7   | Profile `engine/app-shell`, stage `apply-app-shell`, dry run, `verify-project`, `generate feature` into the layout                                                                                                                             | `pnpm test` and `pnpm run typecheck`                             |
| 8   | Verification in a generated project: `ng build`, `ng test`, and the shell in the browser (wide, collapsed, mobile, dark)                                                                                                                       | `ng build` and `ng test` green; seen in the browser              |
| 9   | Docs (README, CHANGELOG), `code-review`, `simplify`, opt-in e2e (`AS_E2E=1`)                                                                                                                                                                   | `typecheck`, `lint`, `format:check`, `test`, `build`, then e2e   |

## Out of scope

The other layout modes and the settings drawer, server rendering of the shell, the call widget, every
business piece of the reference (authentication, presence, notifications, profile, tickets).
