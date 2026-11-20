<div class="flex flex-col gap-4">
  <header>
    <h2 class="text-body-2-bold text-(--app-text-color)">Preferencias globales</h2>
    <p class="text-caption-2-regular text-(--app-text-subtle)">Opciones de navegación y comportamiento.</p>
  </header>

  @for (toggle of toggles; track toggle.id) {
    <div class="flex items-center justify-between gap-3 border-t border-(--app-border-color) pt-4 first-of-type:border-t-0 first-of-type:pt-0">
      <div class="flex flex-col">
        <span class="text-caption-1-semibold text-(--app-text-color)">{{ toggle.label }}</span>
        <span class="text-caption-2-regular text-(--app-text-subtle)">{{ toggle.hint }}</span>
      </div>
      <as-toggle [checked]="toggle.value()" (changed)="toggle.setValue($event)" [ariaLabel]="toggle.label" />
    </div>
  }
</div>
