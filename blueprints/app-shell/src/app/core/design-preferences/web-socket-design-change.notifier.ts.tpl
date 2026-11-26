import { fetchDesignVersion, parseDesignChange, type DesignChange, type DesignChangeNotifier } from './design-change-notifier';

export interface WebSocketDesignChangeOptions {
  /**
   * The address of the server, for example `wss://api.example.com/design`. A function is called on every connection,
   * so it can add a fresh token.
   */
  readonly url: string | (() => string | Promise<string>);
  /**
   * The endpoint that answers `{ "version": "…" }`. A channel does not replay what a client missed while it was
   * disconnected (Redis pub/sub does not), so after every reconnection the notifier asks for the version once.
   */
  readonly versionUrl?: string;
  readonly headers?: () => Record<string, string>;
  /** Reconnection with exponential backoff; `false` leaves the socket closed after a failure. */
  readonly reconnect?: false | { readonly minDelayMs?: number; readonly maxDelayMs?: number };
  /** Creates the socket; for tests, or to use a different implementation. */
  readonly socketFactory?: (url: string) => WebSocket;
  /** Replaces `fetch`; for tests. */
  readonly fetch?: typeof fetch;
}

/**
 * Real-time notices over a native WebSocket: the server sends `{ "type": "design-changed", "version": "…" }` to every
 * connection when the administrator saves (docs/design-preferences.md shows it fed by Redis pub/sub). It reconnects by
 * itself.
 */
export class WebSocketDesignChangeNotifier implements DesignChangeNotifier {
  private listener: ((change: DesignChange) => void) | null = null;
  private socket: WebSocket | null = null;
  private retryTimer: ReturnType<typeof setTimeout> | null = null;
  private attempts = 0;
  private reconnecting = false;
  private closed = true;

  constructor(private readonly options: WebSocketDesignChangeOptions) {}

  connect(listener: (change: DesignChange) => void): void {
    this.listener = listener;
    this.closed = false;
    void this.open();
  }

  disconnect(): void {
    this.closed = true;
    this.listener = null;
    if (this.retryTimer !== null) clearTimeout(this.retryTimer);
    this.retryTimer = null;
    const socket = this.socket;
    this.socket = null;
    socket?.close();
  }

  private async open(): Promise<void> {
    if (this.closed || this.socket !== null) return;
    let url: string;
    try {
      url = typeof this.options.url === 'string' ? this.options.url : await this.options.url();
    } catch {
      this.scheduleReconnect();
      return;
    }
    if (this.closed || this.socket !== null) return;

    let socket: WebSocket;
    try {
      socket = (this.options.socketFactory ?? ((address) => new WebSocket(address)))(url);
    } catch {
      this.scheduleReconnect();
      return;
    }
    this.socket = socket;
    socket.onopen = () => {
      this.attempts = 0;
      if (this.reconnecting) void this.catchUp();
    };
    socket.onmessage = (message) => {
      const change = parseDesignChange(message.data);
      if (change !== null) this.listener?.(change);
    };
    socket.onclose = () => {
      if (this.socket !== socket) return;
      this.socket = null;
      this.scheduleReconnect();
    };
  }

  private async catchUp(): Promise<void> {
    const { versionUrl } = this.options;
    if (!versionUrl) return;
    const version = await fetchDesignVersion(versionUrl, this.options);
    if (version !== null) this.listener?.({ version });
  }

  private scheduleReconnect(): void {
    const { reconnect } = this.options;
    if (this.closed || reconnect === false) return;
    const min = reconnect?.minDelayMs ?? 1_000;
    const max = reconnect?.maxDelayMs ?? 30_000;
    const delay = Math.min(max, min * 2 ** this.attempts);
    this.attempts += 1;
    this.reconnecting = true;
    this.retryTimer = setTimeout(() => {
      this.retryTimer = null;
      void this.open();
    }, delay);
  }
}
