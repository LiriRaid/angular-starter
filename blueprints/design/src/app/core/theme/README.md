# core/theme

Light and dark mode, the primary (accent) color and the surface (neutral) color of the application.

- `theme.service.ts` — `ThemeService`: `mode`, `toggleMode()`, `setMode()`, `setPrimaryColor()` and
  `setSurfaceColor()`. It toggles the `dark` class on `<html>`, writes the `--as-primary-*` and
  `--as-surface-*` ramps and remembers the choice in the browser.
- `theme-palettes.ts` — the color ramps you can choose from; add your own here.
- `theme-storage.ts` — where the preference is saved.
- `theme.initializer.ts` — `provideThemeInitializer()`, registered in `app.config.ts`.

The tokens themselves live in `src/styles/tokens.css`; this folder only changes them at run time.
