import { ChangeDetectionStrategy, Component, inject } from '@angular/core';

import { PRIMARY_COLORS, SURFACE_COLORS } from '@core/theme/theme-palettes';
import { ThemeService } from '@core/theme/theme.service';
import { ColorSwatches, ModeSwitch } from './theme-controls';

@Component({
  selector: '__PREFIX__-theme-tab',
  imports: [ColorSwatches, ModeSwitch],
  templateUrl: './theme-tab.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ThemeTab {
  readonly themeService = inject(ThemeService);

  readonly primaryColors = PRIMARY_COLORS;
  readonly surfaceColors = SURFACE_COLORS;
}
