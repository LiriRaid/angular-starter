# ADR-0016: A faster install in `as new` and a leaner end-to-end suite

- Status: accepted
- Date: 2026-11-23
- Deciders: project maintainer

## Context

The end-to-end suite (`AS_E2E=1`) generated fifteen projects with the real Angular CLI, installed the
dependencies of each with npm and built (and tested) every one. A full run took more than half an hour,
it saturated the machine, and under that load a test that passes alone (177 s) failed by timeout.

The same cost is felt by the people who will use the packaged CLI: `as new` installs once, at the end,
and that install is the longest step. The plan is to publish two packages, the CLI and the components,
so the creation of a project has to be as light as it can be.

## Decision

1. **The install asks for less.** `as new` runs `npm install --no-audit --no-fund --prefer-offline` and
   `pnpm install --prefer-offline --no-frozen-lockfile`: both reach for their local cache before the network, and npm skips
   the audit and funding requests it makes after every install; pnpm never freezes its lockfile, because `as add` has just changed `package.json` and a CI environment turns the freeze on (it failed with `ERR_PNPM_OUTDATED_LOCKFILE`). Yarn keeps a plain `install`, because
   its modern versions reject the flag. The arguments come from one function, `installArgsOf`.
2. **The end-to-end suite has seven installed projects, not fifteen.** Each one covers a family of the
   options and carries the assertions of the ones it replaces:
   - Screaming + Starter routing + default Angular SSR (build only);
   - an existing project that gets routing, icons, Starter SSR and the components added, with generated
     features;
   - the recommended project (also checks the Lucide package is installed);
   - every component with Starter SSR and incremental hydration;
   - an existing project that gets the App Shell, every component, presence and the UI System added;
   - a project with presence, the welcome home with its documentation and the UI System;
   - the plain Angular structure.
     The combinations that are no longer installed are covered by the unit specs of the engine (the
     profiles, the stages and the `add` command run with a fake runner).
3. **The projects install with pnpm, except one.** Its content-addressable store links the files, so every install
   after the first is a matter of links; `ng` runs with `pnpm exec`. The project that runs `as add rendering starter-ssr` stays on npm,
   because `ng add @angular/ssr` fails with pnpm (see the follow-up); npm is also covered by the unit specs
   of the install arguments.

## Alternatives considered

- **Sharing one `node_modules` between the projects.** It is the fastest, but the projects add packages
  (Lucide, the CDK) and a shared folder would hide a missing dependency, which is what the suite exists
  to catch.
- **Running the projects in parallel.** The machine is already saturated by one `ng build`; parallel
  runs produced the timeouts.
- **Dropping `ng test` from every project.** The generated specs are part of what a project ships, so
  they run in the projects that have the most of them and in the plain one.

## Consequences

- Positive: less than half of the installs and builds, no timeouts from saturation, and a lighter
  install for the users of the CLI.
- Negative: a bug in a combination that is no longer installed is found by the unit specs, not by a real
  build; the options that matter to the build (SSR, the components, the shell) keep their project.
- Follow-up: `as add rendering ssr|starter-ssr` in a pnpm project fails with "a merge conflicted on path
  /src/server.ts" from `ng add @angular/ssr` (it works with npm and is not caused by this change); it
  needs its own fix.
- Follow-up: when the components package exists, install it from a local registry in the suite instead
  of copying blueprints; measure the real `as new` before and after on a clean machine.
