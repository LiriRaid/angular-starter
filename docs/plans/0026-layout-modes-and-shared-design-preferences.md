# Plan 0026: layout modes as run-time variants and shared design preferences

Decision: [ADR-0029](../adr/0029-layout-modes-as-runtime-variants-and-shared-design-preferences.md). One step per
commit on `feat/app-shell-layout-modes`; every step starts with its specs, shown red, and ends green on `typecheck`,
`format:check`, `test`, `build` and the real e2e (`SA_E2E=1`), with a look in the browser, light and dark.

| #   | Step                                                                                                                                                                  | Gate                                       | State |
| --- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------ | ----- |
| 1   | Foundation: `layout` preference, traits signal, `layout-modes.ts`, store and notifier contracts (memory store), `updateAvailable` alert, Apariencia switches          | specs of the service, tab, main; e2e       | done  |
| 2   | `HttpDesignPreferencesStore`, polling and WebSocket notifiers, `docs/design-preferences.md` with a minimal Node server (it is the server of the browser check)        | specs; the sample server runs and persists | done  |
| 3   | `compact-joined`: rail sidebar, logo only, search in the header, secondary panel for children, breadcrumb switch disabled                                             | specs; e2e; browser, light and dark        | done  |
| 4   | `wide-joined`: the wide sidebar joined to header and content (no floating gaps)                                                                                       | same                                       |       |
| 5   | `floating-compact`: compact rail with floating panels                                                                                                                 | same                                       |       |
| 6   | `transparent-joined`, the `transparentWidth` preference and the "Sidebar transparente" select enabled only for transparent modes                                      | same                                       |       |
| 7   | `transparent-floating`                                                                                                                                                | same                                       |       |
| 8   | CLI: `layouts` checklist in the wizard and `sa add app-shell`, `sa add layout`, `starter-angular.config.json`, registry (`available: true` per built mode), `sa list` | specs of wizard, add, list, resolve; e2e   |       |
| 9   | CHANGELOG, READMEs of the shell and of `core/design-preferences`, `code-review`, integration into `development`                                                       | the gates on the merge                     |       |

## Assumptions to confirm while building

- Below 1024 px every mode keeps today's drawer (wide); compact applies from 1024 px.
- The header toggle hides the sidebar completely in compact modes, as the reference does.
- The secondary navigation panel of a compact item is a flyout anchored to the rail (decided at step 3, with a `Camino`).

## Out of scope

Sharing the colour scheme and the theme through the store, a server-sent events notifier, Spartan UI, and changes to
buttons, avatars, icons or field modes (ADR-0025).
