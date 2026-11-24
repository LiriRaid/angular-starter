import { ChangeDetectionStrategy, Component, computed, DestroyRef, inject, signal } from '@angular/core';
import { NavigationEnd, Router } from '@angular/router';
import { FormControl, ReactiveFormsModule } from '@angular/forms';
import { takeUntilDestroyed, toObservable, toSignal } from '@angular/core/rxjs-interop';

import { filter, pairwise, startWith } from 'rxjs';

import { NavigationGroup, NavigationItem } from '@core/navigation/navigation.types';
import { NAV_APP_NAME_TOKEN } from '@core/navigation/navigation.tokens';
import { SidebarStatus } from '../enums/sidebar-status.enum';
import { LayoutService } from '../../services/layout.service';
import { filterNavigationGroups, getFolderRootLink, hasActiveDescendant, isNavigationItemActive, normalizeSidebarUrl } from './sidebar-navigation.utils';
import { SaIcon, SaRipple, SaSearch, SaTooltip } from '@shared/components';
import { UserMenu } from './user-menu/user-menu';

@Component({
  selector: '__PREFIX__-sidebar',
  imports: [ReactiveFormsModule, SaIcon, SaRipple, SaSearch, SaTooltip, UserMenu],
  templateUrl: './sidebar.html',
  styleUrl: './sidebar.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    '(window:resize)': 'onResize()',
  },
})
export class Sidebar {
  /** Nombre del proyecto: el mismo que `provideNavigation` agrega a los títulos de página. */
  readonly brandTitle = inject(NAV_APP_NAME_TOKEN);
  readonly brandInitial = (Array.from(this.brandTitle.trim())[0] ?? '').toUpperCase();
  readonly searchInput = new FormControl<string>('');

  SidebarStatus = SidebarStatus;

  readonly layoutService = inject(LayoutService);
  private readonly router = inject(Router);
  private readonly destroyRef = inject(DestroyRef);

  private readonly currentUrl = signal(normalizeSidebarUrl(this.router.url));
  private readonly restoreCollapsedAfterSearch = signal(false);
  private readonly skipExpandOnClearOnce = signal(false);
  private readonly collapseFoldersAfterCollapsedSearchNav = signal(false);
  private readonly collapseFoldersAfterExpandedSearchNav = signal(false);

  private readonly searchText = toSignal(this.searchInput.valueChanges.pipe(startWith(this.searchInput.value ?? '')), { initialValue: '' });

  readonly isSearching = computed(() => (this.searchText() ?? '').trim().length > 0);
  private readonly baseNavigationGroups = computed(() => this.layoutService.getNavigationGroups());

  readonly navigationGroups = computed<readonly NavigationGroup[]>(() => {
    const q = (this.searchText() ?? '').trim().toLowerCase();
    return filterNavigationGroups(this.baseNavigationGroups(), q, (item) => this.isHidden(item));
  });

  constructor() {
    this.checkScreenSize();
    this.expandParentsForUrl(this.currentUrl());

    this.searchInput.valueChanges.pipe(startWith(this.searchInput.value ?? ''), pairwise(), takeUntilDestroyed(this.destroyRef)).subscribe(([prev, curr]) => {
      const prevQ = (prev ?? '').trim();
      const currQ = (curr ?? '').trim();

      if (prevQ.length > 0 && currQ.length === 0) {
        if (this.skipExpandOnClearOnce()) {
          this.skipExpandOnClearOnce.set(false);
          return;
        }
        this.expandParentsForUrl(this.currentUrl());
      }
    });

    this.router.events
      .pipe(
        filter((e): e is NavigationEnd => e instanceof NavigationEnd),
        takeUntilDestroyed(this.destroyRef),
      )
      .subscribe((e) => this.onNavigationEnd(e));

    toObservable(
      computed(() => ({
        mobile: this.layoutService.isMobile(),
        open: this.layoutService.isOpen(),
        restore: this.restoreCollapsedAfterSearch(),
      })),
    )
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe(() => this.syncCollapsedSearchState());
  }

  onTransitionEnd(event: TransitionEvent) {
    if (event.propertyName === 'transform' && !this.layoutService.isOpen()) {
      this.layoutService.onTransitionClosed();
    }
  }

  onResize() {
    this.checkScreenSize();
  }

  // =========================
  // UI helpers
  // =========================
  isSidebarVisible(): boolean {
    if (this.layoutService.isMobile()) return this.layoutService.isOpen();
    return this.layoutService.state() === SidebarStatus.EXPANDED;
  }

  /** Un item oculto no se lista aquí (sí conserva título y breadcrumb). El permiso del item lo
   *  evalúa `filterNavigation` del árbol cuando el proyecto tenga autenticación. */
  isHidden(item: NavigationItem): boolean {
    return !!item.hidden?.(item);
  }

  isActive(item: NavigationItem): boolean {
    return isNavigationItemActive(item, this.currentUrl());
  }

  hasActiveDescendant(items: readonly NavigationItem[] | undefined): boolean {
    return hasActiveDescendant(items, this.currentUrl());
  }

