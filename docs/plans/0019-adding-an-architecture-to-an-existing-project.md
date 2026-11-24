# Plan 0019: adding an architecture to an existing project

Decision: [ADR-0022](../adr/0022-adding-an-architecture-to-an-existing-project.md). Each step ends with its
gate; the specs come first and are shown red.

| #   | Step                                                                                                                                                                    | Gate                                                     |
| --- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------- |
| 1   | Specs first (red): the structure over a bare project, over one with components, with code of its own, with a changed root, an alias that points elsewhere, the question | the new specs of `add.spec.ts` fail for the right reason |
| 2   | `ArchitectureProfile.adopt`; the Screaming profile adds folders, README and aliases, adapts the untouched skeleton and lists the rest                                   | `vitest run` of `add.spec.ts` and the engine specs       |
| 3   | The stage tells what it adapted, removed and left to review; `sa add architecture` asks about the routing and the shell in a terminal                                   | `vitest run` of `add.spec.ts`                            |
| 4   | The fake `ng new` workspace carries Angular's welcome markers; the real e2e: components, then the architecture, a feature, the routing and the shell, build and test    | `SA_E2E=1` e2e passes                                    |
| 5   | CHANGELOG, ADR-0022 and this plan, `code-review`                                                                                                                        | `typecheck`, `lint`, `format:check`, `test`, `build`     |
| 6   | Commit, push of the branch and of `development`                                                                                                                         | the same gates on the merge                              |

## Out of scope

An `all` option for the design of the app shell, `sa add app-shell` completing only what the shell lacks, a
guided move of existing code into the architecture, and the architectures that are still planned.
