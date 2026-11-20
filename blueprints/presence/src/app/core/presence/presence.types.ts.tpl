export const PRESENCE_STATUSES = ['online', 'away', 'busy', 'invisible'] as const;

/** What a user shows to the others: `invisible` is how an offline user appears. */
export type PresenceStatus = (typeof PRESENCE_STATUSES)[number];

export function isPresenceStatus(value: unknown): value is PresenceStatus {
  return typeof value === 'string' && (PRESENCE_STATUSES as readonly string[]).includes(value);
}

/** Icon drawn in the presence dot for each status; `online` is a plain dot. */
export const PRESENCE_STATUS_ICONS: Readonly<Record<PresenceStatus, string | null>> = {
  online: null,
  away: 'Moon',
  busy: 'CircleMinus',
  invisible: 'CircleDot',
};

export function presenceStatusIcon(status: string | null | undefined): string | null {
  return isPresenceStatus(status) ? PRESENCE_STATUS_ICONS[status] : null;
}

export interface PresenceUser {
  readonly userId: string;
  readonly status: PresenceStatus;
}

/** What the client asks the server to do with its own status. */
export interface PresenceChange {
  readonly status: PresenceStatus;
  /** True for the automatic away of inactivity: the server must not keep it as a preference. */
  readonly auto?: boolean;
  /** How long a manual status lasts before the user goes back online; none means until changed. */
  readonly durationMinutes?: number | null;
}

/**
 * What a transport delivers to the service, whatever its wire format:
 * - `welcome`: who this client is, so it can tell its own events from the others'.
 * - `snapshot`: the status of every user, sent when the client connects. `timerRemainingSeconds`
 *   is the time left of the duration of the client's own status.
 * - `update`: one user changed status.
 */
export type PresenceEvent =
  | { readonly type: 'welcome'; readonly userId: string }
  | {
      readonly type: 'snapshot';
      readonly users: readonly PresenceUser[];
      readonly timerRemainingSeconds?: number;
    }
  | {
      readonly type: 'update';
      readonly userId: string;
      readonly status: PresenceStatus;
      readonly timerRemainingSeconds?: number;
    };
