<div class="as-tabs" role="tablist" [attr.aria-label]="label()" (keydown)="onKeydown($event)">
  @for (tab of tabs(); track tab.id) {
    <button
      type="button"
      class="as-tabs__tab"
      role="tab"
      [attr.data-tab]="tab.id"
      [class.as-tabs__tab--selected]="tab.id === selected()"
      [attr.aria-selected]="tab.id === selected()"
      [attr.tabindex]="tab.id === selected() ? 0 : -1"
      [disabled]="tab.disabled"
      (click)="select(tab)"
    >
      @if (tab.icon) {
        <as-icon [name]="tab.icon" [size]="16" />
      }
      <span>{{ tab.label }}</span>
      @if (tab.badge !== undefined && tab.badge !== '') {
        <span class="as-tabs__badge">{{ tab.badge }}</span>
      }
    </button>
  }
</div>
