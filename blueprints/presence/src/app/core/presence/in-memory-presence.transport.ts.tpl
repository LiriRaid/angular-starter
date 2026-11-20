import type { PresenceTransport } from './presence.transport';
import type {
  PresenceChange,
  PresenceEvent,
  PresenceStatus,
  PresenceUser,
} from './presence.types';

export interface InMemoryPresenceOptions {
  /** The id this client gets in the `welcome`. */
  readonly userId?: string;
  /** Other users the "server" knows, to see presence in lists before there is a backend. */
  readonly peers?: readonly PresenceUser[];
}

/**
 * A transport with no network: it answers like a server would. It sends the welcome and the
 * snapshot when it connects, echoes every change of this client as an `update` and remembers the
 * status while the page lives. Events are delivered asynchronously, as a socket does.
 */
export class InMemoryPresenceTransport implements PresenceTransport {
  private listener: ((event: PresenceEvent) => void) | null = null;
  /** Changes with every connection, so what was on its way to a closed one is dropped. */
  private connection = 0;
  private status: PresenceStatus = 'online';
  private readonly userId: string;
  private readonly peers: PresenceUser[];

  constructor(options: InMemoryPresenceOptions = {}) {
    this.userId = options.userId ?? 'me';
    this.peers = [...(options.peers ?? [])];
  }

  connect(listener: (event: PresenceEvent) => void): void {
    this.listener = listener;
    this.connection += 1;
    this.deliver({ type: 'welcome', userId: this.userId });
    this.deliver({
      type: 'snapshot',
      users: [{ userId: this.userId, status: this.status }, ...this.peers],
    });
  }

  send(change: PresenceChange): void {
    if (!this.listener) return;
    this.status = change.status;
    const seconds = !change.auto && change.durationMinutes ? change.durationMinutes * 60 : 0;
    this.deliver({
      type: 'update',
      userId: this.userId,
      status: change.status,
      ...(seconds > 0 ? { timerRemainingSeconds: seconds } : {}),
    });
  }

  disconnect(): void {
    this.listener = null;
    this.connection += 1;
  }

  /** Delivers the change of another user, as the server would when someone else changes status. */
  simulatePeer(userId: string, status: PresenceStatus): void {
    this.deliver({ type: 'update', userId, status });
  }

  private deliver(event: PresenceEvent): void {
    const target = this.listener;
    const connection = this.connection;
    queueMicrotask(() => {
      if (target !== null && this.connection === connection) target(event);
    });
  }
}
