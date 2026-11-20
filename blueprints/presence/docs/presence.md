# Presence: connect it to your server

The client side of presence is in `src/app/core/presence` (read its README first). It works out of the
box with an in-memory transport that behaves like a server. This document is what you need to build the
real one: the messages the client speaks, the Redis keys that hold the state, the rules a server must
follow and a minimal server in Node.

```
 browser                          your API                       Redis
 ┌─────────────┐   WebSocket    ┌──────────────┐   keys, TTL   ┌───────┐
 │ PresenceService ─ transport ─▶│ presence      │──────────────▶│ state │
 │ (status, idle, │◀─ snapshot ──│ endpoint      │◀──────────────│       │
 │  timers)       │◀─ updates ───│ + broadcast   │   pub/sub     └───────┘
 └─────────────┘                 └──────────────┘
```

## 1. Connect the client

In `app.config.ts`, replace `providePresence()` with:

```ts
providePresence({ transport: 'websocket', url: 'wss://api.example.com/presence' });
```

`url` can be a function, called on every (re)connection, to carry the token of the session:

```ts
providePresence({
  transport: 'websocket',
  url: () => `wss://api.example.com/presence?token=${readSessionToken()}`, // your own function
});
```

(Browsers cannot set headers on a WebSocket, so the token travels in the query string or in the first
message; the server must authenticate the connection before it accepts it.)

## 2. The protocol: JSON over a WebSocket

Every message is a JSON object in a text frame with a `type`. Anything else is ignored by the client, so
the same socket can carry other features.

### Server to client

| `type`              | Fields                                                    | When                                                                          |
| ------------------- | --------------------------------------------------------- | ----------------------------------------------------------------------------- |
| `welcome`           | `userId`                                                  | right after the connection, so the client knows who it is                     |
| `presence:snapshot` | `payload: [{ userId, status }]`, `timerRemainingSeconds?` | once, after `welcome`: the status of every user                               |
| `presence`          | `userId`, `status`, `timerRemainingSeconds?`              | every time any user changes status, and to the user who changed it (the echo) |

```json
{ "type": "welcome", "userId": "42" }
{ "type": "presence:snapshot", "payload": [{ "userId": "42", "status": "online" }, { "userId": "7", "status": "busy" }], "timerRemainingSeconds": 900 }
{ "type": "presence", "userId": "7", "status": "away" }
```

- `status` is one of `online`, `away`, `busy`, `invisible`. `invisible` is how an offline user appears.
- `userId` may be a string or a number; the client reads it as a string.
- `timerRemainingSeconds` is the time left of the duration the user chose for their own status. In the
  snapshot it belongs to the connecting user; in an update, to the user of the update. Leave it out
  when there is no duration.

### Client to server

```json
{ "type": "presence:set", "status": "busy", "durationMinutes": 60 }
{ "type": "presence:set", "status": "away", "auto": true }
```

- `status`: one of the four. Reject anything else.
- `durationMinutes` (optional): the status ends after this time and the user goes back to their
  preferred status. The menu offers 15, 60, 480, 1440 and 4320.
- `auto: true` is the automatic away of inactivity. It must **not** be stored as the status the user
  chose: it neither starts a duration nor replaces the preference.

The server answers a change by broadcasting a `presence` event to everyone, including the sender. The
client uses the echo to follow what other tabs of the same user do; it never sends an echo back.

## 3. Optional: change the status over REST

If your API already has an endpoint for the status, the client can use it for sending while the
WebSocket stays for receiving. The body is the same as the message, without the `type`:

```http
PATCH /api/me/presence
Content-Type: application/json

{ "status": "busy", "durationMinutes": 60, "auto": false }
```

```http
200 OK
{ "status": "busy" }
```

`422` for a status that is not one of the four. The handler does exactly what the server does for a
`presence:set` message (section 5) and then broadcasts. On the client, wrap it in a transport: keep the
WebSocket transport for `connect` and `disconnect`, and replace `send`:

```ts
import { WebSocketPresenceTransport } from '@core/presence/web-socket-presence.transport';
import type { PresenceChange } from '@core/presence/presence.types';

