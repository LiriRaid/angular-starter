import { ChangeDetectionStrategy, Component, input } from '@angular/core';

/**
 * A line that separates content, horizontal or vertical, with an optional text in it.
 *
 * ```html
 * <as-divider />
 * <as-divider label="or" align="center" />
 * <as-divider orientation="vertical" />
 * ```
 */
@Component({
  selector: 'as-divider',
  templateUrl: './as-divider.html',
  styleUrl: './as-divider.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    role: 'separator',
    '[attr.aria-orientation]': 'orientation()',
    '[class.as-divider--vertical]': 'orientation() === "vertical"',
    '[class.as-divider--dashed]': 'style() === "dashed"',
    '[attr.data-align]': 'label() ? align() : null',
  },
})
export class AsDivider {
  readonly orientation = input<'horizontal' | 'vertical'>('horizontal');
  readonly style = input<'solid' | 'dashed'>('solid');
  readonly label = input<string>('');
  /** Where the label sits on a horizontal divider. */
  readonly align = input<'start' | 'center' | 'end'>('center');
}
