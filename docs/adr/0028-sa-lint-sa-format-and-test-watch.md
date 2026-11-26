# ADR-0028: `sa lint` and `sa format` run the project's scripts, and every project has `test:watch`

- Status: accepted
- Date: 2026-11-26
- Deciders: project maintainer
- Refines: [ADR-0027](0027-default-eslint-prettier-and-sa-test.md), whose follow-up proposed both commands

## Context

ADR-0027 gave every project ESLint, Prettier and the scripts `lint`, `lint:fix`, `format` and `format:check`, and gave
the CLI `sa test`. The two reference applications also carry a `test:watch` script (Vitest in watch mode), and
the maintainer wants the same checks to be run from `sa` as from the package manager: whoever created the project,
`ng`, `pnpm` and `sa` should do the same.

## Decision

1. **`sa lint` and `sa format` run the script of the project.** They find the Angular workspace from any folder, take
   the package manager of its lockfile and run `<manager> run lint` (or `format`), in the terminal, with the exit code
   of the script. Two flags choose the sibling script and are not handed over: `sa lint --fix` runs `lint:fix` and
   `sa format --check` runs `format:check`. Every other argument goes to the script (npm needs `--` before them, the
   others do not); they are meant for options such as `--max-warnings 0`, since the script already holds its glob, so
   a path typed after it is added to the glob and does not narrow the run. They run the script and not the tool because the scripts are the contract of the project: the glob,
   the formats of the stylesheets and the ESLint setup are what the project decided.
2. **A project without the script is told how to get it.** `sa lint` in a project with no `lint` script stops with
   exit code 2 and says `sa add tooling`. Like `sa test`, the commands need an Angular workspace with its dependencies
   installed (Yarn Plug'n'Play counts) and do not need the project to have been made by Starter Angular.
3. **One runner for the three commands.** `project-run.ts` holds what `sa test`, `sa lint` and `sa format` share: the
   workspace and package manager lookup, the installed check, the script lookup and the run that keeps the exit code.
4. **Every project has `test:watch`.** The tooling adds `test:watch` (`ng test --watch`) next to `test`, also to a
   project that keeps its own ESLint setup, and the README block of the project lists it. `sa add tooling` completes a
   project that has everything but this script.

## Alternatives considered

- **Run ESLint and Prettier directly** (`eslint src`): it would work in a project without scripts, but it would repeat
  the globs in the CLI and ignore a project that changed them.
- **`test:coverage` and `audit:safe`** (also in OmniInbox): left out. Coverage needs `@vitest/coverage-v8`, whose peer
  dependency is the exact version of Vitest that `ng new` installs, so any release of Vitest in the range would break
  the install; the audit scripts depend on the package manager.

## Consequences

- Positive: `sa test`, `sa lint` and `sa format` give the same results as the scripts, from any folder, in any
  Angular project that has them.
- Negative: a project that deleted its `lint` script cannot use `sa lint` until `sa add tooling` brings it back.
- Follow-up: `test:coverage`, once there is a way to keep `@vitest/coverage-v8` in step with Vitest; a `sa build`
  and `sa serve` in the same family.
