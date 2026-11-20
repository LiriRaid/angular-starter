import { ChangeDetectionStrategy, Component, booleanAttribute, input, output } from '@angular/core';

/**
 * A row or card the user can pick, with a title and a subtitle; content you project goes on the
 * right. It is a button: it works with the keyboard and announces whether it is selected.
 *
 * ```html
 * <as-selectable-item title="Ada Lovelace" subtitle="ada@example.com" [selected]="picked === 1" (itemClick)="picked = 1" />
 * ```
 */
@Component({
  selector: 'as-selectable-item',
  templateUrl: './as-selectable-item.html',
  styleUrl: './as-selectable-item.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { '[style.--as-selectable-accent]': 'accentColor()' },
})
export class AsSelectableItem {
  readonly title = input<string>('');
  readonly subtitle = input<string>('');
  readonly selected = input(false, { transform: booleanAttribute });
  /** Looks faded, for items that are not available right now. */
  readonly dimmed = input(false, { transform: booleanAttribute });
  readonly disabled = input(false, { transform: booleanAttribute });
  /** Any CSS color for the mark of the selected state. */
  readonly accentColor = input<string>('var(--as-primary)');

  readonly itemClick = output<void>();
}
