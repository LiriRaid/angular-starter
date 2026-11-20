import { DOCUMENT } from '@angular/common';
import {
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  ElementRef,
  booleanAttribute,
  effect,
  inject,
  input,
  model,
  viewChild,
} from '@angular/core';
import { focusableElements, trapTabKey } from '../../utils/focus-trap';
import { AsIcon } from '../as-icon/as-icon';

let nextId = 0;

/**
 * A panel that slides in from the left or the right edge, for settings, filters or details. Like
 * the modal it keeps focus inside, closes with Escape and gives focus back to what opened it.
 *
 * ```html
 * <as-drawer [(open)]="filtersOpen" title="Filters" position="right">...</as-drawer>
 * ```
 */
@Component({
  selector: 'as-drawer',
  imports: [AsIcon],
  templateUrl: './as-drawer.html',
  styleUrl: './as-drawer.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AsDrawer {
  readonly open = model(false);
  readonly title = input<string>('');
  readonly position = input<'left' | 'right'>('right');
  /** Any CSS length. */
  readonly width = input<string>('24rem');
  readonly closable = input(true, { transform: booleanAttribute });
  readonly closeOnBackdrop = input(true, { transform: booleanAttribute });

  private readonly document = inject(DOCUMENT);
  private readonly panel = viewChild<ElementRef<HTMLElement>>('panel');
  private opener: HTMLElement | null = null;
  private locked = false;

  protected readonly titleId = `as-drawer-title-${nextId++}`;

  constructor() {
    effect(() => {
      if (this.open()) this.onOpen();
      else this.onClose();
    });
    inject(DestroyRef).onDestroy(() => {
      if (this.locked) this.document.body.style.overflow = '';
    });
  }

  protected close(): void {
    if (this.closable()) this.open.set(false);
  }

  protected onBackdropClick(): void {
    if (this.closeOnBackdrop()) this.close();
  }

  protected onKeydown(event: KeyboardEvent): void {
    if (event.key === 'Escape') {
      event.stopPropagation();
      this.close();
      return;
    }
    const panel = this.panel()?.nativeElement;
    if (panel) trapTabKey(event, panel);
  }

  private onOpen(): void {
    this.opener = this.document.activeElement as HTMLElement | null;
    this.document.body.style.overflow = 'hidden';
    this.locked = true;
    queueMicrotask(() => {
      const panel = this.panel()?.nativeElement;
      if (!panel) return;
      (focusableElements(panel)[0] ?? panel).focus();
    });
  }

  private onClose(): void {
    if (!this.locked) return;
    this.locked = false;
    this.document.body.style.overflow = '';
    this.opener?.focus?.();
    this.opener = null;
  }
}
