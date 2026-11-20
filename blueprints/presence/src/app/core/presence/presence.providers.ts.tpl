import {
  EnvironmentProviders,
  inject,
  makeEnvironmentProviders,
  provideAppInitializer,
} from '@angular/core';
import { InMemoryPresenceTransport, type InMemoryPresenceOptions } from './in-memory-presence.transport';
import { PresenceService } from './presence.service';
import { PRESENCE_TRANSPORT, type PresenceTransport } from './presence.transport';
import { WebSocketPresenceTransport, type WebSocketPresenceOptions } from './web-socket-presence.transport';

/** Which transport presence uses: the in-memory mock (the default) or a WebSocket server. */
export type PresenceConfig =
  | ({ readonly transport?: 'memory' } & InMemoryPresenceOptions)
  | ({ readonly transport: 'websocket' } & WebSocketPresenceOptions);

function createTransport(config: PresenceConfig): PresenceTransport {
  if (config.transport === 'websocket') {
    const { transport: _transport, ...options } = config;
    return new WebSocketPresenceTransport(options);
  }
  const { transport: _transport, ...options } = config;
  return new InMemoryPresenceTransport(options);
}

/**
 * Provides presence and starts it with the application:
 *
 *   providePresence()                                                    // in memory, no backend
 *   providePresence({ transport: 'websocket', url: 'wss://api.example.com/presence' })
 *
 * An application that connects only after a sign-in provides `PRESENCE_TRANSPORT` itself and calls
 * `PresenceService.start()` after the sign-in and `stop()` after the sign-out.
 */
export function providePresence(config: PresenceConfig = {}): EnvironmentProviders {
  return makeEnvironmentProviders([
    { provide: PRESENCE_TRANSPORT, useFactory: () => createTransport(config) },
    provideAppInitializer(() => {
      inject(PresenceService).start();
    }),
  ]);
}
