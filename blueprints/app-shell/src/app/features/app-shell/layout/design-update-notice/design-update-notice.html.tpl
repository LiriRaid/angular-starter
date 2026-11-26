@if (visible()) {
  <div role="status" class="fixed right-4 bottom-4 z-1100 flex max-w-sm items-start gap-3 rounded-xl border border-(--app-border-color) bg-(--app-panel-bg) p-4 shadow-lg" animate.enter="fade-in-out-enter" animate.leave="fade-in-out-leave">
    <div class="flex min-w-0 flex-1 flex-col gap-2">
      <strong class="text-caption-1-bold text-(--app-text-color)">El diseño de la plataforma cambió</strong>
      <span class="text-caption-2-regular text-(--app-text-subtle)">El administrador guardó otro diseño. Recarga la página para verlo; mientras tanto puedes seguir trabajando.</span>
      <div>
        <sa-button size="small" icon="Refresh" iconSize="14" label="Recargar" (onClick)="reload()" />
      </div>
    </div>
    <sa-button icon="X" iconSize="16" variant="text" size="small" ariaLabel="Cerrar aviso" (onClick)="dismiss()" />
  </div>
}