  // =========================
  // Actions
  // =========================
  unfolItem(item: NavigationItem) {
    const isMobile = this.layoutService.isMobile();
    const isCollapsed = this.layoutService.state() === SidebarStatus.COLLAPSED;

    const canExpand = (isMobile && this.layoutService.isOpen()) || (!isMobile && this.isSidebarVisible());
    const isFolder = !!item.children?.length && !item.link;

    if (!isMobile && isCollapsed && isFolder) {
      const rootLink = getFolderRootLink(item);
      if (rootLink) this.navigate(rootLink);
      return;
    }

    if (item.link) {
      this.navigate(item.link);
      return;
    }

    if (canExpand && item.children?.length) {
      item.unfolded = !item.unfolded;
    }
  }

  navigate(link: string) {
    if (!link) return;

    const isMobile = this.layoutService.isMobile();
    const isDesktopCollapsed = !isMobile && this.layoutService.state() === SidebarStatus.COLLAPSED;

    const openedFromCollapsedSearch = this.restoreCollapsedAfterSearch();
    const hasSearch = this.hasSearch();

    if (openedFromCollapsedSearch) this.collapseFoldersAfterCollapsedSearchNav.set(true);
    if (!isDesktopCollapsed && hasSearch) this.collapseFoldersAfterExpandedSearchNav.set(true);

    this.router.navigate([link]);

    if (isMobile) {
      this.layoutService.setOpen(false);
      return;
    }

    if (openedFromCollapsedSearch) {
      this.restoreCollapsedAfterSearch.set(false);
      this.layoutService.setOpen(false);
      queueMicrotask(() => this.clearSearchForNavigation());
    }
  }

  onCollapsedSearchClick() {
    const isDesktopCollapsed = !this.layoutService.isMobile() && this.layoutService.state() === SidebarStatus.COLLAPSED;

    this.restoreCollapsedAfterSearch.set(isDesktopCollapsed);

    if (this.restoreCollapsedAfterSearch()) {
      this.layoutService.setOpen(true);
      queueMicrotask(() => this.layoutService.expandParentsOfActiveItem(this.currentUrl()));
    }

    setTimeout(() => this.focusSearchInput(), 0);
  }

  // =========================
  // Internals
  // =========================
  private onNavigationEnd(e: NavigationEnd) {
    const url = normalizeSidebarUrl(e.urlAfterRedirects);
    this.currentUrl.set(url);

    this.layoutService.updateCurrentUrl(e.urlAfterRedirects);
    this.layoutService.handleNavigationChange(e.urlAfterRedirects);

    if (this.collapseFoldersAfterCollapsedSearchNav()) {
      this.collapseFoldersAfterCollapsedSearchNav.set(false);
      this.collapseFoldersAndMaybeReopenParents(url, false);
      return;
    }

    if (this.collapseFoldersAfterExpandedSearchNav()) {
      this.collapseFoldersAfterExpandedSearchNav.set(false);
      this.collapseFoldersAndMaybeReopenParents(url, true);
      return;
    }
  }

  private checkScreenSize() {
    const isMob = window.innerWidth < 1024;
    const wasMobile = this.layoutService.isMobile();

    this.layoutService.setMobile(isMob);

    if (isMob && !wasMobile) {
      this.layoutService.setOpen(false);
    }
  }

  private syncCollapsedSearchState(): void {
    if (this.layoutService.isMobile()) return;
    if (!this.restoreCollapsedAfterSearch()) return;
    if (this.layoutService.isOpen()) return;

    this.restoreCollapsedAfterSearch.set(false);
    this.collapseFoldersAfterCollapsedSearchNav.set(false);
  }

  private focusSearchInput(attempt = 0) {
    const el = document.querySelector('__PREFIX__-sidebar input[placeholder="Buscar módulos"]') as HTMLInputElement | null;
    if (el) {
      el.focus();
      el.select();
      return;
    }
    if (attempt < 6) setTimeout(() => this.focusSearchInput(attempt + 1), 50);
  }

  private clearSearchForNavigation() {
    const v = (this.searchInput.value ?? '').trim();
    if (!v.length) return;

    this.skipExpandOnClearOnce.set(true);
    this.searchInput.setValue('', { emitEvent: true });
  }

  private hasSearch(): boolean {
    return (this.searchInput.value ?? '').trim().length > 0;
  }

  private collapseFoldersAndMaybeReopenParents(url: string, reopenParents: boolean) {
    this.layoutService.collapseAll();
    if (reopenParents) this.expandParentsForUrl(url);
  }

  private expandParentsForUrl(url: string) {
    const isMobile = this.layoutService.isMobile();
    const isExpanded = this.layoutService.state() === SidebarStatus.EXPANDED;

    if (!isMobile && isExpanded) {
      this.layoutService.expandParentsOfActiveItem(url);
      return;
    }

    if (isMobile) {
      this.layoutService.expandParentsIfNoManualExpansion(url);
    }
  }
}
