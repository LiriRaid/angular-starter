# core

Application infrastructure used by the whole app: global providers and configuration,
interceptors, route guards, session, theme.

- Nothing here knows about one business feature. Product logic belongs in `features/`.
- `core` imports nothing from `features/` or `shared/`.
- Import it with the `@core/*` alias.
