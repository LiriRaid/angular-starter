import { TestBed } from '@angular/core/testing';
import { LivePresenceService } from './live-presence.service';
import { PresenceService } from './presence.service';
import { PRESENCE_TRANSPORT, type PresenceTransport } from './presence.transport';
import type { PresenceEvent } from './presence.types';

interface Row {
  id: string;
  name: string;
  presenceStatus?: string;
}

describe('LivePresenceService', () => {
  let emit: (event: PresenceEvent) => void;
  let presence: PresenceService;
  let live: LivePresenceService;

  beforeEach(() => {
    const transport: PresenceTransport = {
      connect: (listener) => {
        emit = listener;
      },
      send: () => undefined,
      disconnect: () => undefined,
    };
    TestBed.configureTestingModule({ providers: [{ provide: PRESENCE_TRANSPORT, useValue: transport }] });
    presence = TestBed.inject(PresenceService);
    live = TestBed.inject(LivePresenceService);
    presence.start();
    emit({ type: 'welcome', userId: 'me' });
  });

  afterEach(() => presence.stop());

  const rows: Row[] = [
    { id: 'me', name: 'Me', presenceStatus: 'invisible' },
    { id: 'ana', name: 'Ana', presenceStatus: 'invisible' },
    { id: 'luis', name: 'Luis' },
  ];

  it('gives the current user their own status, the moment they change it', () => {
    presence.setManualStatus('busy');
    expect(live.apply(rows)[0]?.presenceStatus).toBe('busy');
  });

  it('gives everyone else the status the server last sent', () => {
    emit({ type: 'update', userId: 'ana', status: 'online' });
    emit({ type: 'update', userId: 'luis', status: 'away' });
    const applied = live.apply(rows);
    expect(applied[1]?.presenceStatus).toBe('online');
    expect(applied[2]?.presenceStatus).toBe('away');
  });

  it('keeps the status an item already had when the server said nothing about it', () => {
    expect(live.apply(rows)[1]?.presenceStatus).toBe('invisible');
    expect(live.apply(rows)[2]?.presenceStatus).toBeUndefined();
  });

  it('does not change the list it receives', () => {
    const before = JSON.stringify(rows);
    live.apply(rows);
    expect(JSON.stringify(rows)).toBe(before);
  });
});
