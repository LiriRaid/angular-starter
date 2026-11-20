import { DOCUMENT, isPlatformBrowser } from '@angular/common';
import { DestroyRef, Injectable, PLATFORM_ID, inject, signal } from '@angular/core';
import { fromEvent, merge, type Subscription } from 'rxjs';
import { throttleTime } from 'rxjs/operators';
import { PRESENCE_TRANSPORT } from './presence.transport';
import type { PresenceEvent, PresenceStatus } from './presence.types';

const IDLE_TIMEOUT_MS = 5 * 60 * 1000;
const HIDDEN_TIMEOUT_MS = 5 * 60 * 1000;
/** Visibility changes right after start are the page loading, not the user leaving. */
const READY_DELAY_MS = 2_000;

const ACTIVITY_EVENTS = ['mousemove', 'mousedown', 'keydown', 'scroll', 'touchstart', 'click'] as const;

/**
 * The status of the user of this client and of the others, in real time.
 *
 * It keeps the user `online` while there is activity, moves them to `away` by itself after five
 * minutes without it (or with the tab hidden) and brings them back with the next interaction. A
 * manual status (`busy`, `away`, `invisible`) lasts until it is changed, or for the duration chosen.
 * Every change goes to the server through the `PresenceTransport`, and what the server says (the
 * snapshot, the updates of the others and the echo of the own ones) comes back the same way.
 *
 * `providePresence()` starts it with the application; `start()` and `stop()` are for an application
 * that connects after a sign-in and disconnects after a sign-out.
 */
