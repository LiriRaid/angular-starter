# core/design-preferences

The design of the platform: one document for every user, changed in real time from the page
`features/preference-design` (the "Preferencias de Diseño" button of the user menu) and loaded before the first
render by `provideDesignPreferences()` in `app.config.ts`.

| Preference       | What it changes                                            | How                                                              |
| ---------------- | ---------------------------------------------------------- | ---------------------------------------------------------------- |
| `layout`         | the look of the shell: sidebar, header and content         | `data-layout` and `data-layout-traits` on `html`, and the traits |
| `radius`         | every `rounded-*`, buttons, selects, popovers and tooltips | `--sa-ui-radius-scale` × `--radius-*`                            |
| `buttonSize`     | the height of the `sa-button` sizes                        | `--sa-ui-button-scale`                                           |
| `density`        | every spacing utility (padding, gaps, sizes)               | `--sa-ui-density-scale` × `--spacing`                            |
| `fontSize`       | everything sized in `rem`                                  | `--sa-ui-font-scale` on `html`                                   |
| `showBreadcrumb` | the breadcrumb of the header                               | read by the header                                               |
| `animations`     | transitions and animations                                 | `data-animations` attribute on `html`                            |

The variables are consumed by `src/styles/features/design-preferences-styles.css`.

## The layout is a variant, not a file set

`layout-modes.ts` lists the modes of the shell. Each one is a mix of three traits (`compact`, `floating`,
`transparent`): there is one set of components and the mode only changes what they draw. Switching is dynamic: the
service keeps `layoutTraits`, a `computed` signal that the components read, and puts the same traits on `html`
(`html[data-layout-traits~='floating']`) for the stylesheets. `ENABLED_LAYOUT_MODES` is the list the page offers and
`DEFAULT_LAYOUT_MODE` is what everybody sees until someone saves another one. All the code of every mode is generated;
edit the list to offer more or fewer.

## Where the design lives

It never lives in the browser (`localStorage` and `sessionStorage` are per browser: nobody else would see it). Two
contracts, both provided by tokens like `PRESENCE_TRANSPORT`:

- `DESIGN_PREFERENCES_STORE` (`DesignPreferencesStore`): `load()`, `save(preferences)` and `canSave`, the signal that
  says who may press "Guardar cambios". The document has a `version` that every save changes. The default keeps it in
  memory, so a save lasts until the page is reloaded: connect your backend to keep it.
- `DESIGN_CHANGE_NOTIFIER` (`DesignChangeNotifier`): `connect(listener)` and `disconnect()`. It reports the `version`
  of the design the administrator saved; when it differs from the one this tab applied, the shell shows
  `design-update-notice` ("El diseño de la plataforma cambió", with a _Recargar_ button). Nothing is applied by itself.
  The default tells nobody: users see the new design the next time they load the page.

Shipped implementations, all over native `fetch` and `WebSocket`: `HttpDesignPreferencesStore` (`GET` and `PUT` of
one document), `PollingDesignChangeNotifier` (asks the version every minute and when the tab comes back, no sockets)
and `WebSocketDesignChangeNotifier` (the server pushes `design-changed`, with reconnection and a version check after
it). `docs/design-preferences.md` has the contract of the endpoint, a minimal Node server and how to feed the notices
from Redis pub/sub.

```ts
provideDesignPreferences({
  store: () =>
    new HttpDesignPreferencesStore({
      url: '/api/design-preferences',
      canSave: inject(Session).isAdmin,
    }),
  notifier: () => new PollingDesignChangeNotifier({ url: '/api/design-preferences/version' }),
});
```

Or your own: `store: () => inject(MyDesignStore)` with any class that implements the interfaces.

"Restablecer" brings back the defaults, also the theme and the colours, and saves them when the store allows it.
The theme (light or dark) and the colours are stored by `ThemeService` (`core/theme`) in the browser as soon as they
change; they are not part of the document of the platform.

To add a preference: add it to `DesignPreferences` and its defaults, validate it in `sanitize()`, apply it in
`apply()`, and give it a control in the page.
