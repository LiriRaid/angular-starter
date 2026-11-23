# Plan 0013: final fixes of the UI System and the documentation of AS Starter

Decision: [ADR-0015](../adr/0015-ui-system-final-fixes-and-starter-docs.md). Each step ends with its gate; tests come first.

| #   | Step                                                                                                                                                   | Gate                                                 |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------- |
| 1   | Omni first: specs shown red, then the textarea padding and icons, the tag input label and height, the label radius, the `over` label with an icon      | `vitest run` of input, textarea and select in Omni   |
| 2   | Omni: the tooltip anchor (`anchorRectOf`) and `draggable` of the modal, each with its spec shown red, one commit per component (no push)               | `vitest run` of tooltip and modal in Omni            |
| 3   | The same changes in the `as-*` blueprints (input, textarea, tooltip, modal) with their specs                                                           | `ng test` of a generated project                     |
| 4   | Catalog specs shown red: dark chips, independent tabs, readonly select with a value, `draggable` switch; then the catalog                              | `ng test` fails for the new specs, then passes       |
| 5   | Engine specs shown red: the cards without angular.dev, `features/docs`, its route and navigation item, the guards; then `features/docs` and the wiring | `vitest run` of `app-shell.spec.ts`                  |
| 6   | Verification in a generated project (`--ui-system starter`): `ng build`, `ng test`, the catalog, the docs and the home measured in the browser         | `ng build` and `ng test` green; seen in the browser  |
| 7   | CHANGELOG, `code-review`, commits by topic, push of the branch and merge into `development`                                                            | `typecheck`, `lint`, `format:check`, `test`, `build` |

## Out of scope

The wizard, the layout modes under construction, the `resizable` option of the modal, a search over the
documentation, documentation pages for presence and routing, and any change to the tokens of the UI tab.
