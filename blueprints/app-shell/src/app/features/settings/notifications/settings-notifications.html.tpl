<section class="rounded-xl border border-(--app-border-color) p-4">
  <h2 class="text-body-2-bold text-(--app-text-color) mb-3">Notifications</h2>
  <ul class="flex flex-col gap-3">
    <li class="flex items-center justify-between gap-3">
      <span class="text-caption-1-medium text-(--app-text-color)">Email notifications</span>
      <as-toggle [checked]="email()" (changed)="email.set($event)" ariaLabel="Email notifications" />
    </li>
    <li class="flex items-center justify-between gap-3">
      <span class="text-caption-1-medium text-(--app-text-color)">Weekly summary</span>
      <as-toggle [checked]="weeklySummary()" (changed)="weeklySummary.set($event)" ariaLabel="Weekly summary" />
    </li>
  </ul>
</section>
