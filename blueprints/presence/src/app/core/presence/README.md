# core/presence

Real-time presence: the status of the user (online, away, busy, invisible) and of the others, shown in
the user menu of the sidebar and available to any list. It is the client side only; the server side is
explained in [`docs/presence.md`](../../../../docs/presence.md).

```
presence/
  presence.service.ts                  PresenceService: the state and the rules
  live-presence.service.ts             LivePresenceService: applies the live status to a list
  presence.types.ts                    PresenceStatus, PresenceEvent, PresenceChange
  presence.transport.ts                PresenceTransport (the contract) and PRESENCE_TRANSPORT
  in-memory-presence.transport.ts      a transport that answers like a server, with no network
  web-socket-presence.transport.ts     a native WebSocket speaking the JSON protocol
  presence.protocol.ts                 the JSON messages, parsed and written
  presence.providers.ts                providePresence(): what app.config.ts calls
```

The status row of the user menu is in `features/app-shell/layout/sidebar/user-menu` (`user-status.ts`
and the template), and its styles in `src/styles/features/presence-styles.css`.

## How it works

`PresenceService` talks to the server only through a `PresenceTransport`, so the wire format is
interchangeable:

| Transport                    | When                                                                                          |
| ---------------------------- | --------------------------------------------------------------------------------------------- |
| `InMemoryPresenceTransport`  | the default: works with no backend, to build the UI                                           |
| `WebSocketPresenceTransport` | your server speaks the protocol of the document                                               |
| your own                     | implement `connect`, `send` and `disconnect` (Server-Sent Events, polling, a REST `PATCH`...) |

`app.config.ts` provides it:

```ts
providePresence(); // in memory
providePresence({ transport: 'websocket', url: 'wss://api.example.com/presence' });
```

## The service

| Member                          | What it is                                                              |
| ------------------------------- | ----------------------------------------------------------------------- |
| `status()`                      | signal with the status of this user                                     |
| `durationLabel()`               | signal with how long the manual status lasts (`15m`, `1h`, ...) or null |
| `selfId()`                      | the id the server gave this client                                      |
| `users()`                       | signal with the last status of every user, by id                        |
| `setManualStatus(status, mins)` | the user picks a status, for `mins` minutes or until they change it     |
| `syncFromServer(status, secs)`  | takes the status from the server and never sends it back                |
| `start()`, `stop()`             | connect and disconnect (`providePresence()` starts it with the app)     |

Rules, as in the reference application:

- An online user goes `away` after 5 minutes without activity, or with the tab hidden for 5 minutes.
  The next interaction brings them back. The change is sent with `auto: true`, so the server does not
  keep it as the status the user chose.
- `busy`, `invisible` and a manual `away` are never changed by inactivity.
- A manual status can have a duration; when it ends the user is `online` again.

## Show it in a list

```ts
private readonly live = inject(LivePresenceService);
protected readonly rows = computed(() => this.live.apply(this.users()));
```

```html
<sa-avatar [label]="row.initials" mode="presence" [presenceStatus]="row.presenceStatus" />
```

## Sign in and sign out

If presence must connect only after the user signs in, do not provide it with the application:
provide the transport (`{ provide: PRESENCE_TRANSPORT, useFactory: ... }`) and call
`PresenceService.start()` after the sign-in and `stop()` after the sign-out. The server marks the user
as gone when the connection closes.
