# Plan 0008: a routed wizard, the layout modes and the design preferences page

Decision: [ADR-0010](../adr/0010-routed-wizard-layout-modes-and-design-preferences.md). Each step ends
with its gate; tests come first.

| #   | Step                                                                                                                                                                                                                                                  | Gate                                                     |
| --- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------- |
| 1   | ADR-0010 and this plan                                                                                                                                                                                                                                | `pnpm run format:check`                                  |
| 2   | Tests first, shown red: registry (`offeredWith`, order, `ssrPurpose`, `layout`, `uiSystem`, texts), resolve (derived defaults), wizard (the flow, planned entries), `find.ts` compatibility, flags, help, `as list`, `as add ui-system`               | `pnpm test` fails for the new tests only                 |
| 3   | Registry, schema, resolve, prompter (disabled choices), wizard, flags, `--help`, `as list`, summary, dry run, `find.ts`                                                                                                                               | `pnpm run typecheck` and the unit tests                  |
| 4   | Tests first, then the page: `features/preference-design` (tabs Apariencia, Tema, UI, Otros), `DesignPreferencesService`, route and navigation entry, "Preferencias de Diseño" in the user menu, the drawer removed, the edits of presence re-anchored | `vitest run src/engine` and a spec of the page that runs |
| 5   | UI System: tokens of the UI tab, the catalog with previews, `uiSystem` profile, stage, `as add ui-system`, verify-project                                                                                                                             | `pnpm test` and `pnpm run typecheck`                     |
| 6   | Verification in two generated projects: `angular-default` (the wizard asks only the stylesheet and the rendering) and `screaming` + shell; `ng build`, `ng test` and the page in the browser                                                          | `ng build` and `ng test` green; seen in the browser      |
| 7   | Docs (README, CHANGELOG), `code-review`, `simplify`, opt-in e2e for the new cases (`AS_E2E=1`), commits                                                                                                                                               | `typecheck`, `lint`, `format:check`, `test`, `build`     |

## Out of scope

The other five layout modes, the transparent sidebar width, server rendering of the shell, the landing
and ecommerce variants, previews for the components outside the essential collection, and any
change to the other options.
