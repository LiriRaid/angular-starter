# Plan 0009: components picker and design preferences tabs

Decision: [ADR-0011](../adr/0011-components-picker-and-design-preferences-tabs.md). Each step ends with
its gate; tests come first.

| #   | Step                                                                                                                                                                                   | Gate                                          |
| --- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------- |
| 1   | ADR-0011 and this plan                                                                                                                                                                 | `pnpm run format:check`                       |
| 2   | Tests first, shown red: `config/components`, schema and resolve (`custom`, `componentList`), registry, prompter `checkbox`, wizard (the list), `--components` ids, `as add components` | `pnpm test` fails for the new tests only      |
| 3   | `config/components.ts`, schema, resolve, registry, prompter, wizard, flags, summary, dry run, stages, `as add components`                                                              | `pnpm run typecheck` and the unit tests       |
| 4   | Blueprint: Apariencia keeps the layout only, round swatches with a ring; specs of the page                                                                                             | `vitest run src/engine` and the project specs |
| 5   | Verification in a generated project: the wizard (real prompts traced), `ng build`, `ng test` and the tabs in the browser                                                               | `ng build` and `ng test` green; seen          |
| 6   | Docs (README, CHANGELOG), review, commits                                                                                                                                              | all gates                                     |

## Out of scope

The variants of every component in the UI System and the sync of the components with the two
applications (another session), icon libraries for `as-icon`, the published packages and the web.
