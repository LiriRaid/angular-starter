# Plan: explicit wizard, design base, native components, project commands (ADR-0004, 0005, 0006)

Each step ends with its gate; a step is done only when its gate passes. Tests come first (shown
red), then the code. Each block ends with commit and push of `development`.

| #   | Step                                                                                                                                                                           | Gate                                                                          |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------- |
| 1   | ADR-0004, 0005, 0006 and this plan                                                                                                                                             | `pnpm format:check`                                                           |
| 2   | B1 registry + wizard + defaults: tests first (red), registry fields, one style list, `requires`, derived defaults, aligned wizard format, `as list` with descriptions          | `pnpm test` + `pnpm typecheck`                                                |
| 3   | B2 Starter SSR: tests first, `rendering` profile (hydration providers, `@defer` example), `ng new --ssr` base                                                                  | `pnpm test`, opt-in e2e for `ssr` and `starter-ssr`                           |
| 4   | B3 help by category, `config`, `add` (icons, routing, rendering), `generate`: tests first, project discovery                                                                   | `pnpm test` + `pnpm typecheck`                                                |
| 5   | B4 design base: `styles/`, `core/theme`, `core/icons`, `shared/utils` with pipes and directives, root without placeholder, angular.json and app.config edits, Tailwind mapping | `pnpm test` + e2e CSR/Tailwind build and test                                 |
| 6   | B5 `recommended` components in batches (16), each with spec; `as add components`                                                                                               | `pnpm test` + e2e `ng build` and `ng test`                                    |
| 7   | B6 `all` components (10 more) in batches                                                                                                                                       | same                                                                          |
| 8   | Matrix e2e (`AS_E2E=1`): CSR, SSR, Starter SSR; with/without Tailwind; Lucide; components                                                                                      | `AS_E2E=1 pnpm test`                                                          |
| 9   | README, CHANGELOG, `code-review`, `simplify`, full gates                                                                                                                       | `pnpm typecheck && pnpm lint && pnpm format:check && pnpm test && pnpm build` |
