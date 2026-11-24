import { DOCUMENT } from '@angular/common';
import { ComponentRef, DestroyRef, Directive, ElementRef, TemplateRef, ViewContainerRef, inject, input } from '@angular/core';

import { Tooltip } from './as-tooltip';

export type AsTooltipPosition = 'top' | 'bottom' | 'left' | 'right';

const FALLBACK_ORDER: Record<AsTooltipPosition, AsTooltipPosition[]> = {
  top: ['top', 'bottom', 'right', 'left'],
  bottom: ['bottom', 'top', 'right', 'left'],
  left: ['left', 'right', 'top', 'bottom'],
  right: ['right', 'left', 'top', 'bottom'],
};

/**
 * La caja a la que se ancla el tooltip. Un host `display: inline` (un componente como `as-button`, un
 * elemento personalizado) solo reporta la caja de su línea de texto aunque lo que pinta dentro sea más alto
 * (el botón con su relleno): por eso `top` y `bottom` quedaban sobre el texto mientras `left` y `right`, que
 * solo miran el ancho, caían bien fuera del botón. Se ancla a la unión del host con lo que pinta dentro.
 */
export function anchorRectOf(host: HTMLElement): DOMRect {
  const rect = host.getBoundingClientRect();
  if (host.children.length === 0 || getComputedStyle(host).display !== 'inline') return rect;

  let { top, bottom, left, right } = rect;
  for (const child of Array.from(host.children)) {
    const childRect = child.getBoundingClientRect();
    // A child with no box (display: none) reports all zeros: it is not part of what is seen.
    if (childRect.width === 0 && childRect.height === 0) continue;
    top = Math.min(top, childRect.top);
    bottom = Math.max(bottom, childRect.bottom);
    left = Math.min(left, childRect.left);
    right = Math.max(right, childRect.right);
  }
  return new DOMRect(left, top, right - left, bottom - top);
}

@Directive({
  selector: '[asTooltip]',
  standalone: true,
  host: {
    '(mouseenter)': 'onMouseEnter()',
    '(mouseleave)': 'onMouseLeave()',
    '(focus)': 'onFocus()',
    '(blur)': 'onBlur()',
    '(click)': 'onClick()',
  },
})
export class AsTooltip {
  readonly content = input<string | TemplateRef<unknown> | undefined | null>(undefined, { alias: 'asTooltip' });
  readonly tooltipPosition = input<AsTooltipPosition>('right');
  readonly tooltipStyleClass = input<string>('');
  readonly showDelay = input<number>(0);

  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);
  private readonly viewContainerRef = inject(ViewContainerRef);
  private readonly document = inject(DOCUMENT);
  private panel: ComponentRef<Tooltip> | null = null;
  private showTimer: ReturnType<typeof setTimeout> | null = null;
  /** La punta de la flecha toca el host, igual que el Tooltip de PrimeNG. */
  private readonly gap = 0;
  private readonly viewportMargin = 8;

  constructor() {
    inject(DestroyRef).onDestroy(() => this.destroyPanel());
  }

  onMouseEnter(): void { this.scheduleShow(); }
  onMouseLeave(): void { this.cancelAndHide(); }
  onFocus(): void { this.scheduleShow(); }
  onBlur(): void { this.cancelAndHide(); }
  onClick(): void { this.cancelAndHide(); }

  private scheduleShow(): void {
    if (!this.content()) return;
    this.clearTimer();
    this.showTimer = setTimeout(() => this.show(), this.showDelay());
  }

  private cancelAndHide(): void {
    this.clearTimer();
    this.destroyPanel();
  }

  private clearTimer(): void {
    if (this.showTimer === null) return;
    clearTimeout(this.showTimer);
    this.showTimer = null;
  }

  private show(): void {
    if (this.panel) return;
    const content = this.content();
    if (!content) return;

    const panel = this.viewContainerRef.createComponent(Tooltip);
    panel.setInput('content', content);
    panel.changeDetectorRef.detectChanges();

    const panelElement = panel.location.nativeElement as HTMLElement;
    // popover="manual": sin esto, un tooltip sobre un elemento dentro de OTRO panel nativo
    // (select, popover, color picker, etc.) queda tapado por ese panel — los elementos
    // [popover] se pintan en el "top layer" del navegador, por encima de cualquier z-index
    // normal, así que un tooltip con z-index simple pierde contra ellos. Uniéndose también al
    // top layer, el tooltip gana por ser el más reciente en abrirse.
    panelElement.setAttribute('popover', 'manual');
    panelElement.style.position = 'fixed';
    panelElement.style.zIndex = '1100';
    panelElement.style.top = '-9999px';
    panelElement.style.left = '-9999px';
    panelElement.setAttribute('role', 'tooltip');
    this.document.body.appendChild(panelElement);
    if (typeof panelElement.showPopover === 'function') panelElement.showPopover();
    this.panel = panel;
    this.align();
  }

  private align(): void {
    const order = FALLBACK_ORDER[this.tooltipPosition()];
    for (let index = 0; index < order.length; index++) {
      this.applyPosition(order[index]);
      if (index === order.length - 1 || !this.isOutOfBounds()) return;
    }
  }

  private applyPosition(position: AsTooltipPosition): void {
    const panel = this.panel?.location.nativeElement as HTMLElement | undefined;
    if (!panel) return;

    panel.className = ['as-tooltip', `as-tooltip--${position}`, this.tooltipStyleClass()].filter(Boolean).join(' ');
    const hostRect = anchorRectOf(this.host.nativeElement);
    const panelRect = panel.getBoundingClientRect();
    let top = 0;
    let left = 0;

    switch (position) {
      case 'top':
        top = hostRect.top - panelRect.height - this.gap;
        left = hostRect.left + hostRect.width / 2 - panelRect.width / 2;
        break;
      case 'bottom':
        top = hostRect.bottom + this.gap;
        left = hostRect.left + hostRect.width / 2 - panelRect.width / 2;
        break;
      case 'left':
        top = hostRect.top + hostRect.height / 2 - panelRect.height / 2;
        left = hostRect.left - panelRect.width - this.gap;
        break;
      case 'right':
        top = hostRect.top + hostRect.height / 2 - panelRect.height / 2;
        left = hostRect.right + this.gap;
        break;
    }

    panel.style.top = `${top}px`;
    panel.style.left = `${left}px`;
  }

  private isOutOfBounds(): boolean {
    const panel = this.panel?.location.nativeElement as HTMLElement | undefined;
    if (!panel) return false;

    const rect = panel.getBoundingClientRect();
    const viewportWidth = this.document.documentElement.clientWidth;
    const viewportHeight = this.document.documentElement.clientHeight;
    return rect.left < this.viewportMargin || rect.top < this.viewportMargin || rect.right > viewportWidth - this.viewportMargin || rect.bottom > viewportHeight - this.viewportMargin;
  }

  private destroyPanel(): void {
    this.panel?.location.nativeElement.remove();
    this.panel?.destroy();
    this.panel = null;
  }
}
