# Plan 0025: `sa lint` and `sa format` run the project's scripts, and every project has `test:watch`

Decision: [ADR-0028](../adr/0028-sa-lint-sa-format-and-test-watch.md). Each step ends with its gate; the specs come
first and are shown red.

| #   | Step                                                                                                                        | Gate                                              |
| --- | --------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------- |
| 1   | Specs first (red): `sa lint`, `sa format` (scripts, flags, arguments per package manager), `test:watch` and its README line | the new specs fail                                |
| 2   | `project-run.ts` with what the three commands share; `sa test` uses it; `scripts.ts` with `sa lint` and `sa format`         | `vitest` of the three command specs               |
| 3   | The commands in the program and in the root help (it stays under 40 lines of 120 columns)                                   | `vitest` of `program.spec`                        |
| 4   | The `test:watch` script in the tooling profile and in the README block of the project                                       | `vitest` of `tooling.spec`, `project-readme.spec` |
| 5   | The real e2e: `sa lint` and `sa format --check` on the recommended project, and `test:watch` in its manifest                | `SA_E2E=1` e2e passes                             |
| 6   | CHANGELOG, ADR-0028, this plan and the READMEs, `code-review`                                                               | `typecheck`, `format:check`, `test`, `build`      |
| 7   | Commit and push of `development`                                                                                            | the same gates on the merge                       |

## Out of scope

`test:coverage` and `audit:safe`, `sa build` and `sa serve`, and a `sa lint` for a project without the script (it says
`sa add tooling`).
