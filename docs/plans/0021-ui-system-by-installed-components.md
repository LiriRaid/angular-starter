# Plan 0021: The UI System is built from the components a project has; budgets and the README follow what it has

Decision: [ADR-0024](../adr/0024-ui-system-by-installed-components-budgets-and-project-readme.md). Each step ends
with its gate; the specs come first and are shown red.

| #   | Step                                                                                                                                                                          | Gate                                                                   |
| --- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| 1   | Specs first (red): the checklist blocked and labelled, `disabled` in the real prompter, `(recommended)` in `sa list`, the gate of the UI System                               | the new specs of `add.spec.ts`, `prompter.spec.ts`, `list.spec.ts`     |
| 2   | `installedComponentIds`, the checklist, the labels, the UI System refusing without components and bringing `sa-button` and `sa-toggle`                                        | `vitest run` of `add.spec.ts`, `prompter.spec.ts`, `list.spec.ts`      |
| 3   | Markers in the templates of the UI System, `selectRegions`, the entries of `sa-search`, `sa-theme-color-picker` and the usage cards, a catalog by installed components        | `vitest run` of `regions.spec.ts`, `ui-system.spec.ts`                 |
| 4   | Completing the catalog: `missingEntries`, `update`, the offer after `sa add components`, `sa add ui-system` in a project that has it                                          | `vitest run` of `ui-system.spec.ts`, `add.spec.ts`                     |
| 5   | Budgets: `raiseInitialBudget` in the design base; `sa-tabs.css` below 4 kB                                                                                                    | `vitest run` of `angular-json.spec.ts`, `design.spec.ts`; real build   |
| 6   | The README of the project: `refreshProjectReadme`, its stage in `sa new` and in every `sa add`                                                                                | `vitest run` of `project-readme.spec.ts`, `new.spec.ts`, `add.spec.ts` |
| 7   | The real e2e: default project, some components, architecture, routing, shell, UI System with those components, more components, the catalog completed, build without warnings | `SA_E2E=1` e2e passes                                                  |
| 8   | README, docs, CHANGELOG, ADR-0024 and this plan, `code-review`                                                                                                                | `typecheck`, `lint`, `format:check`, `test`, `build`                   |
| 9   | Commit, push of the branch and of `development`                                                                                                                               | the same gates on the merge                                            |

## Out of scope

Curated previews for the eight components that only have a usage card (`table`, `datepicker`, `section-nav`,
`selectable-item`, `reorder-list`, `preview`, `media-preview`, `weekly-schedule`), completing a catalog the
developer edited, retrofitting the budgets and the README of projects made before, and a UI System that does not
need the starter routing.
