import { Injectable, signal, computed, Signal, InjectionToken, inject } from '@angular/core';
import { NavigationGroup } from '@core/navigation/navigation.types';
import { SidebarStatus } from '../layout/enums/sidebar-status.enum';
import { collapseAllItems, collapseItemsNotContainingRoute, expandParentsOfActiveItem, hasAnyManualExpansion, restoreExpansionState, saveExpansionState } from './layout-navigation-state.utils';

// Inyección de navegación y estado inicial
export const NAVIGATION_GROUPS_TOKEN = new InjectionToken<readonly NavigationGroup[]>('NAVIGATION_GROUPS_TOKEN');
export const SIDEBAR_INITIAL_STATE = new InjectionToken<SidebarStatus>('SIDEBAR_INITIAL_STATE');

@Injectable({ providedIn: 'root' })
export class LayoutService {
  private _isOpen = signal(false);
  private _shouldRender = signal(false);
  private _isMobile = signal(false);

  /**
   * Estado puente para desktop -> mobile.
   *
   * Mientras esto está true:
   * - NO activamos mobile.
   * - NO hay overlay.
   * - NO hay position fixed.
   * - El sidebar sigue en el layout normal y puede animar width hasta 0.
   */
  private _isDesktopToMobileTransition = signal(false);
  private desktopToMobileTimer: ReturnType<typeof setTimeout> | null = null;

  // Última URL conocida
  private _lastUrl = '/';

  private _desktopState: SidebarStatus = inject(SIDEBAR_INITIAL_STATE);
  private _desktopExpansionState: Map<string, boolean> = new Map();
  private _initialExpansionState: Map<string, boolean> = new Map();

  isOpen = this._isOpen.asReadonly();
  isMobile = this._isMobile.asReadonly();
  shouldRender = this._shouldRender.asReadonly();

  state: Signal<SidebarStatus> = computed(() => (this._isOpen() ? SidebarStatus.EXPANDED : SidebarStatus.COLLAPSED));

  private _navigationGroups = inject<readonly NavigationGroup[]>(NAVIGATION_GROUPS_TOKEN);

  constructor() {
    this.saveInitialExpansionState();

    const isMobile = window.innerWidth < 1024;

    if (isMobile) {
      this._isOpen.set(false);
      this._shouldRender.set(false);
      this._isMobile.set(true);
      this._isDesktopToMobileTransition.set(false);
    } else {
      this._isOpen.set(this._desktopState === SidebarStatus.EXPANDED);
      this._shouldRender.set(true);
      this._isMobile.set(false);
      this._isDesktopToMobileTransition.set(false);
    }
  }

  /** ---------- API PÚBLICA ---------- */

  getNavigationGroups(): readonly NavigationGroup[] {
    return this._navigationGroups;
  }

  setNavigationGroups(groups: readonly NavigationGroup[]): void {
    this._navigationGroups = groups;
  }

  updateCurrentUrl(url: string): void {
    if (url) this._lastUrl = url;
  }

  setOpen(open: boolean, currentUrl?: string): void {
    if (currentUrl) this._lastUrl = currentUrl;

    /**
     * Si estamos en el cruce desktop -> mobile,
     * ignoramos cualquier setOpen(false) extra que venga del sidebar.ts.
     *
     * Esto evita que el cierre se convierta en overlay.
     */
    if (this._isDesktopToMobileTransition()) {
      return;
    }

    if (this._isMobile()) {
      if (open) {
        this._shouldRender.set(true);

        requestAnimationFrame(() => {
          requestAnimationFrame(() => {
            this._isOpen.set(true);
            this.expandParentsIfNoManualExpansion(this._lastUrl);
          });
        });
      } else {
        this._isOpen.set(false);
      }

      return;
    }

    this._isOpen.set(open);
  }

  onTransitionClosed(): void {
    if (this._isMobile() && !this._isOpen()) {
      this._shouldRender.set(false);
    }
  }

  toggle(currentUrl?: string): void {
    this.setOpen(!this._isOpen(), currentUrl);
  }

