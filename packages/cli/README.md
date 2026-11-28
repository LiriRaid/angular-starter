# Starter Angular CLI

`sa` creates [Angular](https://angular.dev/) applications with a ready-made architecture (Screaming Architecture, a
navigation tree, an app shell, design preferences and native `sa-` components) and adds those pieces one at a time to
a project that already exists. It runs the official `ng new` and never replaces the Angular CLI. The code it generates
is yours: Starter Angular is not a runtime dependency of the applications it creates.

> **Status: pre-alpha.** Names, scope and commands are provisional.

## Install

Requires Node.js `^22.22.3 || ^24.15.0 || >=26.0.0`.

| Package manager | Install globally                            | Run without installing                          |
| --------------- | ------------------------------------------- | ----------------------------------------------- |
| npm             | `npm install -g @liriraid/starter-angular`  | `npx @liriraid/starter-angular new my-app`      |
| pnpm            | `pnpm add -g @liriraid/starter-angular`     | `pnpm dlx @liriraid/starter-angular new my-app` |
| Yarn            | `yarn global add @liriraid/starter-angular` | `yarn dlx @liriraid/starter-angular new my-app` |

The package installs two binaries with the same behavior: the short `sa` and the full `starter-angular`.

> **`sa` on some Linux systems.** The `acct` / `psacct` package installs `sa`, the process accounting summary tool,
> and it can sit before this CLI in your `PATH`. `starter-angular` works whatever `sa` points to, so use it there (or
> `npx @liriraid/starter-angular`).

## Use

```sh
sa new my-app             # the wizard asks for each option
sa new my-app --defaults  # the recommended set, no prompts
sa new my-app --dry-run   # draws the files it would create as a tree and writes nothing
```

| Command                            | What it does                                                                                             |
| ---------------------------------- | -------------------------------------------------------------------------------------------------------- |
| `new`                              | Creates a project (wizard, flags, `--defaults`, `--config`, `--dry-run`)                                 |
| `init`                             | Prepares an Angular project that `sa new` did not make                                                   |
| `add <capability> [value]`         | Adds architecture, routing, app shell, presence, components, UI System, icons, rendering or tooling      |
| `generate` (`g`) `<kind> <name>`   | Generates a `feature` or a `component` that follows the architecture of the project                      |
| `test`, `lint`, `format`           | Run the tests, the lint and the format of the project through its package manager, from any folder of it |
| `list`, `info`, `config`, `doctor` | See what each option is, the options of the project, its configuration and the state of your environment |
| `version`                          | Prints the version of the CLI and of the Angular CLI it runs                                             |

`sa --help` lists every command and `sa <command> --help` shows the flags and examples of each one.

## More

- Full documentation, options and examples: the [repository README](https://github.com/LiriRaid/starter-angular#readme).
- Decisions behind the CLI: [`docs/`](https://github.com/LiriRaid/starter-angular/tree/main/docs).
- What changed in each version: [CHANGELOG](https://github.com/LiriRaid/starter-angular/blob/main/CHANGELOG.md).
- Problems and ideas: [issues](https://github.com/LiriRaid/starter-angular/issues). For security reports see
  [SECURITY.md](https://github.com/LiriRaid/starter-angular/blob/main/SECURITY.md).

## Not affiliated with Google

Starter Angular is an independent, community-driven project. It is not affiliated with, sponsored by, or endorsed by
Google or the Angular team. "Angular" is a trademark of Google, used here only to describe what the tool is for.

## License

[MIT](https://github.com/LiriRaid/starter-angular/blob/main/LICENSE). Third-party notices:
[THIRD_PARTY_NOTICES.md](https://github.com/LiriRaid/starter-angular/blob/main/THIRD_PARTY_NOTICES.md).
