<section class="dashboard flex flex-col gap-6">
  <header>
    <h1 class="text-body-1-bold text-(--app-text-color)">Dashboard</h1>
    <p class="text-caption-1-regular text-(--app-text-subtle)">Sample data: replace this page with the summary of your product.</p>
  </header>

  <div class="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
    @for (metric of metrics; track metric.label) {
      <article class="flex items-center gap-3 rounded-xl border border-(--app-border-color) p-4">
        <span class="flex size-11 shrink-0 items-center justify-center rounded-lg bg-(--app-badge-soft-bg) text-(--app-badge-soft-text)">
          <sa-icon [name]="metric.icon" size="22" />
        </span>
        <div class="min-w-0">
          <p class="text-body-1-bold text-(--app-text-color)">{{ metric.value }}</p>
          <p class="text-caption-2-regular text-(--app-text-subtle)">{{ metric.label }}</p>
          <p class="text-caption-2-semibold text-(--app-status-online)">{{ metric.trend }}</p>
        </div>
      </article>
    }
  </div>

  <section class="rounded-xl border border-(--app-border-color) p-4">
    <h2 class="text-body-2-bold text-(--app-text-color) mb-3">Latest activity</h2>
    <ul class="flex flex-col divide-y divide-(--app-border-color)">
      @for (item of activity; track item.title) {
        <li class="flex items-center gap-3 py-3">
          <sa-icon class="text-(--app-text-subtle)" [name]="item.icon" size="18" />
          <div class="min-w-0 flex-1">
            <p class="text-caption-1-semibold text-(--app-text-color)">{{ item.title }}</p>
            <p class="text-caption-2-regular text-(--app-text-subtle)">{{ item.detail }}</p>
          </div>
          <time class="text-caption-2-regular text-(--app-text-subtle)">{{ item.time }}</time>
        </li>
      }
    </ul>
  </section>
</section>
