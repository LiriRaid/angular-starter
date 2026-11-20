<section class="flex flex-col gap-4 border-t border-(--app-border-color) pt-4" aria-label="UI System">
  <header class="flex flex-wrap items-end justify-between gap-3">
    <div>
      <h3 class="text-body-2-bold text-(--app-text-color)">UI System</h3>
      <p class="text-caption-2-regular text-(--app-text-subtle)">Los componentes instalados con su vista previa, su código y los tokens que los cambian. Muévelos arriba y mira cómo responden.</p>
    </div>
    <input type="search" class="w-56 rounded-lg border border-(--app-border-color) bg-(--app-panel-bg) px-3 py-1.5 text-caption-1-medium text-(--app-text-color)" placeholder="Buscar componente" aria-label="Buscar componente" [value]="query()" (input)="query.set($any($event.target).value)" />
  </header>

  @for (entry of filtered(); track entry.id) {
    <article class="flex flex-col gap-3 rounded-xl border border-(--app-border-color) p-4" [attr.data-component]="entry.id">
      <header class="flex items-start justify-between gap-3">
        <div class="min-w-0">
          <h4 class="text-caption-1-bold text-(--app-text-color)">{{ entry.label }}</h4>
          <code class="text-caption-2-regular text-(--app-text-subtle)">{{ entry.selector }}</code>
        </div>
        <as-toggle [checked]="isShown(entry.id)" (changed)="setShown(entry.id, $event)" [ariaLabel]="'Mostrar la vista previa de ' + entry.label" />
      </header>

      <p class="text-caption-2-regular text-(--app-text-subtle)">{{ entry.description }}</p>

      <p class="flex flex-wrap items-center gap-1.5 text-caption-2-regular text-(--app-text-subtle)">
        <span>Cambia con:</span>
        @for (token of entry.affects; track token) {
          <span class="rounded-full bg-(--app-badge-soft-bg) px-2 py-0.5 text-caption-2-semibold text-(--app-badge-soft-text)">{{ token }}</span>
        } @empty {
          <span>ningún token</span>
        }
      </p>

      @if (isShown(entry.id)) {
        <div class="flex flex-wrap items-center gap-3 rounded-lg border border-dashed border-(--app-border-color) bg-(--app-panel-muted-bg) p-4">
          @switch (entry.id) {
            @case ('icon') {
              <as-icon name="Palette" size="24" />
              <as-icon name="Check" size="24" />
            }
            @case ('button') {
              <as-button label="Guardar" icon="Check" iconSize="16" />
              <as-button label="Secundario" severity="secondary" />
              <as-button label="Contorno" variant="outlined" />
            }
            @case ('input') {
              <div class="w-64"><as-input label="Nombre" placeholder="Escribe aquí" /></div>
            }
            @case ('textarea') {
              <div class="w-64"><as-textarea label="Comentario" [rows]="2" /></div>
            }
            @case ('checkbox') {
              <as-checkbox ariaLabel="Casilla de ejemplo" />
            }
            @case ('toggle') {
              <as-toggle [checked]="true" ariaLabel="Interruptor de ejemplo" />
            }
            @case ('select') {
              <div class="w-64"><as-select label="Plan" [options]="plans" optionLabel="label" optionValue="value" /></div>
            }
            @case ('avatar') {
              <as-avatar label="AB" [size]="40" />
              <as-avatar label="CD" [size]="40" shape="rounded" />
            }
            @case ('divider') {
              <div class="w-full"><as-divider /></div>
            }
            @case ('skeleton') {
              <div class="w-64"><as-skeleton layout="line" [lines]="2" /></div>
            }
            @case ('tooltip') {
              <as-button label="Pasa el cursor" variant="outlined" asTooltip="Texto de ayuda" tooltipPosition="top" />
            }
            @case ('modal') {
              <as-button label="Abrir modal" variant="outlined" (onClick)="modalOpen.set(true)" />
              <as-modal [(visible)]="modalOpen" title="Modal de ejemplo">
                <p class="p-4 text-caption-1-regular text-(--app-text-color)">El contenido del diálogo.</p>
              </as-modal>
            }
            @case ('drawer') {
              <as-button label="Abrir panel" variant="outlined" (onClick)="drawerOpen.set(true)" />
              <as-drawer [(visible)]="drawerOpen" position="right">
                <p class="p-4 text-caption-1-regular text-(--app-text-color)">El contenido del panel.</p>
              </as-drawer>
            }
            @case ('toast') {
              <as-button label="Mostrar toast" variant="outlined" (onClick)="showToast()" />
            }
            @case ('tabs') {
              <div class="w-full"><as-tabs [tabs]="tabs" [active]="activeTab()" (activeChange)="activeTab.set($event)" ariaLabel="Pestañas de ejemplo" /></div>
            }
            @case ('popover') {
              <as-popover triggerIcon="Ellipsis" triggerAriaLabel="Abrir popover de ejemplo">
                <p class="w-48 p-3 text-caption-1-regular text-(--app-text-color)">Contenido del popover.</p>
              </as-popover>
            }
          }
        </div>

        <details>
          <summary class="cursor-pointer text-caption-2-semibold text-(--app-text-color)">Código</summary>
          <pre class="mt-2 overflow-x-auto rounded-lg bg-(--app-panel-muted-bg) p-3 text-caption-2-regular text-(--app-text-color)"><code>{{ entry.code }}</code></pre>
        </details>
      }
    </article>
  } @empty {
    <p class="text-caption-1-regular text-(--app-text-subtle)">Ningún componente coincide con la búsqueda.</p>
  }
</section>
