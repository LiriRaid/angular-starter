# styles

The global stylesheets of the application, as the reference application lays them out. Everything is
imported from `src/styles.css`, which is the only place to look to know what the application loads, and
every file is named `*-styles.css`.

`styles.css` starts with Tailwind CSS, the `dark` variant (it follows the `dark` class that
`ThemeService` puts on `<html>`) and the cascade layers:

```css
@layer base, components, legacy-overrides, utilities;
```

Component stylesheets that need to beat a utility class sit in `legacy-overrides`, which comes before
`utilities`; keep that order when you add layers.

- `theme/theme-styles.css`: the design tokens. The `--as-*` colours that `ThemeService` sets, and the
  `--app-*` tokens the application reads (panels, text, borders, sidebar, status colours). Light values
  are in `:root` and dark ones in `.dark`. Change a colour here, never in a component.
- `typography/`: the type scale (`text-body-1-bold`, `text-caption-2-regular`, ...) as Tailwind
  utilities, and the colour helpers.
- `base-elements-styles.css`: the font (Inter, loaded from `index.html`), number inputs, buttons and the
  switch between themes.
- `mixins-styles.css`: reusable selectors such as the hover highlight of the sidebar items.
- `scrollbar-styles.css`: the scrollbar.

The animations are not here: they live in `src/app/shared/animations`.

## What this project has

The list below is rewritten every time something that adds stylesheets runs (`as add components`,
`as add app-shell`, `as add presence`); write your own notes outside of it.

<!-- as:generated -->
<!-- /as:generated -->
