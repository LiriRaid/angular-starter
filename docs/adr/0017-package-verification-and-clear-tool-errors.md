# ADR-0017: Verify the CLI as a package, and say why a tool refuses to run

- Status: accepted
- Date: 2026-11-23
- Deciders: project maintainer

## Context

Until now the CLI was only run from the repository (`node packages/cli/dist/bin.js`). What a user gets
is different: a tarball that holds `dist` and `blueprints`, installed globally, with the `as` and
`as-starter` shims of the package manager that installed it. Nothing proved that the package works
from a folder outside the repository, with each of npm, pnpm and yarn.

Doing so also found two defects, the first already recorded in ADR-0016: `ng add @angular/ssr` ran twice
under pnpm on Windows, and a package manager that is installed but refuses to run was reported as "not
found".

## Decision

1. **The package is verified as a user would use it** (plan 0015): `pnpm build`, `pnpm pack`, a global
   install from the tarball, and `as-starter new` / `as add` from a folder outside the repository with
   the three package managers and the main options. The tarball is the unit under test, not the
   repository.
2. **`ng add @angular/ssr` runs the project's own Angular CLI** with node (`buildNgAddSsrCommand`, see
   the resolved consequence of ADR-0016). It falls back to `npx` only when the project has no
   dependencies installed.
3. **A tool that is installed but refuses to run says so.** `refusalOf(error)` returns the first line
   the tool printed to stderr when it started and failed. `as new` stops with `"yarn" could not run:
<that line>` and `as doctor` warns with the same text; a tool that cannot be started at all is still
   "not found". The case that surfaced it: corepack refuses to run yarn inside a folder whose
   `package.json` names pnpm in `packageManager`.

## Alternatives considered

- **Keep running the CLI from the repository only.** Cheap, but it cannot see packaging mistakes
  (`files`, `bin`, the blueprint path) or the shims of each package manager.
- **An automatic end-to-end test of the tarball.** It needs a global install, which changes the machine
  of whoever runs it; it stays a documented procedure (plan 0015) until there is a CI job with a clean
  runner.
- **Run `ng add` through `pnpm exec`.** `pnpm exec` also reaches the `.bin` shim, so it has the same
  problem.

## Consequences

- Positive: the package was exercised end to end with the three package managers; the pnpm bug is
  fixed with a spec; the messages of `as new` and `as doctor` stop hiding the real cause.
- Negative: the verification is manual; it needs network and several minutes.
- Observed, not changed (they are Angular's or the product's rules):
  - `ng add @angular/ssr` writes `"allowedHosts": []`, so `node dist/<app>/server/server.mjs` answers
    400 on `localhost` until `NG_ALLOWED_HOSTS` or `security.allowedHosts` lists the host.
  - The generated builds warn that the initial bundle exceeds its 500 kB budget and that
    `as-tabs.css` exceeds 4 kB.
  - The package has no `README.md` of its own, so a registry page would be empty.