export class RestSendTransport extends WebSocketPresenceTransport {
  override send(change: PresenceChange): void {
    void fetch('/api/me/presence', {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(change),
    });
  }
}
```

and provide it, instead of `providePresence(...)`, with the transport and the start of the service:

```ts
{ provide: PRESENCE_TRANSPORT, useFactory: () => new RestSendTransport({ url }) },
provideAppInitializer(() => { inject(PresenceService).start(); }),
```

## 4. Redis: keys, TTL and expiration

| Key                            | Type   | TTL                     | What it holds                                                                                        |
| ------------------------------ | ------ | ----------------------- | ---------------------------------------------------------------------------------------------------- |
| `presence:status`              | hash   | none                    | `userId` to its last status: what the snapshot reads                                                 |
| `presence:manual:{userId}`     | string | none                    | the status the user chose with no end: what they go back to and what is restored when they reconnect |
| `presence:timer:{userId}`      | string | the duration            | a random nonce. The TTL **is** the time left (`TTL key` gives `timerRemainingSeconds`)               |
| `presence:disconnect:{userId}` | string | grace period + a margin | "this user's last socket closed and has not come back yet"                                           |

Why each one exists:

- **`presence:status`** is the state the snapshot is built from. Keep it in your database if the
  status must survive a Redis flush; Redis is enough for presence.
- **`presence:manual`** separates what the user _chose_ from what the system _derived_. The automatic
  away never writes it, so when the user comes back they return to their choice and not to `away`.
  `invisible` is a choice: a user who chose it is not made `online` when they reconnect.
- **`presence:timer`** makes a duration survive a refresh and a server restart: the TTL keeps counting
  in Redis while no process is watching. The value is a nonce so that a timer that was replaced by a
  newer one does nothing when it fires.
- **`presence:disconnect`** is the grace period (section 6).

### How a duration ends

When the key `presence:timer:{userId}` expires the user must go back to `manual` (or `online`) and the
server must broadcast it. Two ways to notice:

1. **A timer in the process** (the example below): `setTimeout` for the duration; when it fires,
   compare the nonce with the key and, if it is the same, restore the status. Simple; it loses the timers
   of a process that restarts, and the key then expires without anyone noticing.
2. **Redis keyspace notifications**: enable `notify-keyspace-events Ex`, subscribe to
   `__keyevent@0__:expired` and handle the keys that start with `presence:timer:`. It survives restarts
   and works with several server processes (only one should handle each event: use a lock, such as
   `SET presence:lock:{key} 1 NX EX 5`). The expired key no longer has its value: that is why the
   preference lives in `presence:manual`.

### Several server processes

The sockets live in the process that accepted them, so a change handled by one process must reach the
sockets of the others. `PUBLISH presence:events <json>` from the process that handles the change, and
every process subscribes and writes the event to its own sockets. The state in Redis is already shared.

## 5. What the server does

**On connection** (after authenticating the user):

1. Delete `presence:disconnect:{userId}`. If it existed, this is a quick reconnection (a refresh): the
   user never left, so do not restore anything.
2. Send `welcome`.
3. Unless it was a quick reconnection, or a duration is still running (`TTL presence:timer:{userId}`
   greater than 0): read `presence:manual:{userId}` (`online` if empty) and, unless it is `invisible`,
   store it and broadcast `presence`.
4. Send the **snapshot**: `HGETALL presence:status` as `payload`, with `timerRemainingSeconds` equal to the
   `TTL` of the timer key when it is positive.

**On `presence:set`** (or the REST call):

1. Validate `status`.
2. If `auto` is not `true`:
   - with `durationMinutes`: `SETEX presence:timer:{userId} <minutes * 60> <nonce>` and start the timer;
   - without it: `DEL presence:timer:{userId}` and `SET presence:manual:{userId} <status>`.
3. Store the status in `presence:status` and broadcast `presence`, with `timerRemainingSeconds` when
   there is a duration.

**On close** of a socket: if the user has no other socket open (another tab), start the grace period.

## 6. Disconnection and the grace period

A closed socket does not mean the user left: a page refresh, a route change that reloads the app or a
network blip closes it and the client opens another one a moment later. Marking the user `invisible`
at once would make everyone see them flicker offline.

1. When the **last** socket of a user closes, `SETEX presence:disconnect:{userId} <grace + margin> 1`
   and start a timer for the **grace** period (15 seconds is a good default).
2. A new connection of that user deletes the key (see the connection steps above).
3. When the timer fires, if the key still exists the user did not come back: store and broadcast
   `invisible`, and delete the key.

The TTL of the key is only a safety net (if the process dies, the key does not stay for ever). Give it a
margin over the timer: if both end at the same instant the key may be gone when the timer looks for it.

Never trust the client to say it is leaving: the tab closes, the laptop sleeps, the network drops.
The connection closing is the only signal you always get.

## 7. A minimal server in Node

`npm install ws ioredis` (and `typescript`, `@types/ws` and `@types/node` for the types). It keeps
the sockets and the timers in memory, so it runs as a single process; section 4 says what changes with
several. Run it with `PRESENCE_GRACE_SECONDS=15 node server.js` (or with `tsx`).

```ts
import { randomBytes } from 'node:crypto';
import type { IncomingMessage } from 'node:http';
import Redis from 'ioredis';
import { WebSocket, WebSocketServer } from 'ws';

const STATUSES = ['online', 'away', 'busy', 'invisible'] as const;
type Status = (typeof STATUSES)[number];

const GRACE_SECONDS = Number(process.env['PRESENCE_GRACE_SECONDS'] ?? 15);
const redis = new Redis(process.env['REDIS_URL'] ?? 'redis://localhost:6379');

const keys = {
  status: 'presence:status', // hash: userId -> last status, what the snapshot reads
  manual: (id: string) => `presence:manual:${id}`, // the status the user chose with no end
  timer: (id: string) => `presence:timer:${id}`, // nonce of a duration; the TTL is the time left
  disconnect: (id: string) => `presence:disconnect:${id}`, // grace period after the last socket closes
};

