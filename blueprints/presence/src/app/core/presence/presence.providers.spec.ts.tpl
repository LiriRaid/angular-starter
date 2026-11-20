import { ApplicationInitStatus } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { InMemoryPresenceTransport } from './in-memory-presence.transport';
import { PresenceService } from './presence.service';
import { PRESENCE_TRANSPORT } from './presence.transport';
import { providePresence } from './presence.providers';
import { WebSocketPresenceTransport } from './web-socket-presence.transport';

describe('providePresence', () => {
  afterEach(() => TestBed.inject(PresenceService).stop());

  it('uses the in-memory transport by default and starts presence with the application', async () => {
    TestBed.configureTestingModule({ providers: [providePresence()] });
    await TestBed.inject(ApplicationInitStatus).donePromise;
    expect(TestBed.inject(PRESENCE_TRANSPORT)).toBeInstanceOf(InMemoryPresenceTransport);

    await new Promise((resolve) => setTimeout(resolve, 0));
    expect(TestBed.inject(PresenceService).selfId()).toBe('me');
  });

  it('gives the in-memory transport the id and the peers it was asked for', async () => {
    TestBed.configureTestingModule({
      providers: [providePresence({ userId: 'u9', peers: [{ userId: 'u1', status: 'busy' }] })],
    });
    await TestBed.inject(ApplicationInitStatus).donePromise;
    await new Promise((resolve) => setTimeout(resolve, 0));
    const presence = TestBed.inject(PresenceService);
    expect(presence.selfId()).toBe('u9');
    expect(presence.users().get('u1')).toBe('busy');
  });

  it('uses the WebSocket transport when asked, with its options', async () => {
    const sockets: string[] = [];
    TestBed.configureTestingModule({
      providers: [
        providePresence({
          transport: 'websocket',
          url: 'ws://localhost:3000/presence',
          reconnect: false,
          socketFactory: (url) => {
            sockets.push(url);
            return { close: () => undefined } as unknown as WebSocket;
          },
        }),
      ],
    });
    await TestBed.inject(ApplicationInitStatus).donePromise;
    expect(TestBed.inject(PRESENCE_TRANSPORT)).toBeInstanceOf(WebSocketPresenceTransport);
    await new Promise((resolve) => setTimeout(resolve, 0));
    expect(sockets).toEqual(['ws://localhost:3000/presence']);
  });
});
