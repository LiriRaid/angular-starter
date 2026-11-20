import { Provider } from '@angular/core';
import { NavigationGroup } from '@core/navigation/navigation.types';
import { SidebarStatus } from '../layout/enums/sidebar-status.enum';
import { LayoutService, NAVIGATION_GROUPS_TOKEN, SIDEBAR_INITIAL_STATE } from '../services/layout.service';

/**
 * Retorna los providers necesarios para configurar el layout según el árbol de navegación y el
 * estado inicial del sidebar. El árbol, los títulos y el breadcrumb ya los registra
 * `provideNavigation` en `app.config.ts`.
 */
export function provideLayout(navigationTree: readonly NavigationGroup[], sidebarState: SidebarStatus = SidebarStatus.EXPANDED): Provider[] {
  return [
    {
      provide: NAVIGATION_GROUPS_TOKEN,
      useValue: navigationTree,
    },
    {
      provide: SIDEBAR_INITIAL_STATE,
      useValue: sidebarState,
    },
    LayoutService,
  ];
}
