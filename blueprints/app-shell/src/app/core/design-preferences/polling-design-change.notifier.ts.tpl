import { fetchDesignVersion, type DesignChange, type DesignChangeNotifier } from './design-change-notifier';

export interface PollingDesignChangeOptions {
  /** The endpoint that answers `{ "version": "…" }` with the version of the design (see `docs/design-preferences.md`). */
  readonly url: string;
  /** Time between checks. Default: one minute. */
  readonly intervalMs?: number;
  /** A tab that comes back checks at once, unless it checked less than this ago. Default: ten seconds. */
  readonly minGapMs?: number;
  readonly headers?: () => Record<string, string>;
  /** Replaces `fetch`; for tests. */
  readonly fetch?: typeof fetch;
}

/**
 * Finds out about a new design by asking the server for its version: every minute, and when the tab comes back to the
 * foreground. It needs no sockets, only the version endpoint, and it does nothing while the tab is hidden.
 */
export class PollingDesignChangeNotifier implements DesignChangeNotifier {
  private listener: ((change: DesignChange) => void) | null = null;
  private timer: ReturnType<typeof setInterval> | null = null;
  private lastCheck = 0;
  private lastVersion: string | null = null;

  constructor(private readonly options: PollingDesignChangeOptions) {}

  connect(listener: (change: DesignChange) => void): void {
    this.disconnect();
    this.listener = listener;
    this.timer = setInterval(() => void this.check(), this.options.intervalMs ?? 60_000);
    document.addEventListener('visibilitychange', this.onVisibilityChange);
  }

  disconnect(): void {
    if (this.timer !== null) clearInterval(this.timer);
    this.timer = null;
    this.listener = null;
    document.removeEventListener('visibilitychange', this.onVisibilityChange);
  }

  private readonly onVisibilityChange = (): void => {
    if (!document.hidden && Date.now() - this.lastCheck >= (this.options.minGapMs ?? 10_000)) void this.check();
  };

  private async check(): Promise<void> {
    if (document.hidden) return;
    this.lastCheck = Date.now();
    const version = await fetchDesignVersion(this.options.url, this.options);
    if (version !== null && version !== this.lastVersion) {
      this.lastVersion = version;
      this.listener?.({ version });
    }
  }
}
