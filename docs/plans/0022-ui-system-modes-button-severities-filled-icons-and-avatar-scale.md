# Plan 0022: The mode of a field is a setting of its card; the button severities; filled icons; the avatar scale

Decision: [ADR-0025](../adr/0025-ui-system-modes-button-severities-filled-icons-and-avatar-scale.md). Each step ends
with its gate; the specs come first and are shown red.

| #   | Step                                                                                                                                                            | Gate                                                               |
| --- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| 1   | Specs first (red): the rules of the button stylesheet, `filled`/`fillColor`, the scale of the initials, the mode selector and the catalog                       | `vitest run` of `button-severities.spec.ts`; `ng test` of the rest |
| 2   | `sa-icon` (`filled`, `fillColor`) and `sa-avatar` (Tailwind size by avatar size, `cssSize` calc), consumers without a fixed size                                | `ng test` of `sa-icon`, `sa-avatar`                                |
| 3   | The catalog: `modes`, the chips of the mode, the variants of a field once, code as a function, group `Relleno`, avatar sizes                                    | `ng test` of `preference-design`                                   |
| 4   | The button stylesheet: eight severities as custom properties, filled/outlined/text/focus written once; measured in the browser, light and dark, hover and press | `button-severities.spec.ts`; the eyes                              |
| 5   | The real e2e: a project with the shell and the UI System builds without warnings and passes its tests                                                           | `SA_E2E=1` e2e passes                                              |
| 6   | CHANGELOG, ADR-0025 and this plan, `code-review`                                                                                                                | `typecheck`, `lint`, `format:check`, `test`, `build`               |
| 7   | Commit, push of the branch and of `development`                                                                                                                 | the same gates on the merge                                        |

## Out of scope

The colour picker, the popover and `sa-search` (another session), severities for other components, and
retrofitting projects made before.
