<nav class="__PREFIX__-header sticky top-0 z-10 h-[3.75rem] flex items-center justify-between px-4 bg-(--app-panel-bg) border-b border-(--app-border-color)">
  <div class="header-content w-full flex items-center justify-between gap-3 max-lg:gap-2">
    <div class="header-left flex-1 min-w-0 flex items-center gap-4">
      <as-button type="button" variant="text" size="small" [icon]="isSidebarOpen ? 'PanelClose' : 'PanelOpen'" iconSize="24" styleClass="header-theme-btn !border-0 [color:var(--app-action-icon-color)] hover:[color:var(--app-text-primary)] hover:!bg-(--app-action-hover-bg)" [ariaLabel]="isSidebarOpen ? 'Colapsar sidebar' : 'Expandir sidebar'" [asTooltip]="isSidebarOpen ? 'Colapsar' : 'Expandir'" tooltipPosition="bottom" [showDelay]="300" (onClick)="toggleSidebar()" />

      <div class="breadcrumb-slot flex-1 min-w-0 mr-3 overflow-visible">
        @if (designPreferences.preferences().showBreadcrumb) {
          <__PREFIX__-breadcrumb [breadcrumbs]="breadcrumbService.breadcrumbs()" />
        }
      </div>
    </div>

    <div class="header-right shrink-0 flex items-center gap-2.5">
      <as-theme-color-picker triggerClass="header-theme-btn" size="medium" triggerTooltip="Paleta de colores" triggerTooltipPosition="bottom" [triggerTooltipDelay]="300" />

      <!-- Modo oscuro/claro -->
      <as-button type="button" variant="outlined" size="medium" [icon]="isDark() ? 'Sun' : 'Moon'" iconSize="20" styleClass="header-theme-btn" ariaLabel="Cambiar tema" [asTooltip]="isDark() ? 'Modo Claro' : 'Modo Oscuro'" tooltipPosition="bottom" [showDelay]="300" (onClick)="toggleTheme()" />
    </div>
  </div>
</nav>
