<section class="rounded-xl border border-(--app-border-color) p-4">
  <h2 class="text-body-2-bold text-(--app-text-color) mb-3">General</h2>
  <dl class="grid gap-3 sm:grid-cols-[12rem_1fr]">
    <dt class="text-caption-1-semibold text-(--app-text-subtle)">Organization</dt>
    <dd class="text-caption-1-medium text-(--app-text-color)">{{ organization() }}</dd>
    <dt class="text-caption-1-semibold text-(--app-text-subtle)">Language</dt>
    <dd class="text-caption-1-medium text-(--app-text-color)">{{ language() }}</dd>
    <dt class="text-caption-1-semibold text-(--app-text-subtle)">Time zone</dt>
    <dd class="text-caption-1-medium text-(--app-text-color)">{{ timeZone() }}</dd>
  </dl>
</section>
