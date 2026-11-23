# Plan 0011: the wizard can go back

Decision: [ADR-0013](../adr/0013-wizard-can-go-back.md). Each step ends with its gate; tests come first.

| #   | Step                                                                                                                                                                                 | Gate                                          |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------- |
| 1   | ADR-0013 and this plan                                                                                                                                                               | `pnpm run format:check`                       |
| 2   | Tests first, shown red: `wizard/history`, the wizard (back at each kind of question, flags skipped, the confirmation choice and the change list), the prompter (Esc, hint), `as new` | `pnpm test` fails for the new tests only      |
| 3   | `BackRequested` and `canGoBack` in the prompter, the Esc listener and the hints, the fake prompter answering `BACK`                                                                  | `pnpm run typecheck` and the prompter specs   |
| 4   | `wizard/history.ts` and `runWizard` as a replayed flow; the confirmation moves into the wizard and `commands/new.ts` hands it a summary callback                                     | `pnpm run typecheck` and the wizard specs     |
| 5   | Docs: README, CHANGELOG, `--help` of `new`                                                                                                                                           | `pnpm run format:check`                       |
| 6   | Verification: the compiled wizard driven with Esc keystrokes through a terminal-like stream, the real prompter included                                                              | the script prints the expected question order |
| 7   | Review (`code-review`, `simplify`), full gates, commits and push of the branch                                                                                                       | all gates                                     |

## Out of scope

Going back to the project name, history for `as add`, blueprints and the design preferences (another
session), and the published packages.
