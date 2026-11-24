<section class="reports flex flex-col gap-6">
  <header>
    <h1 class="text-body-1-bold text-(--app-text-color)">Reports</h1>
    <p class="text-caption-1-regular text-(--app-text-subtle)">Sample data: replace these cards with the reports of your product.</p>
  </header>

  <div class="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
    @for (report of reports; track report.name) {
      <article class="flex flex-col gap-3 rounded-xl border border-(--app-border-color) p-4">
        <span class="flex size-10 items-center justify-center rounded-lg bg-(--app-badge-soft-bg) text-(--app-badge-soft-text)">
          <sa-icon name="FileText" size="20" />
        </span>
        <div>
          <h2 class="text-body-2-bold text-(--app-text-color)">{{ report.name }}</h2>
          <p class="text-caption-1-regular text-(--app-text-subtle)">{{ report.description }}</p>
        </div>
        <p class="text-caption-2-regular text-(--app-text-subtle)">Last run: {{ report.lastRun }}</p>
      </article>
    }
  </div>
</section>
