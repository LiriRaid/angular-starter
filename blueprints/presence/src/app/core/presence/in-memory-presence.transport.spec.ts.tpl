import { InMemoryPresenceTransport } from './in-memory-presence.transport';
import type { PresenceEvent } from './presence.types';

describe('InMemoryPresenceTransport', () => {
  let events: PresenceEvent[];
  const listener = (event: PresenceEvent): void => {
    events.push(event);
  };
  const flush = (): Promise<void> => new Promise((resolve) => setTimeout(resolve, 0));

  beforeEach(() => {
    events = [];
  });

  it('welcomes the client and sends the snapshot, like a server on connection', async () => {
    const transport = new InMemoryPresenceTransport({
      userId: 'u1',
      peers: [{ userId: 'u2', status: 'busy' }],
    });
    transport.connect(listener);
    await flush();
    expect(events).toEqual([
      { type: 'welcome', userId: 'u1' },
      {
        type: 'snapshot',
        users: [
          { userId: 'u1', status: 'online' },
          { userId: 'u2', status: 'busy' },
        ],
      },
    ]);
  });

  it('delivers asynchronously, as a socket does', () => {
    const transport = new InMemoryPresenceTransport();
    transport.connect(listener);
    expect(events).toEqual([]);
  });

  it('echoes every change as an update, with the time left of its duration', async () => {
    const transport = new InMemoryPresenceTransport({ userId: 'u1' });
    transport.connect(listener);
    await flush();
    events.length = 0;

    transport.send({ status: 'busy', auto: false, durationMinutes: 15 });
    transport.send({ status: 'away', auto: true });
    await flush();
    expect(events).toEqual([
      { type: 'update', userId: 'u1', status: 'busy', timerRemainingSeconds: 900 },
      { type: 'update', userId: 'u1', status: 'away' },
    ]);
  });

  it('remembers the status while the page lives, so a reconnection restores it', async () => {
    const transport = new InMemoryPresenceTransport({ userId: 'u1' });
    transport.connect(listener);
    transport.send({ status: 'invisible' });
    transport.disconnect();
    events.length = 0;

    transport.connect(listener);
    await flush();
    expect(events[1]).toEqual({
      type: 'snapshot',
      users: [{ userId: 'u1', status: 'invisible' }],
    });
  });

  it('delivers nothing after it disconnects, not even what was on its way', async () => {
    const transport = new InMemoryPresenceTransport();
    transport.connect(listener);
    transport.disconnect();
    await flush();
    transport.send({ status: 'busy' });
    await flush();
    expect(events).toEqual([]);
  });

  it('plays another user for a demo or a spec', async () => {
    const transport = new InMemoryPresenceTransport();
    transport.connect(listener);
    await flush();
    events.length = 0;
    transport.simulatePeer('ana', 'away');
    await flush();
    expect(events).toEqual([{ type: 'update', userId: 'ana', status: 'away' }]);
  });
});
