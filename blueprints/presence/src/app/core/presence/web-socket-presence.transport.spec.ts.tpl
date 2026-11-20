import type { PresenceEvent } from './presence.types';
import { WebSocketPresenceTransport } from './web-socket-presence.transport';

/** The part of a socket the transport uses, driven by the spec as the server would. */
class FakeSocket {
  static instances: FakeSocket[] = [];
  readyState = 0;
  sent: string[] = [];
  closed = false;
  onopen: (() => void) | null = null;
  onmessage: ((message: { data: unknown }) => void) | null = null;
  onclose: (() => void) | null = null;

  constructor(
    readonly url: string,
    readonly protocols?: string | string[],
  ) {
    FakeSocket.instances.push(this);
  }

  send(data: string): void {
    this.sent.push(data);
  }
  close(): void {
    this.closed = true;
    this.readyState = 3;
    this.onclose?.();
  }
  open(): void {
    this.readyState = 1;
    this.onopen?.();
  }
  receive(data: unknown): void {
    this.onmessage?.({ data });
  }
  drop(): void {
    this.readyState = 3;
    this.onclose?.();
  }
}

const factory = (url: string, protocols?: string | string[]): WebSocket =>
  new FakeSocket(url, protocols) as unknown as WebSocket;

describe('WebSocketPresenceTransport', () => {
  let events: PresenceEvent[];
  const listener = (event: PresenceEvent): void => {
    events.push(event);
  };

  beforeEach(() => {
    vi.useFakeTimers();
    FakeSocket.instances = [];
    events = [];
  });

  afterEach(() => vi.useRealTimers());

  const last = (): FakeSocket => FakeSocket.instances.at(-1) as FakeSocket;

  it('opens the socket at the url and delivers what the server sends', async () => {
    const transport = new WebSocketPresenceTransport({ url: 'ws://host/presence', socketFactory: factory });
    transport.connect(listener);
    await vi.advanceTimersByTimeAsync(0);
    expect(last().url).toBe('ws://host/presence');

    last().open();
    last().receive(JSON.stringify({ type: 'welcome', userId: 7 }));
    last().receive(JSON.stringify({ type: 'presence', userId: 7, status: 'busy', timerRemainingSeconds: 60 }));
    expect(events).toEqual([
      { type: 'welcome', userId: '7' },
      { type: 'update', userId: '7', status: 'busy', timerRemainingSeconds: 60 },
    ]);
  });

  it('ignores what is not a presence message', async () => {
    const transport = new WebSocketPresenceTransport({ url: 'ws://host', socketFactory: factory });
    transport.connect(listener);
    await vi.advanceTimersByTimeAsync(0);
    last().receive('not json');
    last().receive(JSON.stringify({ type: 'conversation:new' }));
    expect(events).toEqual([]);
  });

  it('sends the status as a JSON message once the socket is open', async () => {
    const transport = new WebSocketPresenceTransport({ url: 'ws://host', socketFactory: factory });
    transport.connect(listener);
    await vi.advanceTimersByTimeAsync(0);

    last().open();
    transport.send({ status: 'busy', durationMinutes: 15 });
    expect(last().sent.map((text) => JSON.parse(text))).toEqual([
      { type: 'presence:set', status: 'busy', durationMinutes: 15 },
    ]);

    expect(last().sent).toHaveLength(1);
  });

  it('asks for the url on every connection, so it can carry a fresh token', async () => {
    let calls = 0;
    const transport = new WebSocketPresenceTransport({
      url: () => `ws://host/presence?token=${++calls}`,
      socketFactory: factory,
    });
    transport.connect(listener);
    await vi.advanceTimersByTimeAsync(0);
    last().drop();
    await vi.advanceTimersByTimeAsync(1_000);
    expect(FakeSocket.instances.map((socket) => socket.url)).toEqual([
      'ws://host/presence?token=1',
      'ws://host/presence?token=2',
    ]);
  });

  it('reconnects with a growing delay and starts over once it is connected', async () => {
    const transport = new WebSocketPresenceTransport({
      url: 'ws://host',
      reconnect: { minDelayMs: 1_000, maxDelayMs: 4_000 },
      socketFactory: factory,
    });
    transport.connect(listener);
    await vi.advanceTimersByTimeAsync(0);

    last().drop();
    await vi.advanceTimersByTimeAsync(999);
    expect(FakeSocket.instances).toHaveLength(1);
    await vi.advanceTimersByTimeAsync(1);
    expect(FakeSocket.instances).toHaveLength(2);

    last().drop();
    await vi.advanceTimersByTimeAsync(1_999);
    expect(FakeSocket.instances).toHaveLength(2);
    await vi.advanceTimersByTimeAsync(1);
    expect(FakeSocket.instances).toHaveLength(3);

    last().open();
    last().drop();
    await vi.advanceTimersByTimeAsync(1_000);
    expect(FakeSocket.instances).toHaveLength(4);
  });

  it('does not reconnect when it was turned off', async () => {
    const transport = new WebSocketPresenceTransport({
      url: 'ws://host',
      reconnect: false,
      socketFactory: factory,
    });
    transport.connect(listener);
    await vi.advanceTimersByTimeAsync(0);
    last().drop();
    await vi.advanceTimersByTimeAsync(60_000);
    expect(FakeSocket.instances).toHaveLength(1);
  });

  it('closes the socket on disconnect and never reconnects or delivers again', async () => {
    const transport = new WebSocketPresenceTransport({ url: 'ws://host', socketFactory: factory });
    transport.connect(listener);
    await vi.advanceTimersByTimeAsync(0);
    const socket = last();
    socket.open();

    transport.disconnect();
    expect(socket.closed).toBe(true);
    socket.receive(JSON.stringify({ type: 'welcome', userId: 'x' }));
    await vi.advanceTimersByTimeAsync(60_000);
    expect(FakeSocket.instances).toHaveLength(1);
    expect(events).toEqual([]);
  });

  it('sends the last choice made while the socket was down once it opens', async () => {
    const transport = new WebSocketPresenceTransport({ url: 'ws://host', socketFactory: factory });
    transport.connect(listener);
    await vi.advanceTimersByTimeAsync(0);
    transport.send({ status: 'busy' });
    transport.send({ status: 'away', auto: true });
    last().open();
    expect(last().sent.map((text) => JSON.parse(text))).toEqual([
      { type: 'presence:set', status: 'busy' },
    ]);
  });

  it('keeps trying when the socket cannot be created', async () => {
    let calls = 0;
    const transport = new WebSocketPresenceTransport({
      url: 'ws://host',
      socketFactory: (url) => {
        calls += 1;
        if (calls === 1) throw new SyntaxError('bad url');
        return factory(url);
      },
    });
    transport.connect(listener);
    await vi.advanceTimersByTimeAsync(0);
    expect(FakeSocket.instances).toHaveLength(0);
    await vi.advanceTimersByTimeAsync(1_000);
    expect(FakeSocket.instances).toHaveLength(1);
  });

  it('keeps trying when the url cannot be built', async () => {
    let attempts = 0;
    const transport = new WebSocketPresenceTransport({
      url: async () => {
        attempts += 1;
        if (attempts === 1) throw new Error('no token yet');
        return 'ws://host';
      },
      socketFactory: factory,
    });
    transport.connect(listener);
    await vi.advanceTimersByTimeAsync(0);
    expect(FakeSocket.instances).toHaveLength(0);
    await vi.advanceTimersByTimeAsync(1_000);
    expect(FakeSocket.instances).toHaveLength(1);
  });
});
