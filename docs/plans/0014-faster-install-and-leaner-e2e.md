# Plan 0014: a faster install and a leaner end-to-end suite

Decision: [ADR-0016](../adr/0016-faster-install-and-leaner-e2e.md). Each step ends with its gate; tests come first.

| #   | Step                                                                                                        | Gate                                                 |
| --- | ----------------------------------------------------------------------------------------------------------- | ---------------------------------------------------- |
| 1   | Specs first, shown red: `installArgsOf` per package manager and the arguments `as new` runs                 | `vitest run` of `stages.spec.ts` and `new.spec.ts`   |
| 2   | `installArgsOf` and its use in the install stage                                                            | the same specs green                                 |
| 3   | The end-to-end suite: seven projects, pnpm, the assertions of the removed projects moved into the ones left | `typecheck`, then `AS_E2E=1` run of `e2e.spec.ts`    |
| 4   | CHANGELOG, `code-review`, commits by topic, push of the branch and of `development`                         | `typecheck`, `lint`, `format:check`, `test`, `build` |

## Out of scope

Publishing the packages, a local registry for the components package, the website, and any change to
the options of `as new`.
