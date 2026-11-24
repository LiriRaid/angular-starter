# Plan 0016: commands that work on any Angular project

Decision: [ADR-0019](../adr/0019-commands-for-existing-projects.md). Each step ends with its gate; the specs
come first and are shown red.

| #   | Step                                                                                                                                        | Gate                                                 |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------- |
| 1   | `as list`: the `Add` and `New` lines of each option and the kebab-case names of the categories                                              | `vitest run` of the list spec                        |
| 2   | Detection of the options of an existing project (`engine/detect.ts`)                                                                        | `vitest run` of the detect spec                      |
| 3   | `as init` and the hint of `as add`, `as generate` and `findProject` when there is no configuration                                          | `vitest run` of the init and project specs           |
| 4   | Components without an architecture: the requirement moves to `offeredWith`, the shared foundation stage (aliases, barrel)                   | specs of capabilities, stages and add                |
| 5   | `as add architecture screaming` for a project that is still what `ng new` generates                                                         | `vitest run` of the add spec                         |
| 6   | `as generate component` in a project that is not Screaming                                                                                  | `vitest run` of the generate spec                    |
| 7   | End to end: an Angular project made with `ng new`, then `as init`, `add components`, `add architecture` or `generate component`, `ng build` | `AS_E2E=1` run of the new test                       |
| 8   | CHANGELOG, `code-review`, `simplify`, commits by topic, push of the branch and of `development`                                             | `typecheck`, `lint`, `format:check`, `test`, `build` |

## Out of scope

The Starter SSR with its shell, architectures other than Screaming, applying an architecture over a project
that has code, and a change to the recommended marks of the wizard.
