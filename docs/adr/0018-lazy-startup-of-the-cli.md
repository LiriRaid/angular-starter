# ADR-0018: The commands that change files load their code when they run

- Status: accepted
- Date: 2026-11-23
- Deciders: project maintainer

## Context

Measured on the installed package (ADR-0017), `as-starter --version` took 2.1 s, `as list` 2.0 s and
`as new --help` about the same, when Node itself starts in 0.26 s. Every command paid for loading
`ts-morph` (about 0.65 s), `execa` (about 0.6 s) and the whole engine, though only `new`, `add` and
`generate` use them.

The creation of a project is not helped by this: it is dominated by the Angular CLI and the install.
Measured on identical copies of a created project, the install with npm takes 90 s and none of
`--progress=false`, `--ignore-scripts` or both made it faster (99 to 105 s); resolving the dependencies is
11 s of that and the rest is writing 322 MB of `node_modules`. The flags of ADR-0016 stay as they are.

## Decision

1. `program.ts` imports `new`, `add` and `generate` when their action runs. What the help needs from
   them (`ADDABLE`, `addableValues`, `GENERATE_KINDS`) lives in `commands/addable.ts` and
   `commands/generate-kinds.ts`; `add.ts` and `generate.ts` re-export them.
2. `runCommand` imports `execa` on the first command it runs.
3. A spec (`tests/startup.spec.ts`) fails if `--version`, `--help`, `list` or the help of `new`, `add` and
   `generate` load `ts-morph` or `execa` again.

## Alternatives considered

- **Bundle the CLI into one file.** It would cut more, but it adds a build tool and changes how the
  blueprints are found; lazy loading gets most of the gain with no new dependency.
- **Load `ts-morph` lazily inside the edits.** The edit code uses its enums and type guards everywhere;
  loading the commands lazily needs no change there.

## Consequences

- Positive: `--version`, `list` and the help start in about 0.5 s instead of 2.1 s; `new`, `add` and
  `generate` pay the same as before, once.
- Negative: an import error in those commands now shows when they run, not at startup; the specs of each
  command import them directly, so a broken module still fails the suite.
- The install of `as new` with npm stays the slowest of the three package managers (pnpm 24 s, yarn 38 s,
  npm 100 s); the cause is disk writes, not a flag.
