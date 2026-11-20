# core/design-preferences

The design preferences of the application, changed in real time from the page
`features/preference-design` (the "Preferencias de Diseño" button of the user menu) and applied before
the first render by `provideDesignPreferences()` in `app.config.ts`.

| Preference       | What it changes                                            | How                                   |
| ---------------- | ---------------------------------------------------------- | ------------------------------------- |
| `radius`         | every `rounded-*`, buttons, selects, popovers and tooltips | `--as-ui-radius-scale` × `--radius-*` |
| `buttonSize`     | the height of the `as-button` sizes                        | `--as-ui-button-scale`                |
| `density`        | every spacing utility (padding, gaps, sizes)               | `--as-ui-density-scale` × `--spacing` |
| `fontSize`       | everything sized in `rem`                                  | `--as-ui-font-scale` on `html`        |
| `showBreadcrumb` | the breadcrumb of the header                               | read by the header                    |
| `animations`     | transitions and animations                                 | `data-animations` attribute on `html` |

The variables are consumed by `src/styles/features/design-preferences-styles.css`. A change is applied
at once and kept in memory; "Guardar cambios" stores it in `localStorage` and "Restablecer" brings back
the defaults and deletes what was stored. The theme (light or dark) and the colours are stored by
`ThemeService` (`core/theme`) as soon as they change.

To add a preference: add it to `DesignPreferences` and its defaults, apply it in `apply()`, and give it
a control in the page.
