import { DOCUMENT } from '@angular/common';
import { Directive, ElementRef, OnDestroy, inject, input } from '@angular/core';

export type AsTooltipPosition = 'top' | 'bottom' | 'left' | 'right';

const GAP_PX = 8;
let nextId = 0;

/**
 * A short text that appears next to an element on hover and on keyboard focus.
 *
 * ```html
 * <button asTooltip="Save changes">Save</button>
 * <button asTooltip="Delete" asTooltipPosition="bottom">...</button>
 * ```
 */
@Directive({
  selector: '[asTooltip]',
  host: {
    '(mouseenter)': 'show()',
    '(mouseleave)': 'hide()',
    '(focusin)': 'show()',
    '(focusout)': 'hide()',
    '(keydown.escape)': 'hide()',
    '[attr.aria-describedby]': 'tooltipId',
  },
})
export class AsTooltip implements OnDestroy {
  readonly text = input<string>('', { alias: 'asTooltip' });
  readonly position = input<AsTooltipPosition>('top', { alias: 'asTooltipPosition' });

  private readonly document = inject(DOCUMENT);
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef).nativeElement;
  private element: HTMLElement | null = null;

  protected readonly tooltipId = `as-tooltip-${nextId++}`;

  protected show(): void {
    const text = this.text();
    if (!text || this.element) return;

    const element = this.document.createElement('div');
    element.id = this.tooltipId;
    element.setAttribute('role', 'tooltip');
    element.className = 'as-tooltip';
    element.textContent = text;
    this.applyStyle(element);
    this.document.body.appendChild(element);
    this.element = element;
    this.place(element);
  }

  protected hide(): void {
    this.element?.remove();
    this.element = null;
  }

  ngOnDestroy(): void {
    this.hide();
  }

  /** The tooltip is styled inline so it needs no global stylesheet beyond the design tokens. */
  private applyStyle(element: HTMLElement): void {
    Object.assign(element.style, {
      position: 'fixed',
      zIndex: 'var(--as-z-tooltip, 1400)',
      maxWidth: '16rem',
      padding: '0.25rem 0.5rem',
      borderRadius: 'var(--as-radius-sm, 0.25rem)',
      background: 'var(--as-text, #171717)',
      color: 'var(--as-panel, #fff)',
      font: '500 0.75rem/1.4 var(--as-font-sans, system-ui, sans-serif)',
      pointerEvents: 'none',
      boxShadow: 'var(--as-shadow-md, 0 4px 12px rgba(0, 0, 0, 0.2))',
    });
  }

  private place(element: HTMLElement): void {
    const anchor = this.host.getBoundingClientRect();
    const tip = element.getBoundingClientRect();
    const viewport = this.document.defaultView;
    const width = viewport?.innerWidth ?? 0;
    const height = viewport?.innerHeight ?? 0;

    let top: number;
    let left: number;
    switch (this.position()) {
      case 'bottom':
        top = anchor.bottom + GAP_PX;
        left = anchor.left + (anchor.width - tip.width) / 2;
        break;
      case 'left':
        top = anchor.top + (anchor.height - tip.height) / 2;
        left = anchor.left - tip.width - GAP_PX;
        break;
      case 'right':
        top = anchor.top + (anchor.height - tip.height) / 2;
        left = anchor.right + GAP_PX;
        break;
      default:
        top = anchor.top - tip.height - GAP_PX;
        left = anchor.left + (anchor.width - tip.width) / 2;
    }
    // Keep it inside the window.
    element.style.top = `${Math.max(4, Math.min(top, height - tip.height - 4))}px`;
    element.style.left = `${Math.max(4, Math.min(left, width - tip.width - 4))}px`;
  }
}
