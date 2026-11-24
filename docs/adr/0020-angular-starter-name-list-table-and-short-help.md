# ADR-0020: The project is called angular-starter; `as list` is a table; `as --help` is short

- Status: accepted
- Date: 2026-11-24
- Deciders: project maintainer
- Supersedes in part: [ADR-0001](0001-cli-architecture-and-toolchain.md) (the name, the package and the binaries)

## Context

The project was called `as-starter`, a working name: two letters that mean little and a package scope
(`@as-starter`) that nobody owns. The maintainer wants the name `angular-starter` everywhere. On npm
`angular-starter` without a scope is taken (version 6.0.0, by someone else), and the packages must carry
the maintainer's name, not look like something of the Angular team or of Google. Angular is a trademark of
Google; the project is independent and uses the word only to say what the tools are for.

The command `as` is short to type, but on Linux and macOS `as` is the GNU assembler (`gcc` and `clang` run
it), so it can shadow or be shadowed by the CLI in the `PATH`.

Two outputs also grew past what they are for. `as list` prints each option on several lines, and the
commands of ADR-0019 sit under the description at different columns in each category. `as --help` carries
groups, seven examples and a note, which `as <command> --help` already says better.

## Decision

1. **Name.** The project, the repository and the folder are `angular-starter`; the text calls it Angular
   Starter. The CLI package is `@liriraid/angular-starter` and the future components package
   `@liriraid/angular-starter-components`. The scope is the maintainer's own, so the packages are not
   mistaken for the Angular team's; no organisation has to be created. The version is `0.1.0`; 1.0 waits for
   the maintainer. The reserved selector prefix `as-` of the native components does not change.
2. **Binaries.** `as` (short) and `angular-starter` (full name), with the same behavior. `as-starter`
   disappears. The README and this ADR say that on Linux and macOS `as` can be the GNU assembler and that
   `angular-starter`, or `npx @liriraid/angular-starter`, works whatever `as` points to. The README states that
   the project is not affiliated with Google.
3. **History.** Accepted ADRs and plans keep the names they were written with; this ADR is where the name
   changes. Only the live text (README, CONTRIBUTING, SECURITY, the blueprints, the code and the repository
   links) is rewritten.
4. **`as list` is one table**: `ID`, `Commands` and `Option`. The commands are one per line, `as add
<capability> <id>` only where a project can add it and `as new --<flag> <id>`; a planned option has none and
   says `(planned)`. The third column holds the name, the description and the link. The first two columns
   have the same width in every category, so no row starts further right than another. The width is the
   terminal's (100 when the output is not a terminal). When the third column would be narrower than 40
   characters, or than the longest name, it is dropped: the name, the description and the link go under the
   row, below the commands.
5. **`as --help` is short**, like `ng --help`: the usage, the commands with a one-line description each, and
   the options. The examples and notes live in `as <command> --help`.
6. **`as version`, `-v` and `--version`** print the CLI version and the version of the Angular CLI that
   `as new` runs (the tested one, `ANGULAR_CLI_VERSION`), not the latest on npm.

## Alternatives considered

- **`@angular-starter/cli`.** It reads well, but the organisation is not confirmed free and needs the
  maintainer to create it before the first publication; if it is taken, the name changes again.
- **`angular-starter` without a scope.** It is taken on npm.
- **Keeping `as-starter` as a second binary.** Two names are enough, and a third makes a pre-1.0 project
  harder to explain.
- **A fixed width for the table.** It breaks the format on terminals narrower than that width.

## Consequences

- Positive: one name in the docs, the code and the URLs; `angular-starter` is always available when `as`
  is shadowed; `as list` can be read by column and `as --help` fits in a screen.
- Negative: the global install of `@as-starter/cli` has to be removed (`pnpm remove -g @as-starter/cli`)
  and the new package installed, and the repository links work only once the GitHub repository is renamed
  (GitHub redirects the old address afterwards).
- Follow-up: rename the GitHub repository and the local folder (the maintainer's call), create the npm
  account or scope before publishing, and publish `@liriraid/angular-starter-components` when it exists.
