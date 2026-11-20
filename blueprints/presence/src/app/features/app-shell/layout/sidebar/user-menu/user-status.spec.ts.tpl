import { signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { PresenceService } from '@core/presence/presence.service';
import { PRESENCE_TRANSPORT, type PresenceTransport } from '@core/presence/presence.transport';
import type { PresenceChange } from '@core/presence/presence.types';
import type { AsPopover } from '@shared/components';

import { UserStatusMenu } from './user-status';

describe('UserStatusMenu', () => {
  let sent: PresenceChange[];
  let open: ReturnType<typeof signal<boolean>>;
  let anchorCalls: (HTMLElement | undefined)[];
  let menu: UserStatusMenu;

  beforeEach(() => {
    vi.useFakeTimers();
    sent = [];
    anchorCalls = [];
    const transport: PresenceTransport = {
      connect: () => undefined,
      send: (change) => sent.push(change),
      disconnect: () => undefined,
    };
    TestBed.configureTestingModule({ providers: [{ provide: PRESENCE_TRANSPORT, useValue: transport }] });
    open = signal(true);
    const popover = {
      getSubPanelAnchor: (anchor?: HTMLElement) => {
        anchorCalls.push(anchor);
        return { top: 10, left: 20 };
      },
    } as unknown as AsPopover;
    menu = TestBed.runInInjectionContext(() => new UserStatusMenu(() => popover, () => open()));
    TestBed.tick();
  });

  afterEach(() => {
    TestBed.inject(PresenceService).stop();
    vi.useRealTimers();
  });

  it('lists the four statuses of the reference, in Spanish, and which ones can end', () => {
    expect(menu.statusOptions.map((option) => [option.id, option.label, option.hasDuration])).toEqual([
      ['online', 'En línea', false],
      ['away', 'Ausente', true],
      ['busy', 'Ocupado', true],
      ['invisible', 'Invisible', true],
    ]);
    expect(menu.durationOptions.at(-1)).toEqual({ minutes: null, label: 'Para siempre' });
  });

  it('labels the status, with how long it lasts when it does', () => {
    expect(menu.statusLabel()).toBe('En línea');
    TestBed.inject(PresenceService).setManualStatus('busy', 60);
    expect(menu.status()).toBe('busy');
    expect(menu.statusLabel()).toBe('Ocupado · 1h');
    TestBed.inject(PresenceService).setManualStatus('busy');
    expect(menu.statusLabel()).toBe('Ocupado');
  });

  it('opens the status panel next to the popover when the pointer enters the row', () => {
    menu.onStatusTriggerEnter();
    expect(menu.statusSubPanelPos()).toEqual({ top: 10, left: 20 });
  });

  it('closes the panels a moment after the pointer leaves, unless it comes back', () => {
    menu.onStatusTriggerEnter();
    menu.onStatusTriggerLeave();
    menu.onStatusPanelEnter();
    vi.advanceTimersByTime(500);
    expect(menu.statusSubPanelPos()).not.toBeNull();

    menu.onStatusPanelLeave();
    vi.advanceTimersByTime(300);
    expect(menu.statusSubPanelPos()).toBeNull();
  });

  it('opens the durations only for the statuses that can end', () => {
    menu.onStatusTriggerEnter();
    menu.onStatusOptionHover('busy');
    expect(menu.hoveredStatus()).toBe('busy');
    expect(menu.durationSubPanelPos()).not.toBeNull();

    menu.onStatusOptionHover('online');
    expect(menu.hoveredStatus()).toBeNull();
    expect(menu.durationSubPanelPos()).toBeNull();
  });

  it('applies the hovered status for the chosen time, or for ever', () => {
    menu.onStatusOptionHover('busy');
    menu.selectWithDuration(60);
    menu.selectWithDuration(null);
    expect(sent).toEqual([
      { status: 'busy', auto: false, durationMinutes: 60 },
      { status: 'busy', auto: false },
    ]);
  });

  it('applies a status with no end straight away', () => {
    menu.selectStatusDirect('invisible');
    expect(sent).toEqual([{ status: 'invisible', auto: false }]);
  });

  it('does nothing when a duration is chosen without a status', () => {
    menu.selectWithDuration(15);
    expect(sent).toEqual([]);
  });

  it('closes the panels with the popover', () => {
    menu.onStatusTriggerEnter();
    menu.onStatusOptionHover('away');
    open.set(false);
    TestBed.tick();
    expect(menu.statusSubPanelPos()).toBeNull();
    expect(menu.durationSubPanelPos()).toBeNull();
    expect(menu.hoveredStatus()).toBeNull();
  });
});
