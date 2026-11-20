<ng-content select="[asPopoverTrigger]" />

@if (open()) {
  <div class="as-popover__panel as-popover__panel--{{ placement() }} as-animate-fade-in">
    @if (items().length > 0) {
      <ul class="as-popover__menu" role="menu">
        @for (item of items(); track item.id) {
          <li role="none">
            <button
              type="button"
              class="as-popover__item"
              role="menuitem"
              [class.as-popover__item--danger]="item.danger"
              [disabled]="item.disabled"
              (click)="choose(item)"
            >
              @if (item.icon) {
                <as-icon [name]="item.icon" [size]="16" />
              }
              <span>{{ item.label }}</span>
            </button>
          </li>
        }
      </ul>
    } @else {
      <div class="as-popover__content"><ng-content /></div>
    }
  </div>
}
