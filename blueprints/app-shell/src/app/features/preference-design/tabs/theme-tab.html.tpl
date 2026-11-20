<div class="flex flex-col gap-6">
  <header>
    <h2 class="text-body-2-bold text-(--app-text-color)">Personalización de tema</h2>
    <p class="text-caption-2-regular text-(--app-text-subtle)">Cambios de color y de modo global. El tema y los colores se guardan al elegirlos.</p>
  </header>

  <section class="flex flex-col gap-2">
    <span class="text-caption-1-semibold text-(--app-text-color)">Color principal</span>
    <__PREFIX__-color-swatches [colors]="primaryColors" [current]="themeService.primaryColorKey()" label="Color principal" (chosen)="themeService.applyColor($event)" />
  </section>

  <section class="flex flex-col gap-2 border-t border-(--app-border-color) pt-4">
    <span class="text-caption-1-semibold text-(--app-text-color)">Superficie</span>
    <__PREFIX__-color-swatches [colors]="surfaceColors" [current]="themeService.surfaceColorKey()" label="Superficie" itemLabel="Superficie" (chosen)="themeService.applySurface($event)" />
  </section>

  <section class="flex items-center justify-between gap-3 border-t border-(--app-border-color) pt-4">
    <span class="text-caption-1-semibold text-(--app-text-color)">Modo de color</span>
    <__PREFIX__-mode-switch label="Modo de color" />
  </section>
</div>
