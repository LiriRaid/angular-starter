# core/theme

Light and dark mode, the primary colour and the surface colour of the application. The design tokens
(`--sa-primary-*`, `--sa-surface-*`) are CSS variables that this folder sets on `<html>`, and the
stylesheets of `src/styles` read them, so changing the theme never needs a rebuild.

```
theme/
  theme.service.ts                ThemeService: mode, primary colour and surface colour
  theme-palettes.ts               PRIMARY_COLORS and SURFACE_COLORS, each a 50-950 ramp
  theme-preferences.storage.ts    what the user chose, kept in localStorage
  theme.initializer.ts            provideThemeInitializer(): applies the saved theme at startup
  theme.service.spec.ts
```

## ThemeService

| Member                       | What it does                                                          |
| ---------------------------- | --------------------------------------------------------------------- |
| `mode()`                     | signal with `'light'` or `'dark'`                                     |
| `toggleMode()`, `setMode(m)` | switch the mode; the `dark` class of `<html>` is what the CSS reads   |
| `primaryColorKey()`          | signal with the key of the chosen primary palette                     |
| `applyColor(key)`            | sets `--sa-primary-50` ... `--sa-primary-950` and the semantic tokens |
| `surfaceColorKey()`          | signal with the key of the chosen surface palette                     |
| `applySurface(key)`          | sets `--sa-surface-50` ... `--sa-surface-950`                         |

`provideThemeInitializer()` is in `app.config.ts`. On startup it restores what the user saved; with
nothing saved it follows `prefers-color-scheme`. The choices are stored under the keys
`<project name>:theme-mode`, `<project name>:primary-color` and `<project name>:surface-color`.

## Add a colour

Add an entry to `PRIMARY_COLORS` or `SURFACE_COLORS` in `theme-palettes.ts` with the 11 shades of the
ramp. The colour picker of the header lists whatever those arrays hold. The default colours are
`DEFAULT_PRIMARY_COLOR_KEY` and `DEFAULT_SURFACE_COLOR_KEY`.

## Rules

- `core` imports nothing from `features/` or `shared/`; the theme is infrastructure.
- The service only touches the document it is given (`DOCUMENT`) and never reads `dataset`, so it keeps
  working when a page is rendered on the server.
