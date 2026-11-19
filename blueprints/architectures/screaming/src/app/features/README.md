# features

One folder per business capability. The folder names should tell what the product does.

A feature keeps everything that belongs to it:

```
features/<feature>/
  <feature>.ts / .html / .css      main component
  <feature>.routes.ts              exports <FEATURE>_ROUTES, loaded lazily from app.routes.ts
  models/ services/ utils/         as the feature needs them
  validators/ modals/ drawers/
```

- A feature imports from `core/` and `shared/`, never from another feature. Anything two features
  need moves to `shared/`.
- The application shell (layout, sidebar, header) lives in `features/app-shell` when it is added.
- Import with the `@features/*` alias.
