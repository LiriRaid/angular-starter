<div class="as-tablist" role="tablist" [attr.aria-label]="ariaLabel() || null">
  @if (showPrevButton()) {
    <button type="button" class="as-tablist-nav-button as-tablist-prev-button" aria-label="Anterior" (click)="scrollByPage(-1)">
      <as-icon name="ChevronLeft" size="16" />
    </button>
  }

  <div class="as-tablist-content" (scroll)="onScroll()">
    <div class="as-tablist-tab-list">
      @for (tab of tabs(); track tab.id) {
        <button type="button" role="tab" asRipple class="as-tab relative inline-flex min-h-9 max-md:min-h-8 cursor-pointer items-center justify-center gap-2 overflow-hidden whitespace-nowrap rounded-xl bg-transparent px-3.5 max-md:px-3 py-2 text-(--app-text-subtle) transition-colors" [class.as-tab--active]="tab.id === active()" [class.as-tab--icon-only]="!tab.label" [attr.aria-selected]="tab.id === active()" [style.--as-tab-color]="tab.color ?? null" [asTooltip]="tab.tooltip" tooltipPosition="bottom" [showDelay]="300" (click)="selectTab(tab, $event)">
          @if (tab.avatar; as av) {
            <as-avatar class="shrink-0" [label]="av.label" [background]="av.background" [imageUrl]="av.iconUrl ?? null" [size]="22" textClass="text-[9px] font-bold" shape="rounded" />
          } @else if (tab.icon) {
            <as-icon class="shrink-0" [name]="tab.icon" size="18" />
          }
          @if (tab.label) {
            <span [class]="tabLabelClass()">{{ tab.label }}</span>
          }
          @if (tab.count !== undefined) {
            <span class="as-tab-count text-caption-2-semibold inline-flex h-6 w-6 items-center justify-center rounded-full text-white tabular-nums" [class]="tab.countTone === 'danger' ? 'bg-(--app-status-busy)' : 'bg-(--color-primary-500)'">{{ tab.count }}</span>
          }
        </button>
      }
      <span class="as-tablist-active-bar"></span>
    </div>
  </div>

  @if (showNextButton()) {
    <button type="button" class="as-tablist-nav-button as-tablist-next-button" aria-label="Siguiente" (click)="scrollByPage(1)">
      <as-icon name="ChevronRight" size="16" />
    </button>
  }
</div>
