<div class="flex flex-col gap-6">
  <section>
    <h2 class="text-body-2-bold text-(--app-text-color)">Diseño (Layout)</h2>
    <p class="mb-3 text-caption-2-regular text-(--app-text-subtle)">Selecciona el estilo de la aplicación. El cambio se aplica en tiempo real.</p>

    <div class="grid grid-cols-2 gap-2.5 sm:grid-cols-3">
      @for (mode of layoutModes; track mode.id) {
        <button type="button" class="layout-card flex flex-col items-center gap-1 rounded-xl border p-2.5 text-center transition-colors" [class.border-(--as-primary-color)]="mode.id === activeLayout" [class.border-(--app-border-color)]="mode.id !== activeLayout" [class.opacity-60]="!mode.built" [class.cursor-not-allowed]="!mode.built" [disabled]="!mode.built" [attr.aria-pressed]="mode.id === activeLayout" [attr.aria-label]="mode.built ? mode.label : mode.label + ' (en construcción)'">
          <div class="flex h-11 w-24 gap-1 rounded bg-(--app-surface-bg) p-1" [class.gap-1.5]="mode.floating">
            <div class="flex flex-col gap-0.5 rounded-sm p-1" [class.w-3]="mode.compact" [class.w-6]="!mode.compact" [class.bg-(--as-primary-color)]="!mode.transparent" [class.bg-transparent]="mode.transparent">
              <i class="block h-0.5 rounded bg-(--app-text-subtle)"></i>
              <i class="block h-0.5 rounded bg-(--app-text-subtle)"></i>
              <i class="block h-0.5 rounded bg-(--app-text-subtle)"></i>
            </div>
            <div class="flex flex-1 flex-col gap-1">
              <i class="block h-2 rounded-sm bg-(--app-border-color)"></i>
              <i class="block flex-1 rounded-sm bg-(--app-border-color)"></i>
            </div>
          </div>
          <strong class="text-caption-2-bold text-(--app-text-color)">{{ mode.label }}</strong>
          <small class="text-caption-2-regular text-(--app-text-subtle)">{{ mode.description }}</small>
          @if (!mode.built) {
            <span class="rounded-full bg-(--app-badge-soft-bg) px-2 py-0.5 text-caption-2-semibold text-(--app-badge-soft-text)">En construcción</span>
          }
        </button>
      }
    </div>
  </section>

  <section class="flex items-center justify-between gap-3 border-t border-(--app-border-color) pt-4">
    <label for="transparent-sidebar-width" class="text-caption-1-semibold text-(--app-text-color)">Sidebar transparente</label>
    <select id="transparent-sidebar-width" class="rounded-lg border border-(--app-border-color) bg-(--app-panel-bg) px-2 py-1.5 text-caption-1-medium text-(--app-text-subtle)" disabled>
      <option>Ancho</option>
      <option>Compacto</option>
    </select>
  </section>

  <section class="flex items-center justify-between gap-3 border-t border-(--app-border-color) pt-4">
    <span class="text-caption-1-semibold text-(--app-text-color)">Esquema de colores</span>
    <div class="flex flex-wrap justify-end gap-1.5" role="group" aria-label="Esquema de colores">
      @for (color of colors; track color.key) {
        <button type="button" class="size-6 rounded-lg border-2 border-white shadow-[0_0_0_1px_var(--app-border-color)]" [class.outline-2]="themeService.primaryColorKey() === color.key" [class.outline-offset-2]="themeService.primaryColorKey() === color.key" [class.outline-(--as-primary-color)]="themeService.primaryColorKey() === color.key" [style.background]="color.swatch" [attr.aria-label]="'Color ' + color.label" [attr.aria-pressed]="themeService.primaryColorKey() === color.key" (click)="themeService.applyColor(color.key)"></button>
      }
    </div>
  </section>

  <section class="flex items-center justify-between gap-3 border-t border-(--app-border-color) pt-4">
    <span class="text-caption-1-semibold text-(--app-text-color)">Tema</span>
    <div class="flex gap-1 rounded-xl border border-(--app-border-color) p-1" role="group" aria-label="Tema">
      <button type="button" class="flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-caption-2-semibold" [class.bg-(--as-primary-color)]="!isDark()" [class.text-(--as-primary-contrast-color)]="!isDark()" [class.text-(--app-text-color)]="isDark()" [attr.aria-pressed]="!isDark()" (click)="themeService.setMode('light')">
        <as-icon name="Sun" size="14" />Claro
      </button>
      <button type="button" class="flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-caption-2-semibold" [class.bg-(--as-primary-color)]="isDark()" [class.text-(--as-primary-contrast-color)]="isDark()" [class.text-(--app-text-color)]="!isDark()" [attr.aria-pressed]="isDark()" (click)="themeService.setMode('dark')">
        <as-icon name="Moon" size="14" />Oscuro
      </button>
    </div>
  </section>
</div>