  setMobile(isMobile: boolean): void {
    const wasMobile = this._isMobile();
    const isGoingToMobile = this._isDesktopToMobileTransition();

    /**
     * Si ya estamos cerrando hacia mobile, no reiniciar con cada resize.
     */
    if (isMobile && isGoingToMobile) return;

    /**
     * DESKTOP -> MOBILE
     *
     * Este es el arreglo importante.
     *
     * NO hacemos _isMobile.set(true) todavía.
     * Primero dejamos que el CSS lo cierre con width: 0.
     */
    if (isMobile && !wasMobile) {
      this.saveDesktopState();
      this.clearDesktopToMobileTimer();

      this._shouldRender.set(true);
      this._isDesktopToMobileTransition.set(true);

      /**
       * Esto cambia el estado a collapsed.
       * Como todavía NO es mobile, el CSS puede animar:
       *
       * expanded 18.5rem -> 0
       * collapsed 4rem -> 0
       */
      this._isOpen.set(false);

      /**
       * Fallback / finalizador de la transición.
       * Debe coincidir con --t-main: 0.4s del CSS.
       */
      this.desktopToMobileTimer = setTimeout(() => {
        this.finishDesktopToMobileTransition();
      }, 350);

      return;
    }

    /**
     * Si veníamos cerrando hacia mobile pero el usuario vuelve a 1024+.
     */
    if (!isMobile && isGoingToMobile) {
      this.clearDesktopToMobileTimer();

      this._isDesktopToMobileTransition.set(false);
      this._isMobile.set(false);
      this._shouldRender.set(true);

      this._isOpen.set(this._desktopState === SidebarStatus.EXPANDED);

      if (this._desktopState === SidebarStatus.EXPANDED) {
        queueMicrotask(() => restoreExpansionState(this._navigationGroups, this._desktopExpansionState));
      }

      return;
    }

    /**
     * MOBILE -> DESKTOP
     *
     * Mantiene el comportamiento que ya te funciona:
     * aparece desde 0 y crece hacia el estado desktop guardado.
     */
    if (!isMobile && wasMobile) {
      this.clearDesktopToMobileTimer();

      this._isDesktopToMobileTransition.set(false);
      this._isMobile.set(false);
      this._shouldRender.set(true);

      /**
       * Primer frame: queda collapsed.
       * El CSS pasa de mobile width 0 a desktop collapsed/expanded.
       */
      this._isOpen.set(false);

      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          this._isOpen.set(this._desktopState === SidebarStatus.EXPANDED);

          if (this._desktopState === SidebarStatus.EXPANDED) {
            queueMicrotask(() => restoreExpansionState(this._navigationGroups, this._desktopExpansionState));
          }
        });
      });

      return;
    }

    this._isMobile.set(isMobile);
  }

  finishDesktopToMobileTransition(): void {
    if (!this._isDesktopToMobileTransition()) return;

    this.clearDesktopToMobileTimer();

    /**
     * Ahora sí entramos a mobile real.
     * Como isOpen queda false, NO aparece overlay.
     * Como shouldRender queda false, el sidebar ni existe visualmente.
     */
    this._isOpen.set(false);
    this._isMobile.set(true);
    this._isDesktopToMobileTransition.set(false);
    this._shouldRender.set(false);
  }

  expandParentsOfActiveItem(currentUrl: string): void {
    expandParentsOfActiveItem(this._navigationGroups, currentUrl, this._initialExpansionState);
  }

  expandParentsIfNoManualExpansion(currentUrl: string): void {
    const hasManualExpansion = hasAnyManualExpansion(this._navigationGroups, this._lastUrl || window.location.pathname, this._initialExpansionState);

    if (!hasManualExpansion) {
      this.expandParentsOfActiveItem(currentUrl);
    }
  }

  handleNavigationChange(currentUrl: string): void {
    this._lastUrl = currentUrl || this._lastUrl;

    if (this._isMobile() && this._isOpen()) {
      this.collapseItemsNotContainingRoute(currentUrl);
      this.expandParentsOfActiveItem(currentUrl);
    }
  }

  collapseAll(): void {
    collapseAllItems(this._navigationGroups);
  }

  /** ---------- INTERNOS ---------- */

  private clearDesktopToMobileTimer(): void {
    if (!this.desktopToMobileTimer) return;

    clearTimeout(this.desktopToMobileTimer);
    this.desktopToMobileTimer = null;
  }

  private saveDesktopState(): void {
    this._desktopState = this.state();
    this._desktopExpansionState = saveExpansionState(this._navigationGroups);
  }

  private saveInitialExpansionState(): void {
    this._initialExpansionState = saveExpansionState(this._navigationGroups);
  }

  private collapseItemsNotContainingRoute(currentUrl: string): void {
    collapseItemsNotContainingRoute(this._navigationGroups, currentUrl);
  }
}
