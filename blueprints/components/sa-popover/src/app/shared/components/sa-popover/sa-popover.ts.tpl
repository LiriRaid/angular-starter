import { DOCUMENT } from '@angular/common';
import { booleanAttribute, ChangeDetectionStrategy, Component, DestroyRef, ElementRef, TemplateRef, ViewEncapsulation, inject, input, output, signal, viewChild } from '@angular/core';

import { NativeOverlayRuntime, resolveOverlayTriggerElement } from '../../utils/native-overlay-dismiss';
import { isAnchorOutOfView, visibleBounds } from '@shared/utils/panel-placement';
import { SaButton } from '../sa-button/sa-button';
import { SaTooltip } from '../sa-tooltip/sa-tooltip.directive';
import { getPopoverPanelLayout, getPopoverSubPanelAnchor, resolvePopoverPlacement } from './sa-popover.config';
import type { SaPopoverActionItem, SaPopoverButtonVariant, SaPopoverPosition, PopoverPanelLayout, SubPanelAnchor } from './sa-popover.entity';

export type { SaPopoverActionItem, SaPopoverButtonVariant, SaPopoverPosition, SubPanelAnchor } from './sa-popover.entity';

@Component({
  selector: 'sa-popover',
  standalone: true,
  imports: [SaButton, SaTooltip],
  templateUrl: './sa-popover.html',
  styleUrl: './sa-popover.css',
  encapsulation: ViewEncapsulation.None,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SaPopover {
  private readonly document = inject(DOCUMENT);
  private readonly destroyRef = inject(DestroyRef);

  /** `popover="manual"` nativo — top-layer real (sin overflow/z-index clipping, sin mover el
   *  nodo a <body>), pero con el cierre por fuera/Escape 100% manejado por nuestra cuenta (ver
   *  overlayRuntime, en shared/utils/native-overlay-dismiss.ts) en vez del light-dismiss
   *  automático de "auto", que compite con nuestro propio toggle() en el trigger. */
  private readonly popoverPanel = viewChild<ElementRef<HTMLElement>>('popoverPanel');

  readonly actions = input(false, { transform: booleanAttribute });
  readonly items = input<readonly SaPopoverActionItem[]>([]);
  readonly position = input<SaPopoverPosition>('top');

  readonly triggerIcon = input<string | null>('EllipsisVertical');
  readonly triggerIconSize = input<string | number>('16');
  readonly triggerSize = input<'small' | 'medium' | 'high'>('high');
  readonly triggerVariant = input<SaPopoverButtonVariant>('outlined');
  readonly triggerStyleClass = input('');
  readonly triggerActiveClass = input('');
  readonly triggerAriaLabel = input('Abrir popover');

  readonly optionVariant = input<SaPopoverButtonVariant>('outlined');
  readonly optionStyleClass = input('text-caption-1-medium');

  readonly triggerTooltip = input<string | TemplateRef<unknown> | null>('');
  readonly triggerTooltipPosition = input<'top' | 'bottom' | 'left' | 'right'>('bottom');
  readonly triggerTooltipStyleClass = input('');
  readonly triggerTooltipDelay = input(300);

  readonly popoverStyleClass = input('');
  readonly closeOnSelect = input(true);
  readonly offsetX = input(0);
  readonly offsetY = input(0);
  readonly matchTriggerWidth = input(false, { transform: booleanAttribute });

  readonly actionSelected = output<string>();

  readonly isOpen = signal(false);

  get panelElement(): HTMLElement | undefined {
    return this.getPanelElement();
  }

  private triggerElement: HTMLElement | null = null;
  private popoverVisible = false;

  private readonly viewportMargin = 12;
  private readonly panelGap = 8;
  private readonly arrowMinOffset = 14;

  private readonly overlayRuntime = new NativeOverlayRuntime(this.document, {
    getPanelElement: () => this.getPanelElement(),
    getTriggerElement: () => this.triggerElement,
    isVisible: () => this.popoverVisible,
    onDismiss: () => {
      this.markPopoverAsClosing();
      this.getPanelElement()?.hidePopover();
    },
    onReposition: () => this.positionPopover(),
  });

  constructor() {
    this.destroyRef.onDestroy(() => {
      this.overlayRuntime.cleanup();
    });
  }

  toggle(event: MouseEvent): void {
    this.triggerElement = this.resolveTriggerElement(event);

    if (this.popoverVisible) {
      this.markPopoverAsClosing();
    }

    this.getPanelElement()?.togglePopover();
  }

  show(event: MouseEvent): void {
    this.triggerElement = this.resolveTriggerElement(event);
    const panel = this.getPanelElement();
    if (panel && !panel.matches(':popover-open')) panel.showPopover();
  }

  hide(): void {
    this.markPopoverAsClosing();
    this.getPanelElement()?.hidePopover();
  }

  getSubPanelAnchor(anchorEl?: HTMLElement, gap = 6): SubPanelAnchor | null {
    const panel = this.getPanelElement();
    if (!panel) return null;

    const panelRect = panel.getBoundingClientRect();
    const anchorRect = anchorEl?.getBoundingClientRect() ?? panelRect;
    const viewportWidth = this.document.documentElement.clientWidth;
    const viewportHeight = this.document.documentElement.clientHeight;

    return getPopoverSubPanelAnchor(this.position(), panelRect, anchorRect, viewportWidth, viewportHeight, gap);
  }

  /** El evento `toggle` nativo de [popover] reemplaza a (onShow)/(onHide) de p-popover. */
  protected onPopoverToggle(event: ToggleEvent): void {
    if (event.newState === 'open') {
      this.onPopoverShow();
    } else {
      this.onPopoverHide();
    }
  }

  private onPopoverShow(): void {
    this.isOpen.set(true);
    this.popoverVisible = true;
    this.overlayRuntime.addListeners();
    this.overlayRuntime.scheduleReposition();
  }

  private onPopoverHide(): void {
    this.isOpen.set(false);
    this.popoverVisible = false;
    this.triggerElement = null;
    this.overlayRuntime.cleanup();
    this.resetPopoverPosition();
  }

  protected onActionClick(action: SaPopoverActionItem): void {
    if (action.disabled) return;

    this.actionSelected.emit(action.id);

    if (this.closeOnSelect()) {
      this.hide();
    }
  }

  protected actionVariant(action: SaPopoverActionItem): SaPopoverButtonVariant {
    return action.variant ?? this.optionVariant();
  }

  protected triggerClass(): string {
    return [this.triggerStyleClass(), this.isOpen() ? this.triggerActiveClass() : ''].filter(Boolean).join(' ');
  }

  protected panelClass(): string {
    return ['sa-popover', 'sa-popover--repositioned', this.actions() ? 'sa-popover--actions' : '', this.popoverStyleClass()].filter(Boolean).join(' ');
  }

  protected actionClass(action: SaPopoverActionItem): string {
    return ['sa-popover-option', this.optionStyleClass(), action.styleClass].filter(Boolean).join(' ');
  }

  protected trackAction(_: number, action: SaPopoverActionItem): string {
    return action.id;
  }

  private markPopoverAsClosing(): void {
    this.isOpen.set(false);
    this.popoverVisible = false;
    this.overlayRuntime.cleanup();
  }

  private positionPopover(): void {
    const panel = this.getPanelElement();
    const trigger = this.triggerElement;

    if (!panel || !trigger) return;

    const triggerRect = trigger.getBoundingClientRect();
    const bounds = visibleBounds(trigger);

    // El scroll de un contenedor (ej. el hilo de mensajes) puede sacar el ancla de vista: el panel no se queda flotando sin ancla.
    if (isAnchorOutOfView(trigger, bounds)) {
      this.hide();
      return;
    }

    if (this.matchTriggerWidth()) {
      panel.style.setProperty('width', `${triggerRect.width}px`, 'important');
    }

    const panelWidth = panel.offsetWidth;
    const panelHeight = panel.offsetHeight;
    const viewportWidth = this.document.documentElement.clientWidth;
    const viewportHeight = this.document.documentElement.clientHeight;
    const placement = resolvePopoverPlacement(this.position(), triggerRect, panelWidth, panelHeight, viewportWidth, viewportHeight, this.positionConfig(), bounds);

    const styles = getPopoverPanelLayout({ placement, triggerRect, panelWidth, panelHeight, viewportWidth, viewportHeight }, this.positionConfig());

    this.applyPopoverPosition(panel, styles);
  }

  private applyPopoverPosition(panel: HTMLElement, styles: PopoverPanelLayout): void {
    panel.style.setProperty('position', 'fixed', 'important');
    panel.style.setProperty('top', styles.bottom === null ? `${styles.top}px` : 'auto', 'important');
    panel.style.setProperty('left', `${styles.left}px`, 'important');
    panel.style.setProperty('right', 'auto', 'important');
    panel.style.setProperty('bottom', styles.bottom === null ? 'auto' : `${styles.bottom}px`, 'important');
    panel.style.setProperty('transform', 'none', 'important');
    panel.style.setProperty('margin-top', '0', 'important');

    if (styles.arrowX !== null) {
      panel.style.setProperty('--sa-popover-arrow-x', `${styles.arrowX}px`);
    } else {
      panel.style.removeProperty('--sa-popover-arrow-x');
    }

    if (styles.arrowY !== null) {
      panel.style.setProperty('--sa-popover-arrow-y', `${styles.arrowY}px`);
    } else {
      panel.style.removeProperty('--sa-popover-arrow-y');
    }

    panel.dataset['arrowPosition'] = styles.arrowPosition;
    panel.dataset['positioned'] = 'true';
  }

  private resetPopoverPosition(): void {
    const panel = this.getPanelElement();

    if (!panel) return;

    for (const property of ['position', 'top', 'left', 'right', 'bottom', 'width', 'transform', 'margin-top', '--sa-popover-arrow-x', '--sa-popover-arrow-y']) {
      panel.style.removeProperty(property);
    }

    delete panel.dataset['arrowPosition'];
    delete panel.dataset['positioned'];
  }

  private getPanelElement(): HTMLElement | undefined {
    return this.popoverPanel()?.nativeElement;
  }

  private resolveTriggerElement(event: MouseEvent): HTMLElement | null {
    return resolveOverlayTriggerElement(event);
  }

  private positionConfig() {
    return {
      viewportMargin: this.viewportMargin,
      panelGap: this.panelGap,
      arrowMinOffset: this.arrowMinOffset,
      arrowOffsetX: 0,
      offsetX: this.offsetX(),
      offsetY: this.offsetY(),
    };
  }
}
