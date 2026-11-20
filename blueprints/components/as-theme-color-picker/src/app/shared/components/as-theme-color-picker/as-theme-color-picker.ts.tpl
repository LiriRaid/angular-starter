import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { PRIMARY_COLORS, SURFACE_COLORS } from '@core/theme/theme-palettes';
import { ThemeService } from '@core/theme/theme.service';
import { AsIcon } from '../as-icon/as-icon';
import { AsPopover } from '../as-popover/as-popover';

/**
 * A button that opens a panel to switch between light and dark mode and to pick the accent and
 * surface colors of the application. It drives `ThemeService`, which remembers the choice.
 *
 * ```html
 * <as-theme-color-picker />
 * ```
 */
@Component({
  selector: 'as-theme-color-picker',
  imports: [AsIcon, AsPopover],
  templateUrl: './as-theme-color-picker.html',
  styleUrl: './as-theme-color-picker.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AsThemeColorPicker {
  protected readonly theme = inject(ThemeService);
  protected readonly open = signal(false);
  protected readonly primaryColors = PRIMARY_COLORS;
  protected readonly surfaceColors = SURFACE_COLORS;
}
