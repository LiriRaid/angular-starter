<section class="preference-design flex flex-col gap-5">
  <header>
    <h1 class="text-body-1-bold text-(--app-text-color)">Preferencias de Diseño</h1>
    <p class="text-caption-1-regular text-(--app-text-subtle)">Personaliza la apariencia y el comportamiento global de la aplicación. Los cambios se aplican en tiempo real.</p>
  </header>

  <div class="rounded-xl border border-(--app-border-color) bg-(--app-panel-bg)">
    <div class="border-b border-(--app-border-color) p-3">
      <as-tabs [tabs]="tabs" [active]="activeTab()" (activeChange)="activeTab.set($event)" ariaLabel="Preferencias de diseño" />
    </div>

    <div class="p-5">
      @switch (activeTab()) {
        @case ('appearance') {
          <__PREFIX__-appearance-tab />
        }
        @case ('theme') {
          <__PREFIX__-theme-tab />
        }
        @case ('ui') {
          <__PREFIX__-ui-tab />
        }
        @case ('other') {
          <__PREFIX__-other-tab />
        }
      }
    </div>

    <footer class="flex flex-wrap items-center justify-end gap-2 border-t border-(--app-border-color) p-3">
      @if (designPreferences.hasChanges()) {
        <span class="mr-auto text-caption-2-regular text-(--app-text-subtle)">Hay cambios sin guardar: se pierden al recargar.</span>
      }
      <as-button variant="outlined" size="medium" icon="Refresh" iconSize="16" label="Restablecer" (onClick)="reset()" />
      <as-button size="medium" icon="Check" iconSize="16" label="Guardar cambios" [disabled]="!designPreferences.hasChanges()" (onClick)="save()" />
    </footer>
  </div>
</section>
