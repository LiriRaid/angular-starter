<div class="sa-tablist relative flex min-w-0" role="tablist" [attr.aria-label]="ariaLabel() || null">
  @if (showPrevButton()) {
    <button type="button" class="sa-tablist-nav-button sa-tablist-prev-button absolute top-0 left-0 z-2 inline-flex h-full w-(--sa-tabs-nav-size) min-w-(--sa-tabs-nav-size) cursor-pointer items-center justify-center p-0 text-(--app-text-color) before:absolute before:top-1/2 before:left-1/2 before:size-[2.375rem] before:-translate-1/2 before:rounded-full before:bg-(--sa-tabs-nav-knob)" aria-label="Anterior" (click)="scrollByPage(-1)">
      <sa-icon name="ChevronLeft" size="16" />
    </button>
  }

  <div class="sa-tablist-content min-w-0 flex-1 overflow-x-auto overflow-y-hidden scroll-px-(--sa-tabs-nav-size) [scrollbar-width:none] [&::-webkit-scrollbar]:hidden" (scroll)="onScroll()">
    <div class="sa-tablist-tab-list relative grid before:pointer-events-none before:absolute before:inset-x-0 before:top-0 before:bottom-2 before:z-0 before:rounded-2xl before:bg-[color-mix(in_srgb,var(--app-text-subtle)_6%,transparent)] w-max min-w-full auto-cols-[minmax(max-content,1fr)] grid-flow-col gap-1.5 px-1 pt-1 pb-3">
      @for (tab of tabs(); track tab.id) {
        <button type="button" role="tab" saRipple class="sa-tab relative inline-flex min-h-9 max-md:min-h-8 cursor-pointer items-center justify-center gap-2 overflow-hidden whitespace-nowrap rounded-xl bg-transparent px-3.5 max-md:px-3 py-2 text-(--app-text-subtle) transition-colors" [class.sa-tab--active]="tab.id === active()" [class.sa-tab--icon-only]="!tab.label" [attr.aria-selected]="tab.id === active()" [style.--sa-tab-color]="tab.color ?? null" [saTooltip]="tab.tooltip" tooltipPosition="bottom" [showDelay]="300" (click)="selectTab(tab, $event)">
          @if (tab.avatar; as av) {
            <sa-avatar class="shrink-0" [label]="av.label" [background]="av.background" [imageUrl]="av.iconUrl ?? null" [size]="22" shape="rounded" />
          } @else if (tab.icon) {
            <sa-icon class="shrink-0" [name]="tab.icon" size="18" />
          }
          @if (tab.label) {
            <span [class]="tabLabelClass()">{{ tab.label }}</span>
          }
          @if (tab.count !== undefined) {
            <span class="sa-tab-count text-caption-2-semibold inline-flex h-6 w-6 items-center justify-center rounded-full text-white tabular-nums" [class]="tab.countTone === 'danger' ? 'bg-(--app-status-busy)' : 'bg-(--color-primary-500)'">{{ tab.count }}</span>
          }
        </button>
      }
      <span class="sa-tablist-active-bar absolute bottom-1 z-1 h-0.5 bg-(--sa-primary-color)"></span>
    </div>
  </div>

  @if (showNextButton()) {
    <button type="button" class="sa-tablist-nav-button sa-tablist-next-button absolute top-0 right-0 z-2 inline-flex h-full w-(--sa-tabs-nav-size) min-w-(--sa-tabs-nav-size) cursor-pointer items-center justify-center p-0 text-(--app-text-color) before:absolute before:top-1/2 before:left-1/2 before:size-[2.375rem] before:-translate-1/2 before:rounded-full before:bg-(--sa-tabs-nav-knob)" aria-label="Siguiente" (click)="scrollByPage(1)">
      <sa-icon name="ChevronRight" size="16" />
    </button>
  }
</div>
