import { DOCUMENT } from '@angular/common';
import { ChangeDetectionStrategy, Component, DestroyRef, ElementRef, TemplateRef, ViewEncapsulation, computed, inject, input, signal, viewChild } from '@angular/core';

import { PRIMARY_COLORS, SURFACE_COLORS } from '@core/theme/theme-palettes';
import { ThemeService } from '@core/theme/theme.service';
import { addNativeOverlayListeners, isEventInsideOverlay, NativeOverlayScheduler, removeNativeOverlayListeners, resolveOverlayTriggerElement } from '../../utils/native-overlay-dismiss';
import { AsButton } from '..';
import { clamp } from '../as-popover/as-popover.config';
import { AsTooltip } from '../as-tooltip/as-tooltip.directive';

@Component({
  selector: 'as-theme-color-picker',
  standalone: true,
  imports: [AsButton, AsTooltip],
  templateUrl: './as-theme-color-picker.html',
  styleUrl: './as-theme-color-picker.css',
  encapsulation: ViewEncapsulation.None,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AsThemeColorPicker {
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

    const triggerRect = trigger.getBoundingClientRect();
    const panelWidth = panel.offsetWidth;
    const panelHeight = panel.offsetHeight;

    const viewportWidth = this.document.documentElement.clientWidth;
    const viewportHeight = this.document.documentElement.clientHeight;

    const triggerCenterX = triggerRect.left + triggerRect.width / 2;

    const left = this.getPanelLeft({
      triggerCenterX,
      panelWidth,
      viewportWidth,
    });

    const top = this.getPanelTop({
      panel,
      triggerRect,
      panelHeight,
      viewportHeight,
    });

    const arrowX = this.clamp(triggerCenterX - left, this.arrowMinOffset, panelWidth - this.arrowMinOffset);

    this.applyPanelPosition(panel, left, top, arrowX);
  }

  private getPanelLeft(params: { triggerCenterX: number; panelWidth: number; viewportWidth: number }): number {
    const left = params.triggerCenterX - params.panelWidth / 2 + this.getVisualOffsetX();

    return this.clamp(left, this.viewportMargin, params.viewportWidth - params.panelWidth - this.viewportMargin);
  }

  private getPanelTop(params: { panel: HTMLElement; triggerRect: DOMRect; panelHeight: number; viewportHeight: number }): number {
    const belowTop = params.triggerRect.bottom + this.panelGap;
    const aboveTop = params.triggerRect.top - params.panelHeight - this.panelGap;

    if (belowTop + params.panelHeight > params.viewportHeight - this.viewportMargin && aboveTop >= this.viewportMargin) {
      params.panel.dataset['placement'] = 'top';
      return aboveTop;
    }

    params.panel.dataset['placement'] = 'bottom';

    return this.clamp(belowTop, this.viewportMargin, params.viewportHeight - params.panelHeight - this.viewportMargin);
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

  /** Corrección empírica: el trigger de este picker vive en el header, cuyo layout desplaza el
   *  botón lateralmente de forma distinta a ambos lados de este ancho de viewport (no hay una
   *  media query o breakpoint con nombre asociado — el valor se ajustó a mano contra el layout
   *  real hasta centrar la flecha bajo el botón en los dos anchos de prueba). Si el header
   *  cambia de layout, este valor puede necesitar recalibrarse. */
  private getVisualOffsetX(): number {
    const width = this.document.documentElement.clientWidth;

    return width >= 1557 ? 45 : -35;
  }

  private clamp(value: number, min: number, max: number): number {
    return clamp(value, min, max);
  }

  private joinClasses(...classes: string[]): string {
    return classes
      .map((value) => value.trim())
      .filter(Boolean)
      .join(' ');
  }
}
