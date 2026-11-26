import type { DesignChange } from './design-change-notifier';
import { WebSocketDesignChangeNotifier } from './web-socket-design-change.notifier';

/** The part of a socket the notifier uses, driven by the spec as the server would. */
class FakeSocket {
  static instances: FakeSocket[] = [];
  readyState = 0;
  onopen: (() => void) | null = null;
  onmessage: ((message: { data: unknown }) => void) | null = null;
  onclose: (() => void) | null = null;

  constructor(readonly url: string) {
    FakeSocket.instances.push(this);
  }

  close(): void {
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

const factory = (url: string): WebSocket => new FakeSocket(url) as unknown as WebSocket;

describe('WebSocketDesignChangeNotifier', () => {
  let changes: DesignChange[];
  let fetchSpy: ReturnType<typeof vi.fn<typeof fetch>>;
  const listener = (change: DesignChange): void => {
    changes.push(change);
  };
  const last = (): FakeSocket => FakeSocket.instances.at(-1) as FakeSocket;

  const create = (options: Partial<ConstructorParameters<typeof WebSocketDesignChangeNotifier>[0]> = {}) => new WebSocketDesignChangeNotifier({ url: 'wss://api.example.com/design', socketFactory: factory, fetch: fetchSpy, ...options });

  beforeEach(() => {
    vi.useFakeTimers();
    FakeSocket.instances = [];
    changes = [];
    fetchSpy = vi.fn<typeof fetch>().mockImplementation(async () => new Response(JSON.stringify({ version: 'v9' }), { status: 200 }));
  });

  afterEach(() => vi.useRealTimers());

  it('opens the socket of the server when it connects', async () => {
    create().connect(listener);
    await vi.advanceTimersByTimeAsync(0);
    expect(FakeSocket.instances).toHaveLength(1);
    expect(last().url).toBe('wss://api.example.com/design');
  });

  it('reports the version of a design-changed message', async () => {
    create().connect(listener);
    await vi.advanceTimersByTimeAsync(0);
    last().open();
    last().receive(JSON.stringify({ type: 'design-changed', version: 'v5' }));
    expect(changes).toEqual([{ version: 'v5' }]);
  });

  it('ignores what is not a design-changed message', async () => {
    create().connect(listener);
    await vi.advanceTimersByTimeAsync(0);
    last().open();
    for (const data of ['not json', '{"type":"ping"}', '{"type":"design-changed"}', '{"type":"design-changed","version":7}', 42]) last().receive(data);
    expect(changes).toEqual([]);
  });

  it('asks for the url of every connection, so it can carry a fresh token', async () => {
    let token = 0;
    create({ url: () => `wss://api.example.com/design?token=${++token}` }).connect(listener);
    await vi.advanceTimersByTimeAsync(0);
    expect(last().url).toContain('token=1');
    last().drop();
    await vi.advanceTimersByTimeAsync(1_000);
    expect(last().url).toContain('token=2');
  });

  it('reconnects with a growing delay and starts again from the minimum once it connects', async () => {
    create().connect(listener);
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

  it('checks the version after a reconnection, because a channel does not replay what was missed', async () => {
    create({ versionUrl: '/api/design-preferences/version' }).connect(listener);
    await vi.advanceTimersByTimeAsync(0);
    last().open();
    expect(fetchSpy).not.toHaveBeenCalled();
    last().drop();
    await vi.advanceTimersByTimeAsync(1_000);
    last().open();
    await vi.advanceTimersByTimeAsync(0);
    expect(fetchSpy.mock.calls[0][0]).toBe('/api/design-preferences/version');
    expect(changes).toEqual([{ version: 'v9' }]);
  });

  it('does not reconnect when it is told not to, nor after disconnecting', async () => {
    create({ reconnect: false }).connect(listener);
    await vi.advanceTimersByTimeAsync(0);
    last().drop();
    await vi.advanceTimersByTimeAsync(60_000);
    expect(FakeSocket.instances).toHaveLength(1);

    const notifier = create();
    notifier.connect(listener);
    await vi.advanceTimersByTimeAsync(0);
    notifier.disconnect();
    await vi.advanceTimersByTimeAsync(60_000);
    expect(FakeSocket.instances).toHaveLength(2);
  });
});
