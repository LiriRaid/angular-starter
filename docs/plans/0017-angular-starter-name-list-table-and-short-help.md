# Plan 0017: the angular-starter name, the `as list` table and the short help

Decision: [ADR-0020](../adr/0020-angular-starter-name-list-table-and-short-help.md). Each step ends with its
gate; the specs come first and are shown red.

| #   | Step                                                                                                                                                                          | Gate                                                                |
| --- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| 1   | Specs first (red): the manifest and the old name (`naming.spec.ts`), the `as list` table, the short root help and `version`                                                   | the new specs fail for the right reason                             |
| 2   | Rename: package `@liriraid/angular-starter` 0.1.0, binaries `as` and `angular-starter`, repository links, "Angular Starter" in prose, README                                  | `vitest run` of the naming, capabilities and shell specs            |
| 3   | `as list` as a table: the terminal width in `CliIo`, `wrapText`, the same widths in every category, the narrow layout                                                         | `vitest run` of the list and program specs                          |
| 4   | Short root help and `version` with the CLI and Angular CLI versions                                                                                                           | `vitest run` of the program spec                                    |
| 5   | CHANGELOG, ADR-0020 and this plan, `code-review`, `simplify`                                                                                                                  | `typecheck`, `lint`, `format:check`, `test`, `build`                |
| 6   | Commits by topic, push of the branch and of `development`                                                                                                                     | the same gates on the merge result                                  |
| 7   | Maintainer's side: rename the GitHub repository and the local folder, open the PR to `main`, then swap the global CLI (`pnpm remove -g @as-starter/cli`, install the tarball) | the installed `as version` prints 0.1.0 and the Angular CLI version |

## Out of scope

Publishing to npm, the components package, a website, and rewriting the accepted ADRs and plans.
