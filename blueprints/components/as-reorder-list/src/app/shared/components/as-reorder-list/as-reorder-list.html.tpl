<div cdkDropList class="as-reorder-list" [class]="styleClass()" (cdkDropListDropped)="onDrop($event)">
  @for (item of items(); track trackItem(item); let i = $index) {
    <div cdkDrag class="as-reorder-item">
      <ng-container [ngTemplateOutlet]="itemTemplate()" [ngTemplateOutletContext]="{ $implicit: item, index: i }" />
    </div>
  }
</div>
