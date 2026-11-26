# Plan 0023: Floating panels are centred and follow their anchor; the collapsed search opens

Decision: [ADR-0026](../adr/0026-floating-panels-follow-their-anchor-and-collapsed-search-opens.md). Each step ends
with its gate; the specs come first and are shown red.

| #   | Step                                                                                                                                                                                                                    | Gate                                                |
| --- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------- |
| 1   | Specs first (red): `isAnchorOutOfView`, the reposition listeners, the layouts with `bounds`, the colour picker and popover centred, the follow-and-close of select and datepicker, the search focus, the catalog wiring | `ng test` of the touched specs fails to compile/run |
| 2   | `panel-placement.ts` and `native-overlay-dismiss.ts`: `isAnchorOutOfView` and the reposition listeners                                                                                                                  | `ng test` of `shared/utils`                         |
| 3   | `sa-popover` and `sa-theme-color-picker`: no hand-made offsets, the same layout functions, closing when the anchor leaves                                                                                               | `ng test` of both                                   |
| 4   | `sa-select` and `sa-datepicker`: layouts with `bounds`, follow the scroll, close when the anchor leaves                                                                                                                 | `ng test` of both                                   |
| 5   | `sa-search` focuses its field after the click; the catalog opens, closes and clears the collapsed variant                                                                                                               | `ng test` of `sa-search` and `preference-design`    |
| 6   | The eyes: centring measured for every picker and popover of the catalog, the follow and the close on scroll, the collapsed search by a real click, light and dark                                                       | the generated project, in the browser               |
| 7   | The real e2e: a project with the shell and the UI System builds and passes its tests                                                                                                                                    | `SA_E2E=1` e2e passes                               |
| 8   | CHANGELOG, ADR-0026 and this plan, `code-review`                                                                                                                                                                        | `typecheck`, `format:check`, `test`, `build`        |
| 9   | Commit, push of the branch and of `development`                                                                                                                                                                         | the same gates on the merge                         |

## Out of scope

The buttons, avatars, icons and the modes of the fields (ADR-0025), the mention panel of the reference composer (the
starter has no composer), the country panel of `sa-input`, and retrofitting projects made before.
