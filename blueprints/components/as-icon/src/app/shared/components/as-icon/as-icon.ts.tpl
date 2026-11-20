import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';
import { LucideDynamicIcon } from '@lucide/angular';

/**
 * An icon by name: any Lucide icon registered in `core/icons` (`name="check"`), or your own SVG file
 * with `src` (drawn in the current text color).
 *
 * ```html
 * <as-icon name="search" />
 * <as-icon name="loader-circle" [spin]="true" size="1.5rem" />
 * <as-icon src="/logo.svg" label="Company logo" />
 * ```
 */
@Component({
  selector: 'as-icon',
  imports: [LucideDynamicIcon],
  templateUrl: './as-icon.html',
  styleUrl: './as-icon.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    '[style.--as-icon-size]': 'cssSize()',
    '[style.color]': 'color() || null',
    '[attr.role]': 'label() ? "img" : null',
    '[attr.aria-label]': 'label() || null',
    '[attr.aria-hidden]': 'label() ? null : "true"',
  },
})
export class AsIcon {
  /** Name of a registered Lucide icon, in kebab-case. */
  readonly name = input<string>('');
  /** URL of an SVG file, used instead of `name`. */
  readonly src = input<string>('');
  /** A number is pixels; a string is any CSS length (`1.5rem`). */
  readonly size = input<number | string>(16);
  readonly color = input<string>('');
  readonly spin = input(false);
  /** Accessible name. Without it the icon is decorative and hidden from screen readers. */
  readonly label = input<string>('');

  protected readonly cssSize = computed(() => {
    const value = this.size();
    return typeof value === 'number' || /^\d+(\.\d+)?$/.test(value) ? `${value}px` : value;
  });

  /** Lucide wants a number of pixels. */
  protected readonly pixels = computed(() => {
    const value = this.size();
    if (typeof value === 'number') return value;
    const parsed = Number.parseFloat(value);
    if (Number.isNaN(parsed)) return 16;
    return /rem|em/.test(value) ? Math.round(parsed * 16) : parsed;
  });
}
