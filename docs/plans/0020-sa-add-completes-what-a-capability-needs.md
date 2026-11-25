# Plan 0020: `sa add` lists the choices, completes what a capability needs and offers what comes next

Decision: [ADR-0023](../adr/0023-sa-add-completes-what-a-capability-needs.md). Each step ends with its gate;
the specs come first and are shown red.

| #   | Step                                                                                                                                      | Gate                                                          |
| --- | ----------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------- |
| 1   | Specs first (red): the list of architectures, the chain of prerequisites (terminal, no, dry run, no terminal), the offers, the name       | the new specs of `add.spec.ts` fail for the right reason      |
| 2   | `prerequisitesOf` from the registry; the name of the project is its folder                                                                | `vitest run` of `add.spec.ts`, `init.spec.ts`, `find.spec.ts` |
| 3   | `sa add` asks and adds what is missing in order; the architecture selector; the offer of the UI System after the shell and the components | `vitest run` of `add.spec.ts`                                 |
| 4   | The real e2e: components, architecture, feature, routing, shell and UI System, build and test                                             | `SA_E2E=1` e2e passes                                         |
| 5   | CHANGELOG, ADR-0023 and this plan, `code-review`                                                                                          | `typecheck`, `lint`, `format:check`, `test`, `build`          |
| 6   | Commit, push of the branch and of `development`                                                                                           | the same gates on the merge                                   |

## Out of scope

An `all` option for the design of the app shell, `sa add app-shell` completing only what the shell lacks, a
shell and a UI System that do not need the starter routing, and the architectures that are still planned.
