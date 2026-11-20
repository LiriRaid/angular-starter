<ng-template #userInfoTooltip>
  <div class="flex flex-col gap-0.5 items-start">
    <span class="text-caption-1-bold">{{ userName() }}</span>
    <span class="text-caption-2-regular" style="opacity: 0.7">{{ userRole() }}</span>
  </div>
</ng-template>

<as-popover #popover position="top" [triggerIcon]="null" triggerVariant="text" triggerStyleClass="um-trigger" triggerAriaLabel="Abrir menú de usuario" [triggerTooltip]="expanded() ? null : userInfoTooltip" triggerTooltipPosition="right" [triggerTooltipDelay]="300">
  <div popover-trigger class="um-card flex items-center gap-3 w-full min-w-0 text-left">
    <as-avatar class="um-card-avatar" [label]="userInitials()" background="var(--app-sidebar-user-avatar-bg)" color="var(--app-sidebar-user-avatar-text)" textClass="text-caption-1-bold tracking-[0.02em]" [alt]="userName()" />

    <div class="um-card-meta flex flex-col gap-[0.05rem] flex-1 min-w-0" [class.um-text-hidden]="!expanded()">
      <p class="um-card-name text-(--app-text-color) text-caption-1-bold overflow-hidden text-ellipsis whitespace-nowrap max-w-full">{{ userName() }}</p>
      <p class="um-card-email text-(--app-text-subtle) text-caption-2-regular overflow-hidden text-ellipsis whitespace-nowrap max-w-full">{{ userRole() }}</p>
    </div>

    <as-icon class="um-chevron ml-auto text-(--app-text-subtle)" [class.um-chevron--hidden]="!expanded()" [name]="popoverOpen() ? 'ChevronCircleDown' : 'ChevronCircleUp'" size="16" />
  </div>

  <div class="flex flex-col gap-3 w-60 p-3.5">
    <div class="flex items-center gap-3 min-w-0">
      <as-avatar [label]="userInitials()" background="var(--app-sidebar-user-avatar-bg)" color="var(--app-sidebar-user-avatar-text)" textClass="text-caption-1-bold tracking-[0.02em]" [alt]="userName()" />

      <div class="flex flex-col gap-[0.05rem] min-w-0">
        <span class="text-body-2-bold text-(--app-text-color) truncate">{{ userName() }}</span>
        <span class="text-caption-2-regular text-(--app-text-subtle) truncate">&#64;{{ userUsername() }}</span>
      </div>
    </div>

    <hr class="h-px border-0 bg-(--app-border-color) m-0" aria-hidden="true" />

    <as-button [text]="true" size="medium" icon="SlidersHorizontal" iconSize="16" label="Preferencias" ariaLabel="Preferencias" labelClass="text-caption-1-medium" styleClass="w-full um-status-item" (onClick)="openPreferences()" />

    <hr class="h-px border-0 bg-(--app-border-color) m-0" aria-hidden="true" />

    <p class="um-version-label text-[0.6rem] font-medium tracking-[0.04em] text-(--app-text-subtle) text-center opacity-60 pt-0.5">{{ appName }}</p>
  </div>
</as-popover>
