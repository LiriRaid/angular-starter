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
 * A dialog on top of the page. It keeps focus inside, closes with Escape, locks the scroll of the
 * page and gives focus back to what opened it.
 *
 * ```html
 * <as-modal [(open)]="confirming" title="Delete customer">
 *   <p>This cannot be undone.</p>
 *   <ng-container asModalFooter>
 *     <as-button label="Cancel" variant="text" (clicked)="confirming = false" />
 *     <as-button label="Delete" severity="danger" (clicked)="remove()" />
 *   </ng-container>
 * </as-modal>
 * ```
 */
@Component({
  selector: 'as-modal',
  imports: [AsIcon],
  templateUrl: './as-modal.html',
  styleUrl: './as-modal.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AsModal {
  /** Two-way: `[(open)]="visible"`. */
  readonly open = model(false);
  readonly title = input<string>('');
  readonly size = input<'sm' | 'md' | 'lg'>('md');
  /** Shows the close button and lets Escape close the dialog. */
  readonly closable = input(true, { transform: booleanAttribute });
  readonly closeOnBackdrop = input(true, { transform: booleanAttribute });

  private readonly document = inject(DOCUMENT);
  private readonly panel = viewChild<ElementRef<HTMLElement>>('panel');
  private opener: HTMLElement | null = null;
  private locked = false;

  protected readonly titleId = `as-modal-title-${nextId++}`;

  constructor() {
    effect(() => {
      if (this.open()) this.onOpen();
      else this.onClose();
    });
    // A modal removed while it is open must not leave the page without scroll.
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
    // The dialog is drawn after this effect: focus it on the next turn.
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
