# Plan 0018: the Starter Angular name, the `sa` command and the `sa-` prefix

Decision: [ADR-0021](../adr/0021-starter-angular-name-sa-command-and-prefix.md). Each step ends with its
gate; the specs come first and are shown red.

| #   | Step                                                                                                                                                                   | Gate                                                                |
| --- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| 1   | Specs first (red): the manifest, the bins, the config file, the old names, the prefix and the `SA_` variables (`naming.spec.ts`)                                       | the new specs fail for the right reason                             |
| 2   | Rename the name, the command and the config file: package `@liriraid/starter-angular`, bins `sa` and `starter-angular`, `starter-angular.config.json`, URLs, README    | `vitest run` of the naming, program and list specs                  |
| 3   | Rename the prefix: `sa-` in selectors, classes, tokens, `Sa*` symbols and the folders and files of the blueprints, and `SA_` in the variables                          | `typecheck` and the whole `vitest run`                              |
| 4   | README (why the web says Starter for Angular, the `sa` note), CHANGELOG, ADR-0021 and this plan                                                                        | `format:check`                                                      |
| 5   | The real Angular CLI: `SA_E2E=1` e2e builds a generated app with the `sa-` components                                                                                  | the e2e passes                                                      |
| 6   | `code-review`, `simplify`, commits by topic, push of the branch and of `development`                                                                                   | `typecheck`, `lint`, `format:check`, `test`, `build` on the merge   |
| 7   | Maintainer's side: rename the GitHub repository, open the PR to `main`, then swap the global CLI (`pnpm remove -g @liriraid/angular-starter`, install the new tarball) | the installed `sa version` prints 0.1.0 and the Angular CLI version |

## Out of scope

Publishing to npm, the components package, the website, a legal review of the name, and rewriting the
accepted ADRs and plans.
