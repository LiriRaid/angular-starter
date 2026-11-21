# Plan 0010: every variant in the UI System and the components synced with the reference apps

Decision: [ADR-0012](../adr/0012-ui-system-variants-and-synced-components.md). Each step ends with its
gate; tests come first.

| #   | Step                                                                                                                                                                                      | Gate                                                     |
| --- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------- |
| 1   | Compare the components of Omni Inbox and YaloAtiendo, decide what is ported, and port it to Omni (drawer, select, modal, button) with its specs, one commit per group                     | Omni: `tsc`, `eslint`, `vitest`, specs red then green    |
| 2   | Port the same commits to the blueprints (`drawer`, `select`, `modal`, `button`), renamed to `as-`, with their specs                                                                       | `pnpm test` in `packages/cli`                            |
| 3   | Specs of the catalog first, shown red against the old catalog: variants per component, the code that follows the chosen variant, the overlays over the page, the toast, `ui-system.code`  | `ng test` of a generated project fails for the new specs |
| 4   | `ui-system.code` (the snippet generator), the catalog with `variants`, `options` and `content`, the component and its template (previews by group, chips, switches, overlays, code block) | the catalog specs green                                  |
| 5   | `uiSystemProfile` (`requiredFiles`) and its engine spec                                                                                                                                   | `vitest run src/engine/ui-system`                        |
| 6   | Verification in a generated project (`--ui-system starter`): `ng build`, `ng test`, the catalog in the browser with `ng serve`, the tokens still moving every preview                     | `ng build` and `ng test` green; seen in the browser      |
| 7   | CHANGELOG, `code-review`, opt-in e2e (`AS_E2E=1`), commits                                                                                                                                | `typecheck`, `lint`, `format:check`, `test`, `build`     |

## Out of scope

The wizard (components picker), the other layout modes, previews for components outside the essential
collection, changing YaloAtiendo, the date inputs and pill tabs of YaloAtiendo, and any change to the
tokens of the UI tab.
