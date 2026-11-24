<div cdkDropList class="sa-reorder-list" [class]="styleClass()" (cdkDropListDropped)="onDrop($event)">
  @for (item of items(); track trackItem(item); let i = $index) {
    <div cdkDrag class="sa-reorder-item">
      <ng-container [ngTemplateOutlet]="itemTemplate()" [ngTemplateOutletContext]="{ $implicit: item, index: i }" />
    </div>
  }
</div>
