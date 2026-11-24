# ADR-0021: The project is called Starter Angular; the command is `sa` and the prefix `sa-`

- Status: accepted
- Date: 2026-11-24
- Deciders: project maintainer
- Supersedes in part: [ADR-0020](0020-angular-starter-name-list-table-and-short-help.md) (the name, the
  binaries, the package and the selector prefix; the table and the short help stay as they are)

## Context

ADR-0020 named the project Angular Starter, with the command `as` and the selector prefix `as-`. The
maintainer reconsidered it for two reasons. The name put "Angular" first, as if it were the name of the
product, and the project is independent: "Angular" is a trademark of Google and the word should only say
what the tools are for. And `as` stood for _Angular Starter_, so with another name it meant nothing; on
Linux and macOS it is also the GNU assembler.

What the project is does not change: an Angular application that is already built, with its architecture,
structure, conventions, styles and native components, so a team only writes its business. The developer can
change styles, colors and properties, but never builds a button from scratch.

This is not legal advice; the trademark question is the maintainer's to settle before publishing.

## Decision

1. **Name.** The project, the CLI, the package, the repository and every file are called **Starter
   Angular**, written `starter-angular` where an identifier is needed. The package is
   `@liriraid/starter-angular` (0.1.0) and the future components package
   `@liriraid/starter-angular-components`. **Starter for Angular** is the name of the website only, and the
   README explains why: it is a starter for Angular applications.
2. **Binaries.** `sa` (short) and `starter-angular` (full name), with the same behavior. `as` and
   `angular-starter` disappear. The README says that on some Linux systems the `acct`/`psacct` package
   installs `sa`, the process accounting tool, and that `starter-angular`, or
   `npx @liriraid/starter-angular`, works whatever `sa` points to. The README still states that the project
   is not affiliated with Google.
3. **Prefix and tokens.** The reserved selector prefix of the native components is `sa-` (`sa-button`,
   `SaButton`, `--sa-primary-color`, `saTooltip`), the folders and files of the blueprints follow, and the
   environment variables carry `SA_` (`SA_E2E`, `SA_DEBUG`, `SA_LUCIDE_ICONS`).
4. **Configuration file.** A project records its options in `starter-angular.config.json`. There is no
   fallback to the old file name: 0.1.0 is not published and no project outside the tests has it.
5. **History.** Accepted ADRs and plans, and the earlier entries of the CHANGELOG, keep the names they were
   written with; this ADR is where the name changes again. The live text (README, CONTRIBUTING, SECURITY,
   the blueprints, the code, the specs and the links) is rewritten, and `naming.spec.ts` fails if an old
   name or the old prefix comes back.

## Alternatives considered

- **Keep Angular Starter (ADR-0020).** It is the most direct name, but it keeps "Angular" as the product's
  first word, which the maintainer wants to avoid.
- **Blueprint for Angular (`bpa`) or NG Foundation (`ngf`).** Both are free to take but say less about what
  it is; the maintainer prefers a name that reads as a starter.
- **`sfa` for Starter for Angular.** The name for the web is not the name for the tools, so the command
  follows the tools.
- **Keep the prefix `as-`.** No change in the generated apps, but the prefix would mean nothing and would
  be a breaking change later, once the package is published.

## Consequences

- Positive: one name in the docs, the code, the URLs and the generated apps; the prefix, the command and
  the name agree; the project does not present itself as an Angular tool.
- Negative: a project generated with the previous build has `as-` components and the old configuration
  file, and `sa add` will not recognise it; the global install of `@liriraid/angular-starter` has to be
  replaced, and the repository links work only once the GitHub repository is renamed (GitHub redirects the
  old address afterwards).
- Follow-up: rename the GitHub repository and, if wanted, the local folder; create the npm account or scope
  before publishing; a legal review of the name before the first publication.
