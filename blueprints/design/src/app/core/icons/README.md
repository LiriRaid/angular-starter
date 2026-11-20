# core/icons

The icons the application can show with `<as-icon name="..." />`, from [Lucide](https://lucide.dev).

- `icons.ts` — the list of bundled icons. Add a `Lucide...` import and an entry to use another one.
- `icons.provider.ts` — `provideAsIcons()`, registered in `app.config.ts`. Pass extra icons to add
  your own without editing the list.

Only the icons listed are included in the build.