const sockets = new Map<string, Set<WebSocket>>(); // userId -> its open sockets in this process
const durationTimers = new Map<string, NodeJS.Timeout>();
const graceTimers = new Map<string, NodeJS.Timeout>();

/** Replace with your authentication: return the id of the user the request belongs to. */
function authenticate(request: IncomingMessage): string | null {
  const token = new URL(request.url ?? '', 'http://localhost').searchParams.get('token');
  return token === null || token === '' ? null : token; // here the token is the user id
}

function broadcast(message: object): void {
  const text = JSON.stringify(message);
  for (const set of sockets.values()) for (const socket of set) socket.send(text);
}

async function setStatus(userId: string, status: Status, remainingSeconds?: number): Promise<void> {
  await redis.hset(keys.status, userId, status);
  broadcast({
    type: 'presence',
    userId,
    status,
    ...(remainingSeconds ? { timerRemainingSeconds: remainingSeconds } : {}),
  });
}

async function sendSnapshot(socket: WebSocket, userId: string): Promise<void> {
  const all = await redis.hgetall(keys.status);
  const remaining = await redis.ttl(keys.timer(userId));
  socket.send(
    JSON.stringify({
      type: 'presence:snapshot',
      payload: Object.entries(all).map(([id, status]) => ({ userId: id, status })),
      ...(remaining > 0 ? { timerRemainingSeconds: remaining } : {}),
    }),
  );
}

async function onConnect(socket: WebSocket, userId: string): Promise<void> {
  // A reconnection inside the grace period is a page refresh, not a user who left.
  clearTimeout(graceTimers.get(userId));
  const wasRefresh = (await redis.del(keys.disconnect(userId))) === 1;

  socket.send(JSON.stringify({ type: 'welcome', userId }));
  if (!wasRefresh && (await redis.ttl(keys.timer(userId))) <= 0) {
    const preference = ((await redis.get(keys.manual(userId))) as Status | null) ?? 'online';
    if (preference !== 'invisible') await setStatus(userId, preference);
  }
  await sendSnapshot(socket, userId);
}

async function onSet(userId: string, message: Record<string, unknown>): Promise<void> {
  const status = message['status'];
  if (!STATUSES.includes(status as Status)) return;
  const minutes = Number(message['durationMinutes']) || 0;

  if (message['auto'] !== true) {
    clearTimeout(durationTimers.get(userId));
    if (minutes > 0) {
      const nonce = randomBytes(8).toString('hex');
      await redis.setex(keys.timer(userId), minutes * 60, nonce);
      durationTimers.set(
        userId,
        setTimeout(async () => {
          if ((await redis.get(keys.timer(userId))) !== nonce) return; // a newer duration replaced it
          await redis.del(keys.timer(userId));
          await setStatus(
            userId,
            ((await redis.get(keys.manual(userId))) as Status | null) ?? 'online',
          );
        }, minutes * 60_000),
      );
    } else {
      await redis.del(keys.timer(userId));
      await redis.set(keys.manual(userId), status as Status);
    }
  }
  await setStatus(userId, status as Status, minutes > 0 ? minutes * 60 : undefined);
}

function onClose(socket: WebSocket, userId: string): void {
  const set = sockets.get(userId);
  set?.delete(socket);
  if (set && set.size > 0) return; // another tab of the user is still connected

  sockets.delete(userId);
  void redis.setex(keys.disconnect(userId), GRACE_SECONDS + 5, '1');
  graceTimers.set(
    userId,
    setTimeout(async () => {
      if ((await redis.exists(keys.disconnect(userId))) === 0) return; // it came back
      await redis.del(keys.disconnect(userId));
      await setStatus(userId, 'invisible');
    }, GRACE_SECONDS * 1000),
  );
}

export function startPresenceServer(port: number): WebSocketServer {
  const server = new WebSocketServer({ port, path: '/presence' });
  server.on('connection', (socket, request) => {
    const userId = authenticate(request);
    if (userId === null) return socket.close(4401, 'unauthorized');

    sockets.set(userId, (sockets.get(userId) ?? new Set()).add(socket));
    socket.on('message', (data) => {
      try {
        const message = JSON.parse(data.toString()) as Record<string, unknown>;
        if (message['type'] === 'presence:set') void onSet(userId, message);
      } catch {
        // not JSON: ignored
      }
    });
    socket.on('close', () => onClose(socket, userId));
    void onConnect(socket, userId);
  });
  return server;
}
```

Start it with `startPresenceServer(3000)` and point the client at `ws://localhost:3000/presence?token=<user id>`.
The `authenticate` function takes the token as the user id: replace it with the verification of your own
session (a JWT, a session cookie) before using it for anything but a demo.

## 8. Check it

1. Open the application in two browsers with different users: each one appears in the other's lists with
   its dot (`mode="presence"` of `as-avatar`) the moment it connects.
2. Choose `Ocupado` for 15 minutes in one: the other sees it at once, and the time left survives a refresh
   (it comes in the snapshot as `timerRemainingSeconds`).
3. Leave a tab without touching it for 5 minutes, or hide it: the user goes `away`; moving the mouse
   brings them back.
4. Close a tab: the user turns `invisible` after the grace period. Refresh it instead: they never do.
