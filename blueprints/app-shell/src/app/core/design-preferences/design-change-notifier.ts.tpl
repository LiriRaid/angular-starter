import { InjectionToken } from '@angular/core';

/** The platform has a new design: the `version` of the document that was saved. */
export interface DesignChange {
  readonly version: string;
}

/**
 * How the users who are using the application find out that the administrator saved another design (ADR-0029). It
 * only reports the new `version`: the shell compares it with the one it applied and, when it differs, offers to reload
 * the page. Nothing is applied by itself. Implement it with whatever your platform has (a WebSocket fed by a Redis
 * channel, a polling of the document, server-sent events); `docs/design-preferences.md` shows two.
 */
export interface DesignChangeNotifier {
  /** Starts listening; call `listener` with every change, whoever made it. */
  connect(listener: (change: DesignChange) => void): void;
  disconnect(): void;
}

/** The message the server pushes: `{ "type": "design-changed", "version": "…" }`. Anything else is ignored. */
export const parseDesignChange = (data: unknown): DesignChange | null => {
  try {
    const message: unknown = typeof data === 'string' ? JSON.parse(data) : null;
    const { type, version } = (message ?? {}) as Record<string, unknown>;
    return type === 'design-changed' && typeof version === 'string' ? { version } : null;
  } catch {
    return null;
  }
};

/** Asks `url` (`GET { "version": "…" }`) for the version of the design; `null` when it cannot be known. */
export const fetchDesignVersion = async (url: string, options: { readonly fetch?: typeof fetch; readonly headers?: () => Record<string, string> } = {}): Promise<string | null> => {
  try {
    const response = await (options.fetch ?? fetch)(url, { headers: { accept: 'application/json', ...options.headers?.() }, credentials: 'include' });
    if (!response.ok) return null;
    const { version } = (await response.json()) as { version?: unknown };
    return typeof version === 'string' ? version : null;
  } catch {
    return null;
  }
};

/** The default tells nobody: users see the new design when they reload the page. */
export const DESIGN_CHANGE_NOTIFIER = new InjectionToken<DesignChangeNotifier>('DESIGN_CHANGE_NOTIFIER', {
  providedIn: 'root',
  factory: () => ({ connect: () => undefined, disconnect: () => undefined }),
});
