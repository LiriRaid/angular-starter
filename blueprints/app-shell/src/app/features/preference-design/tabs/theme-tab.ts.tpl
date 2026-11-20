import { ChangeDetectionStrategy, Component, computed, inject } from '@angular/core';

import { PRIMARY_COLORS, SURFACE_COLORS } from '@core/theme/theme-palettes';
import { ThemeService } from '@core/theme/theme.service';
import { AsIcon } from '@shared/components';

@Component({
  selector: '__PREFIX__-theme-tab',
  imports: [AsIcon],
  templateUrl: './theme-tab.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ThemeTab {
  readonly themeService = inject(ThemeService);

  readonly primaryColors = PRIMARY_COLORS;
  readonly surfaceColors = SURFACE_COLORS;
  readonly isDark = computed(() => this.themeService.mode() === 'dark');
}
