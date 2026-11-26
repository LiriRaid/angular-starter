import { ChangeDetectionStrategy, Component, ViewEncapsulation, computed, inject } from '@angular/core';
import { Router } from '@angular/router';

import { BreadcrumbComponent } from '../../components/breadcrumb/breadcrumb';
import { HeaderSearch } from './header-search/header-search';
import { UserMenu } from '../sidebar/user-menu/user-menu';
import { BreadcrumbService } from '@core/navigation/breadcrumb.service';
import { DesignPreferencesService } from '@core/design-preferences/design-preferences.service';
import { LayoutService } from '../../services/layout.service';
import { ThemeService } from '@core/theme/theme.service';

import { SaButton, SaThemeColorPicker, SaTooltip } from '@shared/components';

@Component({
  selector: '__PREFIX__-header',
  standalone: true,
  imports: [BreadcrumbComponent, HeaderSearch, SaButton, SaThemeColorPicker, SaTooltip, UserMenu],
  templateUrl: './header.html',
  styleUrl: './header.css',
  encapsulation: ViewEncapsulation.None,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Header {
  readonly layoutService = inject(LayoutService);
  readonly router = inject(Router);
  readonly breadcrumbService = inject(BreadcrumbService);
  readonly themeService = inject(ThemeService);
  readonly designPreferences = inject(DesignPreferencesService);

  /** Los layouts compactos muestran un buscador en lugar del breadcrumb; en pantallas chicas se vuelve al breadcrumb. */
  readonly compact = computed(() => this.designPreferences.layoutTraits().compact && !this.layoutService.isMobile());

  readonly isDark = computed(() => this.themeService.mode() === 'dark');

  get isSidebarOpen(): boolean {
    return this.layoutService.isOpen();
  }

  toggleSidebar(): void {
    const currentUrl = this.router.url;
    const isMobile = this.layoutService.isMobile();
    const willBeOpen = !this.layoutService.isOpen();

    if (isMobile) {
      this.layoutService.toggle(currentUrl);

      if (willBeOpen) {
        queueMicrotask(() => this.layoutService.expandParentsIfNoManualExpansion(currentUrl));
      }

      return;
    }

    this.layoutService.collapseAll();
    this.layoutService.toggle(currentUrl);

    if (willBeOpen) {
      this.layoutService.expandParentsOfActiveItem(currentUrl);
    }
  }

  toggleTheme(): void {
    this.themeService.toggleMode();
  }
}
