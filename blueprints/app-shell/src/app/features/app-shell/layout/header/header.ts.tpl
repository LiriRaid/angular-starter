import { ChangeDetectionStrategy, Component, ViewEncapsulation, computed, inject } from '@angular/core';
import { Router } from '@angular/router';

import { BreadcrumbComponent } from '../../components/breadcrumb/breadcrumb';
import { BreadcrumbService } from '@core/navigation/breadcrumb.service';
import { DesignPreferencesService } from '@core/design-preferences/design-preferences.service';
import { LayoutService } from '../../services/layout.service';
import { ThemeService } from '@core/theme/theme.service';

import { AsButton, AsThemeColorPicker, AsTooltip } from '@shared/components';

@Component({
  selector: '__PREFIX__-header',
  standalone: true,
  imports: [BreadcrumbComponent, AsButton, AsThemeColorPicker, AsTooltip],
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
