import { NgTemplateOutlet } from '@angular/common';
import {
  ChangeDetectionStrategy,
  Component,
  TemplateRef,
  input,
  output,
  signal,
} from '@angular/core';
import { AsIcon } from '../as-icon/as-icon';

/**
 * A list the user can reorder by dragging, or with the buttons and the Alt + arrow keys. You draw
 * each item with a template and get the new order in `reordered`.
 *
 * ```html
 * <as-reorder-list [items]="steps" [itemTemplate]="step" [trackBy]="byId" (reordered)="steps = $event" />
 * <ng-template #step let-item let-index="index">{{ index + 1 }}. {{ item.name }}</ng-template>
 * ```
 */
@Component({
  selector: 'as-reorder-list',
  imports: [AsIcon, NgTemplateOutlet],
  templateUrl: './as-reorder-list.html',
  styleUrl: './as-reorder-list.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AsReorderList<T> {
  readonly items = input.required<readonly T[]>();
  /** How an item is drawn. It receives the item and its `index`. */
  readonly itemTemplate = input.required<TemplateRef<unknown>>();
  /** A stable identity for each item, so rows are reused when the order changes. */
  readonly trackBy = input.required<(item: T) => unknown>();

  /** The items in their new order. */
  readonly reordered = output<T[]>();

  protected readonly dragging = signal<number | null>(null);
  protected readonly over = signal<number | null>(null);

  protected move(from: number, to: number): void {
    const list = [...this.items()];
    if (to < 0 || to >= list.length || from === to) return;
    const [item] = list.splice(from, 1);
    if (item === undefined) return;
    list.splice(to, 0, item);
    this.reordered.emit(list);
  }

  protected onKeydown(event: KeyboardEvent, index: number): void {
    if (!event.altKey || (event.key !== 'ArrowUp' && event.key !== 'ArrowDown')) return;
    event.preventDefault();
    this.move(index, index + (event.key === 'ArrowUp' ? -1 : 1));
  }

  protected onDragStart(event: DragEvent, index: number): void {
    this.dragging.set(index);
    event.dataTransfer?.setData('text/plain', String(index));
    if (event.dataTransfer) event.dataTransfer.effectAllowed = 'move';
  }

  protected onDragOver(event: DragEvent, index: number): void {
    if (this.dragging() === null) return;
    event.preventDefault();
    this.over.set(index);
  }

  protected onDrop(event: DragEvent, index: number): void {
    event.preventDefault();
    const from = this.dragging();
    if (from !== null) this.move(from, index);
    this.onDragEnd();
  }

  protected onDragEnd(): void {
    this.dragging.set(null);
    this.over.set(null);
  }
}
