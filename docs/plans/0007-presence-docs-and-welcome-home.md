# Plan 0007: presence, the documentation of each piece and the welcome home

Decision: [ADR-0009](../adr/0009-presence-documentation-and-welcome-home.md). Each step ends with
its gate; tests come first.

| #   | Step                                                                                                                                                                                                                  | Gate                                                  |
| --- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------- |
| 1   | ADR-0009 and this plan                                                                                                                                                                                                | `pnpm run format:check`                               |
| 2   | Tests first, shown red: registry and resolve (`presence`, the `appShell` requirement), wizard, the edits (user menu, welcome cards, README blocks), the profiles (presence, welcome home, READMEs), `as add presence` | `pnpm test` fails for the new tests only              |
| 3   | Registry, schema, resolve, wizard, `--presence`, `--help`, `as list`, `as add presence`, summary and dry run                                                                                                          | `pnpm run typecheck` and the unit tests               |
| 4   | Edits: `edits/presence.ts` (user-menu html and class, avatars), `edits/readme.ts` (generated blocks), welcome cards, `addProvider` of `providePresence()`                                                             | `vitest run src/engine/edits`                         |
| 5   | Blueprint `blueprints/presence`: `core/presence` (types, transport contract, in-memory and WebSocket transports, services, providers, specs), `presence-styles.css`, `docs/presence.md`                               | `vitest run src/engine/presence` and a spec that runs |
| 6   | Profile `engine/presence`, stage `apply-presence`, dry run, `verify-project`, `as add presence`                                                                                                                       | `pnpm test` and `pnpm run typecheck`                  |
| 7   | READMEs of `core/theme`, `core/common/icons`, `shared/animations`, `shared/components`, `styles` and `core/presence`; the generated blocks in the components and the styles                                           | `vitest run src/engine`                               |
| 8   | Welcome home: `home` replaced by the shell when it is still pristine, `home.data.ts`, spec, the card of presence                                                                                                      | same                                                  |
| 9   | Verification in a generated project: `ng build`, `ng test`, and the welcome home and the status menu in the browser                                                                                                   | `ng build` and `ng test` green; seen in the browser   |
| 10  | Docs (README, CHANGELOG), `code-review`, `simplify`, opt-in e2e for the new cases (`AS_E2E=1`)                                                                                                                        | `typecheck`, `lint`, `format:check`, `test`, `build`  |

## Out of scope

The other layout modes, server rendering of the shell, a server implementation (the document explains
it, the starter ships none), presence in the example pages, and the web of AS Starter.
