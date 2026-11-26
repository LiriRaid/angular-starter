# Design preferences: change the design of the platform from production

The administrator opens **Preferencias de Diseño** (`/preference-design`), picks another layout, presses _Guardar
cambios_ and, a moment later, everybody who uses the platform is told that the design changed and reloads the page to
see it. No code change and no deploy. This document is what you need to connect that to your server. The client side
is in `src/app/core/design-preferences` (read its README first).

```
 administrator            your API                      everybody else
 ┌───────────────┐  PUT   ┌───────────────┐  notice    ┌─────────────────┐
 │ preferences   │───────▶│ one document  │───────────▶│ "El diseño de la │
 │ page          │        │ { version,    │ (poll or   │ plataforma       │
 └───────────────┘        │  preferences }│  WebSocket)│ cambió" [Recargar]│
                          └───────┬───────┘            └─────────────────┘
                                  │ GET when the app starts
```

Nothing is kept in the browser (`localStorage` and `sessionStorage` are per browser: nobody else would see it) and
nothing is applied by itself: the notice offers to reload, so a user is never interrupted in the middle of a task.
There is one small document for the whole platform, so there is nothing to cache per user and nobody to push a heavy
payload to: the notice carries only the new `version`.

Out of the box the document lives in memory (`MemoryDesignPreferencesStore`): the changes apply, but they last until the
page is reloaded and nobody else sees them. Connect your server with the two pieces below.

## 1. The document: `DESIGN_PREFERENCES_STORE`

In `app.config.ts`:

```ts
provideDesignPreferences({
  store: () =>
    new HttpDesignPreferencesStore({
      url: '/api/design-preferences',
      headers: () => ({ authorization: `Bearer ${readSessionToken()}` }), // your own function
      canSave: inject(Session).isAdmin, // a Signal<boolean>: only the administrator sees "Guardar cambios" enabled
    }),
});
```

`HttpDesignPreferencesStore` speaks this to your API (it uses `fetch` and sends the cookies; for `HttpClient` and its
interceptors, write a class that implements `DesignPreferencesStore` and injects it):

| Request                               | Answer                                                                                                                                              |
| ------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `GET /api/design-preferences`         | `200 { "version": "…", "preferences": { … } }`, or `404` while nobody has saved one                                                                 |
| `PUT /api/design-preferences`         | body `{ "preferences": { … } }`; `200 { "version": "…", "preferences": { … } }` with the **new** version, `403` if the user is not an administrator |
| `GET /api/design-preferences/version` | `200 { "version": "…" }` (only for the polling notifier and for catching up after a reconnection)                                                   |

- `version` is any string that changes with every save: a counter, a timestamp, a revision of the row.
- The application waits at most five seconds for `GET`; if it does not answer, it starts with the default design.
- The client keeps only the values it understands, so an old or edited document never breaks the page.
- `canSave` is a convenience of the screen. **The server has to refuse the `PUT` of whoever may not save.**

## 2. The notice: `DESIGN_CHANGE_NOTIFIER`

A notifier only reports the version of the design that was saved. Pick one, or write yours (the interface has two
methods, `connect(listener)` and `disconnect()`).

**Polling, no sockets.** It asks `GET /api/design-preferences/version` every minute, and when a tab that was in the
background comes back (never while it is hidden):

```ts
provideDesignPreferences({
  store: () => new HttpDesignPreferencesStore({ url: '/api/design-preferences' }),
  notifier: () => new PollingDesignChangeNotifier({ url: '/api/design-preferences/version' }),
});
```

**Real time, WebSocket.** The server sends `{ "type": "design-changed", "version": "…" }` to every connection when
somebody saves. The notifier reconnects with backoff and, because a channel does not replay what a disconnected client
missed, asks for the version once after every reconnection:

```ts
provideDesignPreferences({
  store: () => new HttpDesignPreferencesStore({ url: '/api/design-preferences' }),
  notifier: () =>
    new WebSocketDesignChangeNotifier({
      url: () => `wss://api.example.com/design?token=${readSessionToken()}`, // a function: a fresh token on every connection
      versionUrl: '/api/design-preferences/version',
    }),
});
```

Browsers cannot set headers on a WebSocket, so the token travels in the query string or in the first message; the
server must authenticate the connection before it accepts it.

The user who saved is not told about their own change.

## 3. A minimal server

Node 22, no dependencies; it keeps the document in a file and answers the three requests (`design-server.mjs`). The
administrator is whoever sends `x-role: admin`: replace `isAdministrator` with your authentication.

```js
import { createServer } from 'node:http';
import { existsSync, readFileSync, writeFileSync } from 'node:fs';

const FILE = 'design-preferences.json';
let document = existsSync(FILE) ? JSON.parse(readFileSync(FILE, 'utf8')) : null;

const isAdministrator = (request) => request.headers['x-role'] === 'admin'; // your authentication goes here
const send = (response, status, body) => {
  response.writeHead(status, { 'content-type': 'application/json', 'cache-control': 'no-cache' });
  response.end(body === undefined ? undefined : JSON.stringify(body));
};

createServer(async (request, response) => {
  const { pathname } = new URL(request.url, 'http://localhost');
  if (pathname === '/api/design-preferences/version' && request.method === 'GET') {
    return document ? send(response, 200, { version: document.version }) : send(response, 404);
  }
  if (pathname !== '/api/design-preferences') return send(response, 404);
  if (request.method === 'GET')
    return document ? send(response, 200, document) : send(response, 404);
  if (request.method === 'PUT') {
    if (!isAdministrator(request)) return send(response, 403);
    let text = '';
    for await (const chunk of request) text += chunk;
    let preferences;
    try {
      ({ preferences } = JSON.parse(text));
    } catch {
      return send(response, 400);
    }
    document = { version: String(Date.now()), preferences };
    writeFileSync(FILE, JSON.stringify(document));
    return send(response, 200, document);
  }
  send(response, 405);
}).listen(3000);
```

Run it with `node design-server.mjs`, and let `ng serve` reach it without CORS with a `proxy.conf.json`
(`{ "/api": { "target": "http://localhost:3000" } }`) and `ng serve --proxy-config proxy.conf.json`. Send the header of
the administrator from the application (`headers: () => ({ 'x-role': 'admin' })`) to be allowed to save.

### Several servers, a cache and real time with Redis

With more than one instance of your API, keep the document where all of them see it (a database row, or a Redis key
in front of it: `GET design:preferences`) and use Redis pub/sub to tell every instance that it changed, so each one
can push the notice to its own WebSocket connections:

```js
// on every save, after writing the document
await redis.set('design:preferences', JSON.stringify(document));
await redis.publish('design-changed', document.version);

// on every instance
const subscriber = redis.duplicate();
await subscriber.subscribe('design-changed');
subscriber.on('message', (_channel, version) => {
  for (const socket of sockets) socket.send(JSON.stringify({ type: 'design-changed', version }));
});
```

Pub/sub keeps no history: an instance or a client that was away misses the message, which is why the client asks for the
version after reconnecting. The document stays small and identical for everybody, so it can sit behind any cache; keep
`Cache-Control: no-cache` (revalidate) on the three requests so that a reload always brings the current version.