@Injectable({ providedIn: 'root' })
export class PresenceService {
  private readonly transport = inject(PRESENCE_TRANSPORT);
  private readonly document = inject(DOCUMENT);
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));

  private readonly _status = signal<PresenceStatus>('online');
  private readonly _durationLabel = signal<string | null>(null);
  private readonly _selfId = signal<string | null>(null);
  private readonly _users = signal<ReadonlyMap<string, PresenceStatus>>(new Map());

  /** The status of this user. */
  readonly status = this._status.asReadonly();
  /** How long the manual status lasts (`15m`, `1h`, `8h`, `24h`, `3d`), or null when it does not end. */
  readonly durationLabel = this._durationLabel.asReadonly();
  /** The id the server gave this client, once it has said it. */
  readonly selfId = this._selfId.asReadonly();
  /** The last status of every user the server told about, by id. */
  readonly users = this._users.asReadonly();

  private started = false;
  private manualStatus: PresenceStatus = 'online';
  private isManualAway = false;
  private isIdle = false;
  private isHidden = false;
  private isReady = false;

  private durationTimer: ReturnType<typeof setTimeout> | null = null;
  private idleTimer: ReturnType<typeof setTimeout> | null = null;
  private hiddenTimer: ReturnType<typeof setTimeout> | null = null;
  private readyTimer: ReturnType<typeof setTimeout> | null = null;
  private activitySub: Subscription | null = null;
  private visibilitySub: Subscription | null = null;

  constructor() {
    inject(DestroyRef).onDestroy(() => this.stop());
  }

  /** Connects to the server and starts watching the activity of the user. */
  start(): void {
    if (this.started) return;
    this.started = true;
    this.isIdle = false;
    this.isManualAway = false;
    this.isHidden = this.isBrowser ? this.document.hidden : false;
    this.manualStatus = 'online';
    this._status.set('online');
    this.transport.connect((event) => this.onEvent(event));
    if (this.isBrowser) this.startListeners();
  }

  /**
   * Disconnects. It does not announce anything: the server marks the user as gone when the
   * connection closes (docs/presence.md explains the grace period it should wait).
   */
  stop(): void {
    if (!this.started) return;
    this.started = false;
    this.stopListeners();
    this.clearDurationTimer();
    this.transport.disconnect();
    this.isIdle = false;
    this.isManualAway = false;
    this.manualStatus = 'online';
    this._status.set('online');
    this._selfId.set(null);
    this._users.set(new Map());
  }

  /** The user chooses a status, for `durationMinutes` or until they change it. */
  setManualStatus(status: PresenceStatus, durationMinutes: number | null = null): void {
    this.isIdle = false;
    this.isManualAway = status === 'away';
    this.clearDurationTimer();
    this.patch(status, false, durationMinutes ?? undefined);

    if (durationMinutes !== null && durationMinutes > 0) {
      this.manualStatus = status;
      this._durationLabel.set(labelFromMinutes(durationMinutes));
      this.durationTimer = setTimeout(() => {
        this.clearDurationTimer();
        this.setManualStatus('online', null);
      }, durationMinutes * 60 * 1000);
    } else {
      this.manualStatus = status;
    }

    if (status === 'invisible' || status === 'away') {
      this.clearIdleTimer();
      this.cancelHiddenTimer();
    } else {
      this.resetIdleTimer();
      if (this.isHidden) this.startHiddenTimer();
    }
  }

  /**
   * Takes the status of this user from the server (another tab, the end of a duration, a restart).
   * It never sends anything back: a change that comes from the server and is sent again would loop.
   */
  syncFromServer(status: PresenceStatus, remainingSeconds?: number): void {
    // The automatic away is this client's own: the echo of the server must not undo it.
    if (this.isIdle) return;
    this._status.set(status);

    this.isManualAway = status === 'away';
    this.manualStatus = status;
    if (status !== 'online') {
      this.clearIdleTimer();
      this.cancelHiddenTimer();
    } else if (this.isBrowser && !this.isHidden) {
      // Back online (the end of a duration, another tab): the inactivity clock starts again.
      this.resetIdleTimer();
    }
    if (remainingSeconds && remainingSeconds > 0) {
      this.clearDurationTimer();
      this._durationLabel.set(labelFromSeconds(remainingSeconds));
      this.durationTimer = setTimeout(() => {
        this.clearDurationTimer();
        this.setManualStatus('online', null);
      }, remainingSeconds * 1000);
    } else {
      this.clearDurationTimer();
    }
  }

  private onEvent(event: PresenceEvent): void {
    switch (event.type) {
      case 'welcome':
        this._selfId.set(event.userId);
        break;
      case 'snapshot': {
        this._users.set(new Map(event.users.map((user) => [user.userId, user.status])));
        const own = event.users.find((user) => user.userId === this._selfId());
        if (own) this.syncFromServer(own.status, event.timerRemainingSeconds);
        break;
      }
      case 'update':
        this._users.update((users) => new Map(users).set(event.userId, event.status));
        if (event.userId === this._selfId()) {
          this.syncFromServer(event.status, event.timerRemainingSeconds);
        }
        break;
    }
  }

  private startListeners(): void {
    this.stopListeners();
    this.isReady = false;
    this.readyTimer = setTimeout(() => {
      this.isReady = true;
    }, READY_DELAY_MS);

    const activity$ = merge(...ACTIVITY_EVENTS.map((name) => fromEvent(this.document, name))).pipe(
      throttleTime(1_000),
    );
    this.activitySub = activity$.subscribe(() => this.onActivity());
    this.visibilitySub = fromEvent(this.document, 'visibilitychange').subscribe(() =>
      this.onVisibilityChange(),
    );

    this.resetIdleTimer();
  }

  private stopListeners(): void {
    this.isReady = false;
    if (this.readyTimer !== null) {
      clearTimeout(this.readyTimer);
      this.readyTimer = null;
    }
    this.activitySub?.unsubscribe();
    this.visibilitySub?.unsubscribe();
    this.activitySub = null;
    this.visibilitySub = null;
    this.clearIdleTimer();
    this.cancelHiddenTimer();
  }

  private onActivity(): void {
    if (this.isHidden) return;
    if (this.isIdle && !this.isManualAway) {
      this.isIdle = false;
      if (this.manualStatus !== 'invisible') this.patch(this.manualStatus);
    }
    this.resetIdleTimer();
  }

  private onVisibilityChange(): void {
    if (!this.isReady) return;
    this.isHidden = this.document.hidden;

    if (this.document.hidden) {
      this.clearIdleTimer();
      if (this.manualStatus === 'online') this.startHiddenTimer();
    } else {
      this.cancelHiddenTimer();
      // Not back online yet: wait for a real interaction (onActivity).
      this.resetIdleTimer();
    }
  }

  private resetIdleTimer(): void {
    this.clearIdleTimer();
    // The automatic away only applies to an online user: busy, invisible and a manual away stay.
    if (this.manualStatus !== 'online') return;
    this.idleTimer = setTimeout(() => {
      if (this.manualStatus !== 'online') return;
      this.isIdle = true;
      this.patch('away', true);
    }, IDLE_TIMEOUT_MS);
  }

  private clearIdleTimer(): void {
    if (this.idleTimer !== null) {
      clearTimeout(this.idleTimer);
      this.idleTimer = null;
    }
  }

  private startHiddenTimer(): void {
    this.cancelHiddenTimer();
    this.hiddenTimer = setTimeout(() => {
      this.hiddenTimer = null;
      if (this.document.hidden && this.manualStatus === 'online') {
        this.isIdle = true;
        this.patch('away', true);
      }
    }, HIDDEN_TIMEOUT_MS);
  }

  private cancelHiddenTimer(): void {
    if (this.hiddenTimer !== null) {
      clearTimeout(this.hiddenTimer);
      this.hiddenTimer = null;
    }
  }

  private patch(status: PresenceStatus, auto = false, durationMinutes?: number): void {
    this._status.set(status);
    this.transport.send({ status, auto, ...(durationMinutes ? { durationMinutes } : {}) });
  }

  private clearDurationTimer(): void {
    if (this.durationTimer !== null) {
      clearTimeout(this.durationTimer);
      this.durationTimer = null;
    }
    this._durationLabel.set(null);
  }
}

function labelFromMinutes(minutes: number): string {
  if (minutes >= 4320) return '3d';
  if (minutes >= 1440) return '24h';
  if (minutes >= 480) return '8h';
  if (minutes >= 60) return '1h';
  return '15m';
}

function labelFromSeconds(seconds: number): string {
  return labelFromMinutes(seconds / 60);
}
