# core/common/icons

The icons the application can draw. The `as-icon` component renders an icon by name, from two
sources: the [Lucide](https://lucide.dev) icons registered here and the SVG files you register.

```
icons/
  lucide-icons.ts            LucideIcons: the Lucide icons the application uses, by name
  lucide-icons.provider.ts   AS_LUCIDE_ICONS: the token that gives them to @lucide/angular
  as-icons.ts                AsIconsSVG: your own SVG files, by name
```

`app.config.ts` and the test setup (`src/test-setup.ts`) provide the registry with
`{ provide: LUCIDE_ICONS, useExisting: AS_LUCIDE_ICONS }`, so the same icons are available in the
application and in the specs.

## Use an icon

```html
<as-icon name="Settings" size="18" />
```

The name is a key of `LucideIcons`, or the `name` of an entry of `AsIconsSVG`.

## Add a Lucide icon

Only the icons registered in `lucide-icons.ts` end up in the bundle (the library is tree-shaken). Import
the icon from `@lucide/angular` and add it to the `AsLucideIcons` object under the name you want to use:

```ts
import { LucideRocket } from '@lucide/angular';

const AsLucideIcons = {
  // ...
  Rocket: LucideRocket,
};
```

## Add your own SVG

Put the file in `public/assets/svg/` and register it in `as-icons.ts`:

```ts
export const AsIconsSVG: AsSvg[] = [
  { name: 'Logo', url: 'assets/svg/logo.svg' },
  { name: 'Brand', url: 'assets/svg/brand.svg', colored: true },
];
```

`colored: true` tints the file with the primary colour; without it the icon follows `currentColor`.
