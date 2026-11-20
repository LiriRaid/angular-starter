<div class="flex flex-col gap-6">
  <header>
    <h2 class="text-body-2-bold text-(--app-text-color)">Personalización de UI</h2>
    <p class="text-caption-2-regular text-(--app-text-subtle)">Estilos reutilizables para todos los componentes. Cambian en tiempo real, sin tocar código.</p>
  </header>

  @for (group of groups; track group.id) {
    <section class="flex flex-wrap items-center justify-between gap-3 border-t border-(--app-border-color) pt-4 first-of-type:border-t-0 first-of-type:pt-0">
      <div class="flex flex-col">
        <span class="text-caption-1-semibold text-(--app-text-color)">{{ group.label }}</span>
        <span class="text-caption-2-regular text-(--app-text-subtle)">{{ group.hint }}</span>
      </div>
      <div class="flex flex-wrap gap-1 rounded-xl border border-(--app-border-color) p-1" role="group" [attr.aria-label]="group.label">
        @for (option of group.options; track option.value) {
          <button type="button" class="rounded-lg px-3 py-1.5 text-caption-2-semibold" [class.bg-(--as-primary-color)]="group.current() === option.value" [class.text-(--as-primary-contrast-color)]="group.current() === option.value" [class.text-(--app-text-color)]="group.current() !== option.value" [attr.aria-pressed]="group.current() === option.value" (click)="group.choose(option.value)">{{ option.label }}</button>
        }
      </div>
    </section>
  }

  <section class="flex flex-col gap-3 border-t border-(--app-border-color) pt-4" aria-label="Vista previa">
    <span class="text-caption-1-semibold text-(--app-text-color)">Vista previa</span>
    <div class="flex flex-col gap-3 rounded-xl border border-(--app-border-color) bg-(--app-panel-muted-bg) p-4">
      <div class="flex flex-wrap items-center gap-2">
        <as-button size="small" label="Pequeño" />
        <as-button size="medium" label="Mediano" />
        <as-button size="large" label="Grande" />
        <as-button size="medium" severity="secondary" label="Secundario" />
        <as-button size="medium" variant="outlined" label="Contorno" />
      </div>
      <div class="flex flex-wrap items-center gap-3">
        <div class="rounded-lg bg-(--app-panel-bg) p-3 text-caption-1-medium text-(--app-text-color) shadow-sm">Tarjeta con radio y espaciado</div>
        <div class="rounded-2xl bg-(--app-panel-bg) p-4 text-caption-1-medium text-(--app-text-color) shadow-sm">Otra, más grande</div>
        <as-toggle [checked]="true" ariaLabel="Interruptor de ejemplo" />
      </div>
      <p class="text-caption-1-regular text-(--app-text-subtle)">El texto sigue el tamaño de fuente elegido.</p>
    </div>
  </section>
</div>
