import { InjectionToken } from '@angular/core';
import { InMemoryPresenceTransport } from './in-memory-presence.transport';
import type { PresenceChange, PresenceEvent } from './presence.types';

/**
 * How presence talks to a server. `PresenceService` only knows this contract, so the wire format
 * (WebSocket, Server-Sent Events, polling, a mock) is a transport and nothing else changes.
 */
export interface PresenceTransport {
  /** Opens the connection and delivers every event to `listener` until `disconnect()`. */
  connect(listener: (event: PresenceEvent) => void): void;
  /** Tells the server the status of this client. It is dropped when there is no connection. */
  send(change: PresenceChange): void;
  /** Closes the connection; nothing is delivered afterwards. */
  disconnect(): void;
}

/**
 * The transport in use. Without `providePresence(...)` it is the in-memory one, which behaves like a
 * server and needs no backend, so the status menu works from the first run.
 */
export const PRESENCE_TRANSPORT = new InjectionToken<PresenceTransport>('PRESENCE_TRANSPORT', {
  providedIn: 'root',
  factory: () => new InMemoryPresenceTransport(),
});
