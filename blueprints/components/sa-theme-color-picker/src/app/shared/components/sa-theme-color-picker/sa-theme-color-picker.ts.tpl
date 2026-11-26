import { DOCUMENT } from '@angular/common';
import { ChangeDetectionStrategy, Component, DestroyRef, ElementRef, TemplateRef, ViewEncapsulation, computed, inject, input, signal, viewChild } from '@angular/core';

import { PRIMARY_COLORS, SURFACE_COLORS } from '@core/theme/theme-palettes';
import { ThemeService } from '@core/theme/theme.service';
import { isAnchorOutOfView, visibleBounds } from '@shared/utils/panel-placement';
import { addNativeOverlayListeners, isEventInsideOverlay, NativeOverlayScheduler, removeNativeOverlayListeners, resolveOverlayTriggerElement } from '../../utils/native-overlay-dismiss';
import { SaButton } from '..';
import { getPopoverPanelLayout, resolvePopoverPlacement } from '../sa-popover/sa-popover.config';
import { SaTooltip } from '../sa-tooltip/sa-tooltip.directive';

@Component({
  selector: 'sa-theme-color-picker',
  standalone: true,
  imports: [SaButton, SaTooltip],
  templateUrl: './sa-theme-color-picker.html',
  styleUrl: './sa-theme-color-picker.css',
  encapsulation: ViewEncapsulation.None,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SaThemeColorPicker {
  private readonly themeService = inject(ThemeService);
  private readonly document = inject(DOCUMENT);
  private readonly destroyRef = inject(DestroyRef);

  readonly triggerClass = input<string>('');
  readonly size = input<'small' | 'medium' | 'high'>('small');

  /** Se aplica sobre el botón interno (no sobre el host) para que el mouseenter/mouseleave de
   *  los swatches del panel — descendientes del host en el DOM aunque se vean en otro lugar por
   *  `position: fixed` — no burbujee hasta un listener a nivel de componente y reabra este tooltip. */
  readonly triggerTooltip = input<string | TemplateRef<unknown> | null>('');
  readonly triggerTooltipPosition = input<'top' | 'bottom' | 'left' | 'right'>('bottom');
  readonly triggerTooltipStyleClass = input('');
  readonly triggerTooltipDelay = input(300);

  protected readonly primaryColors = PRIMARY_COLORS;
  protected readonly surfaceColors = SURFACE_COLORS;

  protected readonly currentPrimaryKey = this.themeService.primaryColorKey;
  protected readonly currentSurfaceKey = this.themeService.surfaceColorKey;

  private readonly panelRef = viewChild<ElementRef<HTMLElement>>('panel');

  protected readonly isPanelOpen = signal(false);

  protected readonly pickerButtonClass = computed(() => {
    return this.joinClasses('theme-picker-trigger', 'icon-btn', this.triggerClass(), this.isPanelOpen() ? 'theme-picker-trigger--active' : '');
  });

  private triggerElement: HTMLElement | null = null;
  private panelVisible = false;

  private readonly viewportMargin = 12;
  private readonly panelGap = 8;
  private readonly arrowMinOffset = 14;

  private readonly scheduler = new NativeOverlayScheduler(() => this.positionPanel());

  private readonly repositionPanel = (): void => {
    this.schedulePanelPosition();
  };

  private readonly onOutsidePointerDown = (event: PointerEvent): void => {
    if (!this.panelVisible || this.isEventInsidePicker(event)) {
      return;
    }

    this.markPanelAsClosing();
    this.getPanelElement()?.hidePopover();
  };

  private readonly onEscapeKeyDown = (event: KeyboardEvent): void => {
    if (this.panelVisible && event.key === 'Escape') {
      this.markPanelAsClosing();
      this.getPanelElement()?.hidePopover();
    }
  };

  constructor() {
    this.destroyRef.onDestroy(() => {
      this.cleanupPanelRuntime();
    });
  }

  protected toggle(panel: HTMLElement, event: MouseEvent): void {
    this.triggerElement = this.resolveTriggerElement(event);

    if (this.panelVisible) {
      this.markPanelAsClosing();
    }

    panel.togglePopover();
  }

  /** El evento `toggle` nativo de [popover] reemplaza a (onShow)/(onHide) de p-popover. */
  protected onPanelToggle(event: ToggleEvent): void {
    if (event.newState === 'open') {
      this.onPanelShow();
    } else {
      this.onPanelHide();
    }
  }

  private onPanelShow(): void {
    this.isPanelOpen.set(true);
    this.panelVisible = true;

    this.addRuntimeListeners();
    this.schedulePanelPosition();
  }

  private onPanelHide(): void {
    this.isPanelOpen.set(false);
    this.panelVisible = false;
    this.triggerElement = null;

    this.cleanupPanelRuntime();
    this.resetPanelPosition();
  }

  protected selectPrimary(key: string, panel: HTMLElement): void {
    this.themeService.applyColor(key);
    this.markPanelAsClosing();
    panel.hidePopover();
  }

  protected selectSurface(key: string): void {
    this.themeService.applySurface(key);
  }

  private markPanelAsClosing(): void {
    this.isPanelOpen.set(false);
    this.panelVisible = false;

    this.cleanupPanelRuntime();
  }

  private schedulePanelPosition(): void {
    if (!this.panelVisible) {
      return;
    }

    this.scheduler.schedule();
  }

  private positionPanel(): void {
    const panel = this.getPanelElement();
    const trigger = this.triggerElement;

    if (!panel || !trigger) {
      return;
    }

    const bounds = visibleBounds(trigger);

    // El scroll de un contenedor puede sacar el disparador de vista: el panel no se queda flotando sin ancla ni pegado a la ventana.
    if (isAnchorOutOfView(trigger, bounds)) {
      this.markPanelAsClosing();
      panel.hidePopover();
      return;
    }

    const triggerRect = trigger.getBoundingClientRect();
    const panelWidth = panel.offsetWidth;
    const panelHeight = panel.offsetHeight;
    const viewportWidth = this.document.documentElement.clientWidth;
    const viewportHeight = this.document.documentElement.clientHeight;
    const config = { viewportMargin: this.viewportMargin, panelGap: this.panelGap, arrowMinOffset: this.arrowMinOffset, arrowOffsetX: 0, offsetX: 0, offsetY: 0 };

    // Centrado en el disparador y solo se corre lo justo para verse: la flecha siempre apunta a su centro, sin correcciones a mano por layout.
    const placement = resolvePopoverPlacement('bottom', triggerRect, panelWidth, panelHeight, viewportWidth, viewportHeight, config, bounds);
    const layout = getPopoverPanelLayout({ placement, triggerRect, panelWidth, panelHeight, viewportWidth, viewportHeight }, config);

    panel.dataset['placement'] = placement;
    this.applyPanelPosition(panel, layout.left, layout.top, layout.arrowX ?? panelWidth / 2);
  }

  private applyPanelPosition(panel: HTMLElement, left: number, top: number, arrowX: number): void {
    panel.style.setProperty('position', 'fixed', 'important');
    panel.style.setProperty('top', `${top}px`, 'important');
    panel.style.setProperty('left', `${left}px`, 'important');
    panel.style.setProperty('right', 'auto', 'important');
    panel.style.setProperty('bottom', 'auto', 'important');
    panel.style.setProperty('transform', 'none', 'important');
    panel.style.setProperty('margin-top', '0', 'important');
    panel.style.setProperty('--color-picker-arrow-x', `${arrowX}px`);

    panel.dataset['positioned'] = 'true';
  }

  private resetPanelPosition(): void {
    const panel = this.getPanelElement();

    if (!panel) {
      return;
    }

    for (const property of ['position', 'top', 'left', 'right', 'bottom', 'transform', 'margin-top', '--color-picker-arrow-x']) {
      panel.style.removeProperty(property);
    }

    delete panel.dataset['positioned'];
    delete panel.dataset['placement'];
  }

  private isEventInsidePicker(event: Event): boolean {
    return isEventInsideOverlay(event, this.getPanelElement(), this.triggerElement);
  }

  private resolveTriggerElement(event: MouseEvent): HTMLElement | null {
    return resolveOverlayTriggerElement(event);
  }

  private addRuntimeListeners(): void {
    addNativeOverlayListeners(this.document, { reposition: this.repositionPanel, onOutsidePointerDown: this.onOutsidePointerDown, onEscapeKeyDown: this.onEscapeKeyDown });
  }

  private removeRuntimeListeners(): void {
    removeNativeOverlayListeners(this.document, { reposition: this.repositionPanel, onOutsidePointerDown: this.onOutsidePointerDown, onEscapeKeyDown: this.onEscapeKeyDown });
  }

  private cleanupPanelRuntime(): void {
    this.scheduler.cancel();
    this.removeRuntimeListeners();
  }

  private getPanelElement(): HTMLElement | null {
    return this.panelRef()?.nativeElement ?? null;
  }

  private joinClasses(...classes: string[]): string {
    return classes
      .map((value) => value.trim())
      .filter(Boolean)
      .join(' ');
  }
}
