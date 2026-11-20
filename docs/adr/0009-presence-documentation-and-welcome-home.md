# ADR-0009: Presence, the documentation of each piece and the welcome home

- Status: accepted
- Date: 2026-11-20
- Deciders: project maintainer

## Context

ADR-0008 left the business of the reference application out of the App Shell, and presence was the
first thing it removed: the status row of the user menu (online, away, busy, invisible, with a
duration), the presence dot of the avatar and the `PresenceService` behind them depended on the
reference's authentication, its HTTP API and ActionCable. Presence is also the realtime piece that
almost every back-office application ends up needing, and the one a developer cannot reconstruct
from the UI alone: the client logic (idle, hidden tab, timers) and the contract with the server.
Two other gaps showed up while using the shell: the pieces a project brings (theme, icons,
components, animations, styles) are not explained anywhere inside it, and the `home` page is still
the neutral list of folders, while Angular's own new application opens on a welcome page.

## Decision

1. **A new option, `presence`: `none` or `starter`.** It is chosen like the other options: a wizard
   question after the App Shell with its documentation link, `--presence <id>`, `as list presence`,
   `as add presence`. It has no `Recommended` badge and it is not part of `--defaults`: it is a
   realtime layer that a project opts into. `starter` requires `appShell: starter` (the status row
   lives in the shell's user menu), so the registry gets one more requirement key, `appShell`.
2. **Where it lives.** The client logic and the contract are infrastructure: `core/presence`
   (`PresenceService`, `LivePresenceService`, the types, `PresenceTransport` and its two
   transports, `providePresence`). The UI is part of the shell: the global stylesheet
   `styles/features/presence-styles.css` and the edits of decision 5. `core` imports nothing from
   `features` or `shared`.
3. **A transport contract instead of the reference's backend.** `PresenceService` is the reference's
   one without `AuthService`, `HttpClient` and ActionCable: status (`online`, `away`, `busy`,
   `invisible`) with its duration, automatic away after five minutes of inactivity or of a hidden
   tab, the map of the other users and `syncFromServer`. It talks to the server only through
   `PresenceTransport` (`connect(listener)`, `send(change)`, `disconnect()`), provided by the
   `PRESENCE_TRANSPORT` token. Two transports ship: a native WebSocket one with a documented JSON
   protocol (reconnection with backoff) and an in-memory one that behaves like a server (echo,
   snapshot, timers) so the feature works without a backend. `providePresence()` connects the
   in-memory transport; `providePresence({ transport: 'websocket', url })` connects the server.
   The contract and the protocol follow the reference's backend (`PresenceChannel`,
   `PresenceController`, `PresenceDisconnectJob`) without its names: snapshot on subscription, one
   `presence` event per change, a status that outlives a quick reconnection.
4. **Documentation of the server side.** `docs/presence.md` of the generated project explains how to
   connect presence to Redis and to an API: the JSON events, the optional REST endpoint, the Redis
   keys with their TTLs, the snapshot, the grace period of a disconnection and a minimal Node
   server (`ws` and `ioredis`).
5. **Integration with the user menu by planned edits, never by overwriting.** The edits are text and
   syntax-tree edits, planned before anything is written, with explicit anchors: the `as-avatar` tags
   of the menu get `mode="presence"`; the status row goes before the preferences button; the two
   status sub-panels go after `</as-popover>` (they must be outside the popover panel, which is in the
   top layer); the class `UserMenu` gets the members it needs. A file that no longer has the anchors
   (the developer reshaped it) stops the stage naming the file, and nothing is written. The texts
   ported from the reference stay in Spanish, like the rest of the shell.
6. **A README for each piece a project brings**, in English, written only for what is generated:
   `core/theme`, `core/common/icons`, `shared/animations`, `shared/components`, `styles`,
   `core/presence` and the ones the routing and the shell already had. The parts that depend on the
   choices (which components, which stylesheets) are a block between `<!-- as:generated -->` markers
   that every generation or `as add` regenerates; what the developer writes outside the block is never
   touched.
7. **A welcome home when there is an App Shell.** `features/home` becomes a welcome page, like the one
   of a new Angular application: the logo, the project name, cards to explore (the documentation and
   what the project brings), the links to AS Starter and, at the bottom, the social links (GitHub only).
   The cards are data in `home.data.ts`; `as add presence` adds its card there. The page replaces the
   neutral home only when the four files of `home` are still the ones the architecture generated, so a
   developer's `home` (or the `@defer` section of Starter SSR, which edits it) is never overwritten.
   Without the shell the neutral home stays, and with `angular-default` the view is Angular's.

## Alternatives considered

- Port the reference's `RealtimeService` and ActionCable: rejected, it is a vendor protocol and a
  business backend; the transport contract keeps the client independent of the server.
- Only a WebSocket transport: rejected, a project would show a connection error until a server
  exists; the in-memory transport makes the feature visible on day one.
- Presence with `--defaults`: rejected, it adds a realtime layer and its provider to every complete
  build; opting in is one flag or one question.
- Ship the status UI inside the shell blueprint behind a flag: rejected, it would bring files that
  the option `none` must not have, and the shell would depend on presence.
- A single README at the root of the project: rejected, the maintainer wants the explanation next to
  each piece.
- Replace `home` unconditionally: rejected, it would overwrite the developer's page on `as add
app-shell`.

## Consequences

- Positive: the status UI of the reference works without its backend; a developer has the server
  contract written; every piece explains itself where it lives; a new project opens on a page that
  introduces it.
- Negative: more files in a project that opts into presence; the READMEs add files that the developer
  may delete (the block regeneration then recreates nothing: a missing README is left missing); the
  welcome home needs the shell's design.
- Follow-up: a server-sent heartbeat if a deployment needs one; presence rows in the users example
  page; the same welcome page for the other architectures; the web of AS Starter (the links point to
  the GitHub repository until it exists).
