<section class="preference-design flex flex-col gap-5">
  <header>
    <h1 class="text-body-1-bold text-(--app-text-color)">Preferencias de Diseño</h1>
    <p class="text-caption-1-regular text-(--app-text-subtle)">Personaliza la apariencia y el comportamiento global de la aplicación. Los cambios se aplican en tiempo real.</p>
  </header>

  <div class="rounded-xl border border-(--app-border-color) bg-(--app-panel-bg)">
    <div class="border-b border-(--app-border-color) p-3">
      <sa-tabs [tabs]="tabs" [active]="activeTab()" (activeChange)="activeTab.set($event)" ariaLabel="Preferencias de diseño" />
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
      @if (designPreferences.saveFailed()) {
        <span class="mr-auto text-caption-2-regular text-(--app-text-subtle)" role="alert">No se pudo guardar el diseño. Los cambios siguen en pantalla; vuelve a intentarlo.</span>
      } @else if (!designPreferences.canSave()) {
        <span class="mr-auto text-caption-2-regular text-(--app-text-subtle)">No tienes permiso para guardar el diseño de la plataforma: tus cambios se ven solo hasta que recargues.</span>
      } @else if (designPreferences.hasChanges()) {
        <span class="mr-auto text-caption-2-regular text-(--app-text-subtle)">Hay cambios sin guardar. Al guardar valen para toda la plataforma y los demás usuarios recibirán un aviso para recargar.</span>
      }
      <sa-button variant="outlined" size="medium" icon="Refresh" iconSize="16" label="Restablecer" (onClick)="reset()" />
      <sa-button size="medium" icon="Check" iconSize="16" label="Guardar cambios" [disabled]="!designPreferences.hasChanges() || !designPreferences.canSave()" (onClick)="save()" />
    </footer>
  </div>
</section>
