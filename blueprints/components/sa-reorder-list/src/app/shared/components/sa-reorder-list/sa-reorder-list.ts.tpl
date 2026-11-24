import { NgTemplateOutlet } from '@angular/common';
import { ChangeDetectionStrategy, Component, TemplateRef, ViewEncapsulation, input, output } from '@angular/core';
import { CdkDrag, CdkDragDrop, CdkDropList, moveItemInArray } from '@angular/cdk/drag-drop';

@Component({
  selector: 'sa-reorder-list',
  standalone: true,
  imports: [CdkDropList, CdkDrag, NgTemplateOutlet],
  templateUrl: './sa-reorder-list.html',
  styleUrl: './sa-reorder-list.css',
  encapsulation: ViewEncapsulation.None,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SaReorderList<T = unknown> {
  readonly items = input.required<T[]>();
  readonly itemTemplate = input.required<TemplateRef<unknown>>();
  readonly styleClass = input<string>('');
  /** Clave estable que permite a Angular mover el nodo correcto al soltar CDK. */
  readonly trackBy = input.required<(item: T) => unknown>();

  readonly reordered = output<T[]>();

  trackItem = (item: T): unknown => this.trackBy()(item);

  onDrop(event: CdkDragDrop<T[]>): void {
    if (event.previousIndex === event.currentIndex) return;

    const next = [...this.items()];
    moveItemInArray(next, event.previousIndex, event.currentIndex);
    this.reordered.emit(next);
  }
}
