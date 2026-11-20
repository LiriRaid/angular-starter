<div class="flex flex-col gap-6">
  <header>
    <h2 class="text-body-2-bold text-(--app-text-color)">Personalización de tema</h2>
    <p class="text-caption-2-regular text-(--app-text-subtle)">Cambios de color y de modo global. El tema y los colores se guardan al elegirlos.</p>
  </header>

  <section class="flex flex-col gap-2">
    <span class="text-caption-1-semibold text-(--app-text-color)">Color principal</span>
    <div class="flex flex-wrap gap-1.5" role="group" aria-label="Color principal">
      @for (color of primaryColors; track color.key) {
        <button type="button" class="size-7 rounded-lg border-2 border-white shadow-[0_0_0_1px_var(--app-border-color)]" [class.outline-2]="themeService.primaryColorKey() === color.key" [class.outline-offset-2]="themeService.primaryColorKey() === color.key" [class.outline-(--as-primary-color)]="themeService.primaryColorKey() === color.key" [style.background]="color.swatch" [attr.aria-label]="'Color ' + color.label" [attr.aria-pressed]="themeService.primaryColorKey() === color.key" (click)="themeService.applyColor(color.key)"></button>
      }
    </div>
  </section>

  <section class="flex flex-col gap-2 border-t border-(--app-border-color) pt-4">
    <span class="text-caption-1-semibold text-(--app-text-color)">Superficie</span>
    <div class="flex flex-wrap gap-1.5" role="group" aria-label="Superficie">
      @for (surface of surfaceColors; track surface.key) {
        <button type="button" class="size-7 rounded-lg border-2 border-white shadow-[0_0_0_1px_var(--app-border-color)]" [class.outline-2]="themeService.surfaceColorKey() === surface.key" [class.outline-offset-2]="themeService.surfaceColorKey() === surface.key" [class.outline-(--as-primary-color)]="themeService.surfaceColorKey() === surface.key" [style.background]="surface.swatch" [attr.aria-label]="'Superficie ' + surface.label" [attr.aria-pressed]="themeService.surfaceColorKey() === surface.key" (click)="themeService.applySurface(surface.key)"></button>
      }
    </div>
  </section>

  <section class="flex items-center justify-between gap-3 border-t border-(--app-border-color) pt-4">
    <span class="text-caption-1-semibold text-(--app-text-color)">Modo de color</span>
    <div class="flex gap-1 rounded-xl border border-(--app-border-color) p-1" role="group" aria-label="Modo de color">
      <button type="button" class="flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-caption-2-semibold" [class.bg-(--as-primary-color)]="!isDark()" [class.text-(--as-primary-contrast-color)]="!isDark()" [class.text-(--app-text-color)]="isDark()" [attr.aria-pressed]="!isDark()" (click)="themeService.setMode('light')">
        <as-icon name="Sun" size="14" />Claro
      </button>
      <button type="button" class="flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-caption-2-semibold" [class.bg-(--as-primary-color)]="isDark()" [class.text-(--as-primary-contrast-color)]="isDark()" [class.text-(--app-text-color)]="!isDark()" [attr.aria-pressed]="isDark()" (click)="themeService.setMode('dark')">
        <as-icon name="Moon" size="14" />Oscuro
      </button>
    </div>
  </section>
</div>
