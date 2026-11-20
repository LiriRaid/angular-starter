import { parseServerMessage, serializeChange } from './presence.protocol';
import type { PresenceTransport } from './presence.transport';
import type { PresenceChange, PresenceEvent } from './presence.types';

/** The `readyState` of an open socket. */
const OPEN = 1;

export interface WebSocketPresenceOptions {
  /**
   * The address of the server, for example `wss://api.example.com/presence`. A function is called
   * on every connection, so it can add a fresh token: `() => `${base}?token=${session.token()}``.
   */
  readonly url: string | (() => string | Promise<string>);
  readonly protocols?: string | string[];
  /** Reconnection with exponential backoff; `false` leaves the socket closed after a failure. */
  readonly reconnect?: false | { readonly minDelayMs?: number; readonly maxDelayMs?: number };
  /** Creates the socket; for tests, or to use a different implementation. */
  readonly socketFactory?: (url: string, protocols?: string | string[]) => WebSocket;
}

/**
 * Presence over a native WebSocket speaking the JSON protocol of `presence.protocol.ts`, which
 * docs/presence.md describes for the server. It reconnects by itself: the server sends the snapshot
 * again and the state of the client follows.
 */
export class WebSocketPresenceTransport implements PresenceTransport {
  private listener: ((event: PresenceEvent) => void) | null = null;
  private socket: WebSocket | null = null;
  private retryTimer: ReturnType<typeof setTimeout> | null = null;
  private attempts = 0;
  /** The last change that could not be sent because the socket was down; sent when it opens. */
  private pending: PresenceChange | null = null;
  private closed = true;

  constructor(private readonly options: WebSocketPresenceOptions) {}

  connect(listener: (event: PresenceEvent) => void): void {
    this.listener = listener;
    this.closed = false;
    void this.open();
  }

  send(change: PresenceChange): void {
    if (this.socket?.readyState === OPEN) {
      this.socket.send(serializeChange(change));
      this.pending = null;
    } else if (!change.auto) {
      // What the user chose wins over what the server restores when the socket comes back.
      this.pending = change;
    }
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

    const create = this.options.socketFactory ?? ((address, protocols) => new WebSocket(address, protocols));
    let socket: WebSocket;
    try {
      socket = create(url, this.options.protocols);
    } catch {
      this.scheduleReconnect();
      return;
    }
    this.socket = socket;
    socket.onopen = () => {
      this.attempts = 0;
      if (this.pending !== null) {
        const change = this.pending;
        this.pending = null;
        this.send(change);
      }
    };
    socket.onmessage = (message) => {
      const event = parseServerMessage(message.data);
      if (event !== null) this.listener?.(event);
    };
    socket.onclose = () => {
      if (this.socket !== socket) return;
      this.socket = null;
      this.scheduleReconnect();
    };
  }

  private scheduleReconnect(): void {
    const { reconnect } = this.options;
    if (this.closed || reconnect === false) return;
    const min = reconnect?.minDelayMs ?? 1_000;
    const max = reconnect?.maxDelayMs ?? 30_000;
    const delay = Math.min(max, min * 2 ** this.attempts);
    this.attempts += 1;
    this.retryTimer = setTimeout(() => {
      this.retryTimer = null;
      void this.open();
    }, delay);
  }
}
