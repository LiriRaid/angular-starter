<ng-template #headerTpl>
  <div class="flex items-center gap-3.5 flex-1 min-w-0 w-full">
    <div class="w-10 h-10 inline-flex items-center justify-center rounded-full bg-(--app-sidebar-user-avatar-bg) text-(--app-sidebar-user-avatar-text) text-body-1-bold tracking-[0.02em]">U</div>
    <div class="flex flex-col flex-1 min-w-0">
      <span class="text-body-2-bold text-(--app-text-color) truncate">Usuario</span>
      <span class="text-caption-2-regular text-(--app-text-subtle) truncate">Administrador</span>
    </div>
  </div>
</ng-template>

<ng-template #closeIconTpl>
  <as-icon name="SignOut" size="16" />
</ng-template>

<as-drawer [visible]="visible()" (visibleChange)="visible.set($event)" class="user-preferences-drawer" position="right" [headerTemplate]="headerTpl" [closeIconTemplate]="closeIconTpl">
  <div class="flex flex-col h-full">
    <div class="border-b border-(--app-border-color) p-3">
      <as-tabs [tabs]="tabs" [active]="activeTab()" (activeChange)="activeTab.set($event)" ariaLabel="Configuración de usuario" />
    </div>

    <div class="flex-1 min-h-0 overflow-y-auto">
      @if (activeTab() === 'info') {
        <div class="flex flex-col gap-3.5 p-5">
          @for (item of infoItems; track item.label) {
            <div class="flex flex-col gap-0.5 border-b border-(--app-border-color) last:border-b-0">
              <span class="text-caption-2-semibold uppercase tracking-[0.06em] text-(--app-text-subtle)">{{ item.label }}</span>
              <span class="text-caption-1-medium text-(--app-text-color)">{{ item.value }}</span>
            </div>
          }
        </div>
      }

      @if (activeTab() === 'prefs') {
        <div class="flex flex-col gap-3.5 p-5">
          @for (section of preferenceSections; track section.id) {
            <div class="flex flex-col gap-2.5 border-b border-(--app-border-color) last:border-b-0">
              <h4 class="text-caption-2-bold uppercase tracking-[0.06em] text-(--app-text-subtle) m-0">{{ section.label }}</h4>

              @for (item of section.items; track item.id) {
                <div class="flex items-center justify-between gap-3 border-b border-[color-mix(in_srgb,var(--app-border-color)_50%,transparent)] last:border-b-0">
                  <div class="flex items-center gap-2 flex-1 min-w-0 text-(--app-text-subtle)">
                    <as-icon [name]="item.icon" size="16" />
                    <span class="text-caption-1-medium text-(--app-text-color)">{{ item.label }}</span>
                  </div>
                  <as-toggle [checked]="item.value()" (changed)="item.setValue($event)" [ariaLabel]="item.label" />
                </div>
              }
            </div>
          }
        </div>
      }

      @if (activeTab() === 'activity') {
        <div class="flex flex-col items-center justify-center gap-3 min-h-40 p-5 text-center text-(--app-text-subtle)">
          <as-icon name="Inbox" size="32" />
          <span class="text-caption-1-medium">El historial de actividad estará disponible próximamente</span>
        </div>
      }
    </div>
  </div>
</as-drawer>
