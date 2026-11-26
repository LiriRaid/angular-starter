<div class="header-search relative w-full max-w-md" (focusin)="open.set(true)" (focusout)="onFocusOut($event)" (keydown)="onKeydown($event)">
  <sa-search [control]="control" placeholder="Buscar en la aplicación" />

  @if (showPanel()) {
    <ul role="listbox" aria-label="Resultados de la búsqueda" class="absolute top-full right-0 left-0 z-20 mt-2 flex max-h-80 flex-col gap-0.5 overflow-y-auto rounded-xl border border-(--app-border-color) bg-(--app-panel-bg) p-1.5 shadow-lg" (mousedown)="$event.preventDefault()">
      @for (entry of results(); track entry.id; let index = $index) {
        <li role="option" [attr.aria-selected]="index === activeIndex()" class="flex cursor-pointer items-center gap-2 rounded-lg px-2.5 py-2 hover:bg-(--app-sidebar-hover-bg)" [class.bg-(--app-sidebar-hover-bg)]="index === activeIndex()" (click)="go(entry)">
          @if (entry.icon) {
            <sa-icon [name]="entry.icon" size="16" />
          }
          <span class="min-w-0 flex-1 truncate text-caption-1-semibold text-(--app-text-color)">{{ entry.title }}</span>
          @if (entry.trail.length) {
            <span class="truncate text-caption-2-regular text-(--app-text-subtle)">{{ entry.trail.join(' › ') }}</span>
          }
        </li>
      } @empty {
        <li role="presentation" class="px-2.5 py-2 text-caption-2-regular text-(--app-text-subtle)">Sin resultados</li>
      }
    </ul>
  }
</div>
