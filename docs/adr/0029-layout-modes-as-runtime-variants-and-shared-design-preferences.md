# ADR-0029: Layout modes as run-time variants, and design preferences shared by the whole platform

- Status: accepted
- Date: 2026-11-26
- Deciders: project maintainer
- Refines: [ADR-0010](0010-routed-wizard-layout-modes-and-design-preferences.md), decisions 5 and 6 and its follow-up
  about `sa add layout`; [ADR-0009](0009-presence-documentation-and-welcome-home.md) is the model of the contract

## Context

ADR-0010 listed six layout modes and assumed that `sa new` would generate the one the developer picked, one file set per
mode. The maintainer wants something else: an application already in production whose administrator opens the design
preferences page (`/preference-design`, tab Apariencia), picks another layout, presses _Guardar cambios_, and the users
who are working at that moment are told that the design changed, refresh, and see it. No code change and no redeploy;
the developer keeps full freedom to edit the shell. Neither `localStorage` nor `sessionStorage` may carry it (they are
per browser, so no other user would ever see it). The maintainer also does not want real time as the foundation: where
would that be cached, and for how many people. The alert is enough, and the user decides when to refresh.

## Decision

1. **A layout is a variant, not a file set.** The six modes (`wide-joined`, `compact-joined`, `floating-wide`,
   `floating-compact`, `transparent-joined`, `transparent-floating`) are three traits, as in the demo: `compact`,
   `floating`, `transparent`. The shell components (`main`, `sidebar`, `header`, `breadcrumb`) are one set; the mode is a
   preference (`layout`, plus `transparentWidth` for the transparent ones) of `DesignPreferencesService`, a `computed`
   signal of traits, and the components react to it with classes and CSS. Switching is dynamic, with signals.
2. **The catalog and the enabled list live in the project.** `core/design-preferences/layout-modes.ts` holds the
   catalog, `ENABLED_LAYOUT_MODES` (what the preferences page offers) and `DEFAULT_LAYOUT_MODE` (`floating-wide`: what
   is shown when nobody saved anything). Every mode's code is always generated; the list only decides which appear.
3. **"App shell" is everything, a layout is one appearance.** `sa add app-shell` and the wizard ask for the layouts as a
   checklist, `floating-wide` checked, and write the list to `starter-angular.config.json` (`layout` stays the default
   mode, `layouts` is the enabled list). `sa add layout` enables more appearances in a project that has the shell; the
   wizard and `sa list` keep showing the modes that are not built yet as under construction.
4. **No browser storage; a store contract.** `DESIGN_PREFERENCES_STORE` holds a `DesignPreferencesStore`:
   `load()` and `save(preferences)`, both asynchronous, a `version` string that comes back with every document, and
   `canSave` (a signal, so only the administrator saves; the developer connects it to the permissions). The document is
   one for the whole platform. `provideDesignPreferences()` waits for `load()` before the first render
   (`provideAppInitializer` waits for a promise). Without a backend the default store keeps the document in memory:
   changes apply and last until the page is reloaded, and the docs say so. `HttpDesignPreferencesStore` ships (GET and
   PUT, with `ETag`), and `docs/design-preferences.md` documents the endpoint and a minimal Node server, as
   `docs/presence.md` does. The colour scheme and the light/dark mode stay in `ThemeService`, per browser; sharing them
   is a follow-up.
5. **A change notifier, so the others are told.** `DESIGN_CHANGE_NOTIFIER` holds a `DesignChangeNotifier`
   (`connect(listener)`, `disconnect()`), the same shape as `PresenceTransport`. The listener receives the new
   `version`; when it differs from the one the shell applied, `DesignPreferencesService.updateAvailable` turns true and
   the shell shows an alert with a _Recargar_ button. The change is never applied by itself, so nobody loses what they
   are doing, and the administrator's own save is not announced to the administrator. Two notifiers ship: a polling one
   (a conditional GET with the version, every minute and when the tab gets focus again, no sockets) and a WebSocket one
   (the server pushes `{ type: 'design-changed', version }`, reconnection with backoff, and a check of the version after
   a reconnection, because pub/sub does not replay what a client missed). The default is none. The docs show how to feed
   a notifier from Redis pub/sub or any queue.
6. **Compact modes show a search, not a breadcrumb.** As in the reference app, `compact-joined` and `floating-compact`
   put a search in the header, and the user menu (with the presence of `sa add presence`) moves from the sidebar to the
   header, after the colour and theme buttons, as in the reference app; _Mostrar breadcrumb_ of the Otros tab is
   disabled (with a note) in those two modes and keeps its value for the others. A compact sidebar shows the icon above the text; an item with children opens a small
   secondary navigation panel next to it. Below 1024 px every mode uses the same drawer as today.
7. **One mode per commit.** The foundation (decisions 1, 2, 4 and 5, with `floating-wide` only) comes first, then
   `compact-joined`, `wide-joined`, `floating-compact`, `transparent-joined` and `transparent-floating`; each with its
   specs first, its e2e and a look in the browser, light and dark. The CLI checklist and `sa add layout` come after.
8. **Spartan UI is not adopted.** The "shadcn for Angular" is Spartan UI (`@spartan-ng/cli`): it copies a styled layer
   into the project and keeps a headless one in npm. It is a component library and gives no persistence or shared state
   (its dark-mode page leaves storage to the application); what the maintainer wants is the logic above.

## Alternatives considered

- **One file set per mode, chosen by `sa new`** (ADR-0010's assumption): rejected, it cannot change in production.
- **Two sidebars (wide and compact) with common main and header:** rejected, it duplicates the navigation logic and
  re-renders the sidebar on every switch.
- **`localStorage` as a fallback without a backend:** rejected by the maintainer; it hides the fact that others would
  not see the change.
- **Real time as the base (push the new design to everyone):** rejected, it needs the server to know who is connected
  and the client to cache a moving target; an alert and a refresh need one small document.
- **Only the files of the chosen modes:** rejected, it needs conditional wiring of the sidebar and the header on every
  `sa add layout`; keeping every variant and enabling by list is simple and safe.

## Consequences

- Positive: a layout changes in production without a deploy, for everyone, with a warning; a project is yours to edit;
  the transports are the developer's to choose (REST, WebSocket, Redis behind them).
- Negative: more conditional CSS in the shell; the colours and the theme are still per browser; without a backend
  nothing survives a reload (declared, not hidden).
- Follow-up: sharing the colour scheme and theme through the same store, a server-sent events notifier, a Spartan UI
  component collection if the maintainer wants one, and a pending-changes alert for the administrator's other tabs.
