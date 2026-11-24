<nav class="flex w-full flex-none flex-col gap-3 rounded-2xl border border-(--app-border-color) bg-(--app-panel-bg) p-3 md:w-66 md:self-start" [attr.aria-label]="title()">
  <div class="flex flex-col gap-1 px-2 pt-1">
    <span class="text-body-2-medium text-(--app-text-color)">{{ title() }}</span>
    <p class="text-caption-2-regular text-(--app-text-muted)">{{ description() }} <ng-content select="[sectionNavAction]" /></p>
  </div>
  <div class="flex gap-1 overflow-x-auto md:flex-col md:overflow-visible">
    @for (item of items(); track item.id; let index = $index) {
      <button type="button" class="flex shrink-0 cursor-pointer items-center gap-2.5 whitespace-nowrap rounded-lg border-0 bg-transparent px-3 py-2 text-left text-(--app-text-subtle) transition-colors hover:bg-(--app-panel-muted-bg) hover:text-(--app-text-color) focus-visible:outline-2 focus-visible:outline-(--sa-primary-color) aria-[current=true]:bg-(--app-sidebar-footer-settings-bg) aria-[current=true]:text-(--sa-primary-color) md:w-full" [attr.aria-current]="item.id === current()?.id ? 'true' : null" (click)="active.set(item.id)">
        <sa-icon [name]="item.icon" [size]="16" />
        <span class="min-w-0 flex-1 truncate text-caption-1-medium">{{ item.title }}</span>
        <span data-section-number class="text-caption-2-regular tabular-nums text-(--app-text-subtle)" aria-hidden="true">{{ index + 1 }}</span>
      </button>
    }
  </div>
</nav>

<section class="flex min-w-0 flex-1 flex-col gap-4" [attr.aria-labelledby]="titleId">
  @if (current(); as section) {
    <header class="flex min-w-0 flex-wrap items-baseline justify-between gap-x-4 gap-y-1">
      <h2 [id]="titleId" class="text-subtitle-3-medium text-(--app-text-color)">{{ section.title }}</h2>
      @if (section.summary) {
        <span data-section-hint class="text-caption-2-regular text-(--app-text-muted)">{{ section.summary }}</span>
      }
    </header>
  }
  <div class="flex min-w-0 flex-col gap-3">
    <ng-content />
  </div>
  <footer class="flex min-w-0 flex-wrap items-center justify-end gap-3 border-t border-(--app-border-color) pt-4 empty:hidden">
    <ng-content select="[sectionNavFooter]" />
  </footer>
</section>
