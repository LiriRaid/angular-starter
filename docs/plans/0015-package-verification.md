# Plan 0015: verify the CLI as an installed package

Decision: [ADR-0017](../adr/0017-package-verification-and-clear-tool-errors.md). Each step ends with its
gate; tests come first where there is code.

| #   | Step                                                                                                                                                               | Gate                                                 |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------- |
| 1   | Specs first, shown red: `buildNgAddSsrCommand` (local CLI with node, `npx` without dependencies)                                                                   | `vitest run` of `angular-cli.spec.ts`                |
| 2   | `buildNgAddSsrCommand` and its use in the `addAngularSsr` stage; the e2e project that adds SSR goes back to pnpm                                                   | the same spec green, `AS_E2E=1` run of that test     |
| 3   | Remove any global `as-starter` (`pnpm ls -g`, `npm ls -g`, `where as`), `pnpm build`, `pnpm --filter @as-starter/cli pack`                                         | the tarball holds `dist`, `blueprints` and `bin`     |
| 4   | Install the tarball globally and run it from a folder outside the repository: `new --defaults` with npm, pnpm and yarn, the options, `add`, `generate`, `ng build` | every command exits 0; times written down            |
| 5   | Specs first for what step 4 finds: `refusalOf`, `validateEnvironment` and `as doctor` with a tool that refuses to run                                              | `vitest run` of the three specs                      |
| 6   | CHANGELOG, `code-review`, commits by topic, push of the branch and of `development`                                                                                | `typecheck`, `lint`, `format:check`, `test`, `build` |

## Measured (Windows 11, Node 24, warm caches, one run each)

`as-starter new <name> --defaults --no-git`, the global binary from the tarball:

| Package manager | Creation only (`--no-install`) | With install |
| --------------- | ------------------------------ | ------------ |
| npm 11          | 8.6 s                          | 100.2 s      |
| pnpm 12         | 5.9 s                          | 23.7 s       |
| yarn 1.22       | 6.6 s                          | 38.5 s       |

## Out of scope

Publishing to npm, a CI job for the tarball, a README for the package and the Angular defaults noted in
the ADR.
