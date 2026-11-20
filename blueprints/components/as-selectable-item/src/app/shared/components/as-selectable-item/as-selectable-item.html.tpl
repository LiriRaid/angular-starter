<button
  type="button"
  class="as-selectable-item"
  [class.as-selectable-item--selected]="selected()"
  [class.as-selectable-item--dimmed]="dimmed()"
  [attr.aria-pressed]="selected()"
  [disabled]="disabled()"
  (click)="itemClick.emit()"
>
  <span class="as-selectable-item__text">
    <span class="as-selectable-item__title">{{ title() }}</span>
    @if (subtitle()) {
      <span class="as-selectable-item__subtitle">{{ subtitle() }}</span>
    }
  </span>
  <ng-content />
</button>
