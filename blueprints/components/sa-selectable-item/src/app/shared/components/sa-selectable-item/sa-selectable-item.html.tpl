<button type="button" class="flex w-full min-w-0 cursor-pointer items-center justify-between gap-3 rounded-xl border px-3 py-2.5 text-left transition-colors focus-visible:outline-2 focus-visible:outline-(--sa-primary-color)" [attr.aria-pressed]="selected()" [style.borderColor]="selected() ? accentColor() : 'var(--app-border-color)'" [style.background]="selected() ? 'color-mix(in srgb, ' + accentColor() + ' 10%, transparent)' : ''" [class.opacity-60]="dimmed()" (click)="itemClick.emit()">
  <div class="flex min-w-0 flex-col gap-0.5">
    <span class="truncate text-caption-1-bold text-(--app-text-color)">{{ title() }}</span>
    @if (subtitle()) {
      <span class="truncate text-caption-2-regular text-(--app-text-subtle)">{{ subtitle() }}</span>
    }
  </div>
  @if (selected()) {
    <sa-icon name="Check" size="18" [color]="accentColor()" />
  }
</button>
