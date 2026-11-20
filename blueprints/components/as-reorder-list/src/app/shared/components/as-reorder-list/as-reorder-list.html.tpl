<ul class="as-reorder" role="list">
  @for (item of items(); track trackBy()(item); let index = $index; let last = $last) {
    <li
      class="as-reorder__row"
      [class.as-reorder__row--dragging]="dragging() === index"
      [class.as-reorder__row--over]="over() === index && dragging() !== index"
      draggable="true"
      (dragstart)="onDragStart($event, index)"
      (dragover)="onDragOver($event, index)"
      (drop)="onDrop($event, index)"
      (dragend)="onDragEnd()"
    >
      <button
        type="button"
        class="as-reorder__handle"
        aria-label="Move. Hold Alt and press the up or down arrow."
        (keydown)="onKeydown($event, index)"
      >
        <as-icon name="grip-vertical" [size]="18" />
      </button>
      <div class="as-reorder__content">
        <ng-container [ngTemplateOutlet]="itemTemplate()" [ngTemplateOutletContext]="{ $implicit: item, index: index }" />
      </div>
      <div class="as-reorder__buttons">
        <button type="button" class="as-reorder__move" aria-label="Move up" [disabled]="index === 0" (click)="move(index, index - 1)">
          <as-icon name="chevron-up" [size]="16" />
        </button>
        <button type="button" class="as-reorder__move" aria-label="Move down" [disabled]="last" (click)="move(index, index + 1)">
          <as-icon name="chevron-down" [size]="16" />
        </button>
      </div>
    </li>
  }
</ul>
