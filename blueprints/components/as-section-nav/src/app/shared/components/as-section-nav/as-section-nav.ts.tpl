import { ChangeDetectionStrategy, Component, input, model } from '@angular/core';
import { AsIcon } from '../as-icon/as-icon';

export interface AsSectionNavItem {
  id: string;
  label: string;
  /** Name of an icon (see `as-icon`). */
  icon?: string;
  /** A line under the label. */
  description?: string;
  disabled?: boolean;
}

/**
 * A titled list of sections for a settings or admin page, with the current one highlighted.
 *
 * ```html
 * <as-section-nav title="Settings" description="Account and team" [items]="sections" [(selected)]="section" />
 * ```
 */
@Component({
  selector: 'as-section-nav',
  imports: [AsIcon],
  templateUrl: './as-section-nav.html',
  styleUrl: './as-section-nav.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AsSectionNav {
  readonly title = input<string>('');
  readonly description = input<string>('');
  readonly items = input<readonly AsSectionNavItem[]>([]);
  /** The id of the current section. Two-way: `[(selected)]="section"`. */
  readonly selected = model<string>('');

  protected select(item: AsSectionNavItem): void {
    if (!item.disabled) this.selected.set(item.id);
  }
}
