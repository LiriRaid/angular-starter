import { TestBed } from '@angular/core/testing';
import { PresenceService } from './presence.service';
import { PRESENCE_TRANSPORT, type PresenceTransport } from './presence.transport';
import type { PresenceChange, PresenceEvent } from './presence.types';

const MINUTE = 60 * 1000;

/** A transport that records what the service sends and lets the spec play the server. */
class FakeTransport implements PresenceTransport {
  listener: ((event: PresenceEvent) => void) | null = null;
  sent: PresenceChange[] = [];
  disconnected = 0;

  connect(listener: (event: PresenceEvent) => void): void {
    this.listener = listener;
  }
  send(change: PresenceChange): void {
    this.sent.push(change);
  }
  disconnect(): void {
    this.listener = null;
    this.disconnected += 1;
  }
  emit(event: PresenceEvent): void {
    this.listener?.(event);
  }
}

describe('PresenceService', () => {
  let transport: FakeTransport;
  let service: PresenceService;

  const setHidden = (hidden: boolean): void => {
    Object.defineProperty(document, 'hidden', { configurable: true, get: () => hidden });
    document.dispatchEvent(new Event('visibilitychange'));
  };

  beforeEach(() => {
    vi.useFakeTimers();
    transport = new FakeTransport();
    TestBed.configureTestingModule({ providers: [{ provide: PRESENCE_TRANSPORT, useValue: transport }] });
    service = TestBed.inject(PresenceService);
    service.start();
    transport.emit({ type: 'welcome', userId: 'me' });
  });

  afterEach(() => {
    service.stop();
    vi.useRealTimers();
    Reflect.deleteProperty(document, 'hidden');
  });

  describe('connection', () => {
    it('connects once and starts online', () => {
      service.start();
      expect(transport.listener).not.toBeNull();
      expect(service.status()).toBe('online');
      expect(service.selfId()).toBe('me');
    });

    it('keeps the status of every user the server sends in the snapshot', () => {
      transport.emit({
        type: 'snapshot',
        users: [
          { userId: 'me', status: 'online' },
          { userId: 'ana', status: 'busy' },
        ],
      });
      expect(service.users().get('ana')).toBe('busy');
      expect(service.users().size).toBe(2);
    });

    it('follows the updates of the others and takes its own from the server', () => {
      transport.emit({ type: 'update', userId: 'ana', status: 'away' });
      expect(service.users().get('ana')).toBe('away');
      expect(service.status()).toBe('online');

      transport.emit({ type: 'update', userId: 'me', status: 'busy', timerRemainingSeconds: 900 });
      expect(service.status()).toBe('busy');
      expect(service.durationLabel()).toBe('15m');
    });

    it('restores the status the server kept for this user when it connects', () => {
      transport.emit({
        type: 'snapshot',
        users: [{ userId: 'me', status: 'invisible' }],
        timerRemainingSeconds: 3600,
      });
      expect(service.status()).toBe('invisible');
      expect(service.durationLabel()).toBe('1h');
    });

    it('disconnects and forgets what it knew when it stops', () => {
      transport.emit({ type: 'update', userId: 'ana', status: 'busy' });
      service.stop();
      expect(transport.disconnected).toBe(1);
      expect(service.users().size).toBe(0);
      expect(service.selfId()).toBeNull();
      vi.advanceTimersByTime(10 * MINUTE);
      expect(transport.sent).toEqual([]);
    });
  });

  describe('manual status', () => {
    it('shows the status at once and tells the server', () => {
      service.setManualStatus('busy');
      expect(service.status()).toBe('busy');
      expect(transport.sent).toEqual([{ status: 'busy', auto: false }]);
    });

    it('sends the duration and goes back online when it ends', () => {
      service.setManualStatus('busy', 15);
      expect(transport.sent[0]).toEqual({ status: 'busy', auto: false, durationMinutes: 15 });
      expect(service.durationLabel()).toBe('15m');

      vi.advanceTimersByTime(15 * MINUTE);
      expect(service.status()).toBe('online');
      expect(service.durationLabel()).toBeNull();
      expect(transport.sent.at(-1)).toEqual({ status: 'online', auto: false });
    });

    it.each([
      [15, '15m'],
      [60, '1h'],
      [480, '8h'],
      [1440, '24h'],
      [4320, '3d'],
    ])('labels a duration of %i minutes as %s', (minutes, label) => {
      service.setManualStatus('away', minutes);
      expect(service.durationLabel()).toBe(label);
    });

    it('keeps a manual status that has no end until it is changed', () => {
      service.setManualStatus('invisible');
      vi.advanceTimersByTime(60 * MINUTE);
      expect(service.status()).toBe('invisible');
      expect(service.durationLabel()).toBeNull();
    });
  });

  describe('automatic away', () => {
    it('moves an online user to away after five minutes without activity, marked as automatic', () => {
      vi.advanceTimersByTime(5 * MINUTE);
      expect(service.status()).toBe('away');
      expect(transport.sent).toEqual([{ status: 'away', auto: true }]);
    });

    it('does not move the user while there is activity', () => {
      for (let minute = 0; minute < 8; minute++) {
        vi.advanceTimersByTime(MINUTE);
        document.dispatchEvent(new Event('mousemove'));
      }
      expect(service.status()).toBe('online');
      expect(transport.sent).toEqual([]);
    });

    it('brings the user back online with the next interaction', () => {
      vi.advanceTimersByTime(5 * MINUTE);
      document.dispatchEvent(new Event('keydown'));
      expect(service.status()).toBe('online');
      expect(transport.sent.at(-1)).toEqual({ status: 'online', auto: false });
    });

    it('does not undo the automatic away with the echo of the server', () => {
      vi.advanceTimersByTime(5 * MINUTE);
      transport.emit({ type: 'update', userId: 'me', status: 'away' });
      expect(service.status()).toBe('away');
      expect(transport.sent).toHaveLength(1);
    });

    it.each(['busy', 'invisible'] as const)('leaves a manual %s alone', (status) => {
      service.setManualStatus(status);
      transport.sent.length = 0;
      vi.advanceTimersByTime(30 * MINUTE);
      expect(service.status()).toBe(status);
      expect(transport.sent).toEqual([]);
    });

    it('does not bring a manual away back on its own, only the user can', () => {
      service.setManualStatus('away');
      document.dispatchEvent(new Event('click'));
      expect(service.status()).toBe('away');
    });
  });

  describe('hidden tab', () => {
    it('moves the user to away after five minutes with the tab hidden', () => {
      vi.advanceTimersByTime(2_000);
      setHidden(true);
      vi.advanceTimersByTime(5 * MINUTE);
      expect(service.status()).toBe('away');
      expect(transport.sent.at(-1)).toEqual({ status: 'away', auto: true });
    });

    it('ignores the visibility changes of the page loading', () => {
      setHidden(true);
      vi.advanceTimersByTime(4 * MINUTE);
      expect(service.status()).toBe('online');
    });

    it('does not move the user when the tab comes back in time', () => {
      vi.advanceTimersByTime(2_000);
      setHidden(true);
      vi.advanceTimersByTime(4 * MINUTE);
      setHidden(false);
      vi.advanceTimersByTime(4 * MINUTE);
      expect(service.status()).toBe('online');
    });
  });

  describe('syncFromServer', () => {
    it('takes the status without sending anything back', () => {
      service.syncFromServer('busy', 3600);
      expect(service.status()).toBe('busy');
      expect(service.durationLabel()).toBe('1h');
      expect(transport.sent).toEqual([]);
    });

    it('goes back online when the duration the server gave runs out', () => {
      service.syncFromServer('busy', 60);
      vi.advanceTimersByTime(60 * 1000);
      expect(service.status()).toBe('online');
    });
  });
});
