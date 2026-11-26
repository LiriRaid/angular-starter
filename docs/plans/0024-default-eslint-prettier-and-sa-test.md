# Plan 0024: Every project comes with ESLint and Prettier ready, and `sa test` runs the tests

Decision: [ADR-0027](../adr/0027-default-eslint-prettier-and-sa-test.md). Each step ends with its gate; the specs
come first and are shown red.

| #   | Step                                                                                                                                                                                      | Gate                                                       |
| --- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------- |
| 1   | The proof: install the ESLint packages in a generated project with every piece, lint it and run `prettier --check`; it shows which two rules the `sa-` components break and the 150 files | `eslint` and `prettier --check` on the scratch project     |
| 2   | Specs first (red): `addDevDependencies` and `addScripts`, the tooling profile, the stages, `sa add tooling`, `sa test`                                                                    | the new specs fail                                         |
| 3   | `package-json.ts` (dev dependencies and scripts), `TOOLING_PACKAGES` in `compat.ts`                                                                                                       | `vitest` of `package-json.spec`                            |
| 4   | The blueprint `blueprints/tooling/eslint.config.mjs.tpl` and the profile `engine/tooling/tooling.ts` (plan, `isComplete`, `apply`)                                                        | `vitest` of `tooling.spec`                                 |
| 5   | The stages `apply-tooling` and `format-project` in `sa new`, and `tooling` in `verify-project`                                                                                            | `vitest` of `stages.spec`, `new.spec`                      |
| 6   | `sa add tooling`: the command, the help and the word                                                                                                                                      | `vitest` of `add-tooling.spec`, `add.spec`, `program.spec` |
| 7   | `sa test`: finds the workspace and the package manager, hands over the arguments, keeps the exit code                                                                                     | `vitest` of `test-command.spec`                            |
| 8   | The README block of the project lists the lint and format scripts it has                                                                                                                  | `vitest` of `project-readme.spec`                          |
| 9   | The real e2e: a project with every piece and one with every component pass `lint`, `format:check`, build and `sa test`                                                                    | `SA_E2E=1` e2e passes                                      |
| 10  | CHANGELOG, ADR-0027, this plan and the READMEs, `code-review`                                                                                                                             | `typecheck`, `format:check`, `test`, `build`               |
| 11  | Commit and push of `development`                                                                                                                                                          | the same gates on the merge                                |

## Out of scope

`sa lint` and `sa format` as pass-through commands, a CI workflow, Husky or lint-staged, the rules of accessibility
for templates (`templateAccessibility`), type-aware linting, and reformatting a project that already exists.
