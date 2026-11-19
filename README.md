# AS Starter

> **Status: pre-alpha.** The CLI core exists and creates Angular applications with the default structure or the Screaming Architecture profile; the app shell and the native UI are not available yet. Names, scope and commands are provisional.

AS Starter is an independent, community-driven ecosystem of developer tools for [Angular](https://angular.dev/). Its goal is to remove the repetitive work every Angular team redoes when starting an application: architecture, routing, app shell, layouts, theming and reusable UI.

The generated code belongs entirely to the developer. AS Starter is not a runtime dependency of the applications it creates, and the official Angular CLI keeps working as usual.

## Planned scope

| Piece                                  | Purpose                                                                            |
| -------------------------------------- | ---------------------------------------------------------------------------------- |
| CLI (`as`)                             | Create applications and add capabilities to existing ones                          |
| Schematics                             | Official Angular extension mechanism for generating and transforming code          |
| Native UI                              | Source-available components built only with Angular, HTML, CSS and Signals         |
| Layout / Theme / Runtime configuration | One configurable app shell, design tokens, and settings applied without a redeploy |
| Component registry                     | A single metadata source for the CLI, docs, playground and AI skills               |
| Documentation site                     | Interactive docs built with the project's own components                           |

The first architecture profile, **Screaming Architecture** (`core/`, `features/`, `shared/`, standalone components, Signals, one lazy route file per feature), is available with `--architecture screaming`; see [ADR-0002](docs/adr/0002-screaming-architecture-profile.md). Other profiles come later. **Angular Starter Routing** (`--routing starter`, Screaming only) adds one navigation tree that drives page titles and breadcrumbs (`TitleStrategy`, `BreadcrumbService`), ready for the sidebar of the app shell; see [ADR-0003](docs/adr/0003-starter-routing.md). Lucide icons (`--icons lucide`) are the first icon library offered.

## Install the CLI

The package is not published yet. Once it is, any package manager works:

| Package manager | Install globally                  | Run without installing                |
| --------------- | --------------------------------- | ------------------------------------- |
| npm             | `npm install -g @as-starter/cli`  | `npx @as-starter/cli new my-app`      |
| pnpm            | `pnpm add -g @as-starter/cli`     | `pnpm dlx @as-starter/cli new my-app` |
| Yarn            | `yarn global add @as-starter/cli` | `yarn dlx @as-starter/cli new my-app` |

Yarn 2 and later have no global installs; use `yarn dlx`. Then run `as-starter new my-app`. Until
the package is published, install it from a clone (see below). The package manager of the
generated project is chosen separately, with `--package-manager` or in the wizard.

## Try the CLI (development)

Requires Node.js `^22.22.3 || ^24.15.0 || >=26.0.0` (the range of the Angular CLI it runs) and pnpm.

```sh
pnpm install
pnpm build
node packages/cli/dist/bin.js new my-app            # interactive wizard
node packages/cli/dist/bin.js new my-app --defaults # no prompts
node packages/cli/dist/bin.js new my-app --dry-run  # show the plan, create nothing
node packages/cli/dist/bin.js new my-app --architecture screaming --defaults
node packages/cli/dist/bin.js new my-app --architecture screaming --routing starter --defaults
```

`as new` runs the official `ng new` (Angular CLI 22.3.0, the tested version) with every option set
explicitly, then installs dependencies and creates the initial Git commit. Interactive and
non-interactive runs (`--defaults`, flags, `--config <file>`) produce the same validated
configuration, which is saved in `angular-starter.config.json` inside the new project.

| Command                                    | Status        |
| ------------------------------------------ | ------------- |
| `new`, `list`, `info`, `doctor`, `version` | Available     |
| `generate`, `add`, `config`, `update`      | Not available |

Only options that can really be generated are offered. `as list` shows what is available and what is
planned. The package installs two binaries, `as-starter` and the short alias `as`; on macOS and
Linux `as` is normally the system assembler, so prefer `as-starter` or `npx @as-starter/cli` there.

To install your clone as a global command (no publishing involved), after `pnpm build`:
`pnpm add -g ./packages/cli`, or `npm pack` inside `packages/cli` and `npm install -g` the `.tgz`.

Tests: `pnpm test`. End-to-end tests that run the real Angular CLI (network required) are opt-in:
`AS_E2E=1 pnpm --filter @as-starter/cli exec vitest run tests/e2e.spec.ts` (PowerShell:
`$env:AS_E2E=1`).

## What this project is not

- Not a component library such as PrimeNG, Angular Material or NG-ZORRO.
- Not an admin template or a visual app builder.
- Not a fork or replacement of Angular CLI or Tailwind CSS.
- **Not affiliated with, sponsored by, or endorsed by Google or the Angular team.** "Angular" is used only to describe compatibility. Trademark and naming policies are being reviewed before any public release.

## Roadmap

1. Research and definition (licences, names, compatibility matrix, CLI architecture)
2. Analysis of reference projects
3. CLI core and the first architecture profile (Screaming Architecture)
4. Infrastructure capabilities, app shell, layouts and design system
5. Runtime configuration, more architectures, advanced generators
6. Testing, documentation and public release

## License

[MIT](LICENSE). Third-party software notices live in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
