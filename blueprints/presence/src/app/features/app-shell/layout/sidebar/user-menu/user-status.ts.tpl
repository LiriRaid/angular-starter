import { DOCUMENT } from '@angular/common';
import { DestroyRef, computed, effect, inject, signal } from '@angular/core';
import { PresenceService } from '@core/presence/presence.service';
import { presenceStatusIcon, type PresenceStatus } from '@core/presence/presence.types';
import type { AsPopover, SubPanelAnchor } from '@shared/components';

/** How long the pointer may leave a panel before it closes, so it can cross the gap to the next one. */
const PANEL_CLOSE_DELAY_MS = 300;

/**
 * The state of the status row of the user menu and of its two sub-panels (the statuses and, for the
 * ones that can end, how long they last), which open on hover. The user menu holds one and its
 * template reads it. The sub-panels live outside the popover, whose panel is in the top layer, so
 * their position comes from the popover (`getSubPanelAnchor`).
 */
export class UserStatusMenu {
  private readonly presence = inject(PresenceService);
  private readonly document = inject(DOCUMENT);

  readonly status = this.presence.status;
  readonly statusIcon = presenceStatusIcon;

  readonly statusOptions: readonly { id: PresenceStatus; label: string; hasDuration: boolean }[] = [
    { id: 'online', label: 'En línea', hasDuration: false },
    { id: 'away', label: 'Ausente', hasDuration: true },
    { id: 'busy', label: 'Ocupado', hasDuration: true },
    { id: 'invisible', label: 'Invisible', hasDuration: true },
  ];

  readonly durationOptions: readonly { minutes: number | null; label: string }[] = [
    { minutes: 15, label: 'Durante 15 minutos' },
    { minutes: 60, label: 'Durante 1 hora' },
    { minutes: 480, label: 'Durante 8 horas' },
    { minutes: 1440, label: 'Durante 24 horas' },
    { minutes: 4320, label: 'Durante 3 días' },
    { minutes: null, label: 'Para siempre' },
  ];

  readonly statusSubPanelPos = signal<SubPanelAnchor | null>(null);
  readonly durationSubPanelPos = signal<SubPanelAnchor | null>(null);
  /** The status whose durations the second panel shows. */
  readonly hoveredStatus = signal<PresenceStatus | null>(null);

  /** `Ocupado · 1h`: the status, and how long it lasts when it does. */
  readonly statusLabel = computed(() => {
    const status = this.status();
    const label = this.statusOptions.find((option) => option.id === status)?.label ?? 'En línea';
    const duration = this.presence.durationLabel();
    return duration && status !== 'online' ? `${label} · ${duration}` : label;
  });

  private statusCloseTimer: ReturnType<typeof setTimeout> | null = null;
  private durationCloseTimer: ReturnType<typeof setTimeout> | null = null;

  /**
   * @param popover the popover of the user menu, to anchor the sub-panels to its panel
   * @param popoverOpen whether it is open: the sub-panels close with it
   */
  constructor(
    private readonly popover: () => AsPopover | undefined,
    popoverOpen: () => boolean,
  ) {
    inject(DestroyRef).onDestroy(() => {
      this.clearStatusTimer();
      this.clearDurationTimer();
    });
    effect(() => {
      if (!popoverOpen()) this.closeStatusPanel();
    });
  }

  onStatusTriggerEnter(): void {
    this.clearStatusTimer();
    if (this.statusSubPanelPos() === null) {
      this.statusSubPanelPos.set(this.popover()?.getSubPanelAnchor() ?? null);
    }
  }

  onStatusTriggerLeave(): void {
    this.statusCloseTimer = setTimeout(() => this.closeStatusPanel(), PANEL_CLOSE_DELAY_MS);
  }

  onStatusPanelEnter(): void {
    this.clearStatusTimer();
    this.clearDurationTimer();
  }

  onStatusPanelLeave(): void {
    this.statusCloseTimer = setTimeout(() => this.closeStatusPanel(), PANEL_CLOSE_DELAY_MS);
  }

  /** The pointer is on an option: the ones that can end open the durations next to it. */
  onStatusOptionHover(id: PresenceStatus): void {
    this.clearDurationTimer();
    if (this.statusOptions.find((option) => option.id === id)?.hasDuration) {
      this.hoveredStatus.set(id);
      const statusPanel = this.document.querySelector<HTMLElement>(
        '.um-sub-panel:not(.um-sub-panel--duration)',
      );
      this.durationSubPanelPos.set(this.popover()?.getSubPanelAnchor(statusPanel ?? undefined) ?? null);
    } else {
      this.hoveredStatus.set(null);
      this.durationSubPanelPos.set(null);
    }
  }

  onDurationPanelEnter(): void {
    this.clearDurationTimer();
    this.clearStatusTimer();
  }

  onDurationPanelLeave(): void {
    // The pointer left the whole flow, so both panels close.
    this.durationCloseTimer = setTimeout(() => this.closeStatusPanel(), PANEL_CLOSE_DELAY_MS);
  }

  /** A status with no end: online, or the one the user picks directly. */
  selectStatusDirect(id: PresenceStatus): void {
    this.presence.setManualStatus(id, null);
  }

  /** The hovered status for `minutes`, or for ever when `minutes` is null. */
  selectWithDuration(minutes: number | null): void {
    const status = this.hoveredStatus();
    if (status !== null) this.presence.setManualStatus(status, minutes);
  }

  private closeStatusPanel(): void {
    this.clearStatusTimer();
    this.clearDurationTimer();
    this.statusSubPanelPos.set(null);
    this.hoveredStatus.set(null);
    this.durationSubPanelPos.set(null);
  }

  private clearStatusTimer(): void {
    if (this.statusCloseTimer !== null) {
      clearTimeout(this.statusCloseTimer);
      this.statusCloseTimer = null;
    }
  }

  private clearDurationTimer(): void {
    if (this.durationCloseTimer !== null) {
      clearTimeout(this.durationCloseTimer);
      this.durationCloseTimer = null;
    }
  }
}
