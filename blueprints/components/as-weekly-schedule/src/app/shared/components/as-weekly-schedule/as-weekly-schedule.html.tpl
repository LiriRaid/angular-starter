<div class="flex flex-col gap-3">
  <div class="flex flex-wrap items-center justify-between gap-2">
    <span class="text-caption-1-regular text-(--app-text-muted)">{{ label() }}</span>
    <div class="flex flex-wrap items-center gap-1.5">
      <span class="text-caption-2-regular text-(--app-text-subtle)">Aplicar:</span>
      <as-button type="button" label="L-V 8-17" variant="outlined" severity="secondary" size="small" styleClass="text-caption-2-bold" (onClick)="applyPreset('lv-8-17')" />
      <as-button type="button" label="L-S 9-18" variant="outlined" severity="secondary" size="small" styleClass="text-caption-2-bold" (onClick)="applyPreset('ls-9-18')" />
      <as-button type="button" label="Todos 9-23" variant="outlined" severity="secondary" size="small" styleClass="text-caption-2-bold" (onClick)="applyPreset('all-9-23')" />
      <as-button type="button" label="24 horas" variant="outlined" severity="secondary" size="small" styleClass="text-caption-2-bold" (onClick)="applyPreset('24h')" />
    </div>
  </div>

  <div class="flex flex-col rounded-2xl border border-(--app-border-color)">
    @for (day of days(); track day.key; let i = $index; let last = $last) {
      <div class="flex flex-wrap items-center gap-3 border-(--app-border-color) p-3" [class.border-b]="!last">
        <as-toggle [checked]="day.enabled" [ariaLabel]="'Activar ' + day.label" (changed)="toggleDay(i)" />
        <span class="w-24 shrink-0 text-caption-1-regular text-(--app-text-color)">{{ day.label }}</span>

        @if (day.enabled) {
          <input type="time" class="as-weekly-schedule-time-input rounded-lg border border-(--app-border-color) px-2 py-1.5 text-caption-1-regular" [attr.aria-label]="'Hora de inicio del ' + day.label" [value]="day.start" (change)="onTimeChange(i, 'start', $event)" />
          <span class="text-caption-1-regular text-(--app-text-subtle)" aria-hidden="true">–</span>
          <input type="time" class="as-weekly-schedule-time-input rounded-lg border border-(--app-border-color) px-2 py-1.5 text-caption-1-regular" [attr.aria-label]="'Hora de cierre del ' + day.label" [value]="day.end" (change)="onTimeChange(i, 'end', $event)" />
          <as-button type="button" icon="Copy" iconSize="14" variant="text" severity="secondary" size="small" (onClick)="copyDay(i)" ariaLabel="Copiar horario a los demás días activos" />
        } @else {
          <span class="text-caption-1-regular text-(--app-text-subtle)">Cerrado</span>
        }
      </div>
    }
  </div>

  <div class="flex flex-wrap items-center justify-between gap-2 rounded-xl bg-(--app-accent-soft-bg) px-3 py-2">
    <span class="text-caption-1-regular text-(--app-text-color)">{{ summary() }}</span>
    <span class="text-caption-1-bold text-(--as-primary-color)">{{ weeklyHours() }} h/semana</span>
  </div>
</div>
