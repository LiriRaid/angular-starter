# Plan 0012: polishing the UI System and the design preferences page

Decision: [ADR-0014](../adr/0014-ui-system-polish.md). Each step ends with its gate; tests come first.

| #   | Step                                                                                                                                                                                 | Gate                                                     |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------- |
| 1   | Specs first, shown red: the hidden navigation entry, `as-select` in Apariencia, the flags sprite with the input                                                                      | `vitest run` of the engine specs fails for the new ones  |
| 2   | `hidden` in the navigation edit helper, the entry of the page, `as-select` in the appearance tab, the sprite and its notice                                                          | the engine specs green                                   |
| 3   | Specs of the catalog and of `as-modal` first, shown red: the collapse animation, the inputs of every component, the modes, the password eye, the shared tabs, the tooltip, the flush | `ng test` of a generated project fails for the new specs |
| 4   | `as-modal` `flush`, the disabled toggle and the `contrast` toast with theme tokens, the catalog (data, component and template)                                                       | the catalog and component specs green                    |
| 5   | Verification in a generated project (`--ui-system starter`): `ng build`, `ng test`, the catalog and the page in the browser, light and dark                                          | `ng build` and `ng test` green; seen in the browser      |
| 6   | CHANGELOG, `code-review`, commits by topic                                                                                                                                           | `typecheck`, `lint`, `format:check`, `test`, `build`     |

## Out of scope

The wizard, the layout modes that are still under construction, a `fullWidth` input for the tabs, the
modal of the reference application, and any change to the tokens of the UI tab.
