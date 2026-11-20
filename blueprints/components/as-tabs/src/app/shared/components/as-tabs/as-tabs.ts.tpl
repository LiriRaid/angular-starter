import { ChangeDetectionStrategy, Component, input, model } from '@angular/core';
import { AsIcon } from '../as-icon/as-icon';

export interface AsTab {
  id: string;
  label: string;
  /** Name of an icon (see `as-icon`). */
  icon?: string;
  /** A small number or text next to the label, for example a counter. */
  badge?: string | number;
  disabled?: boolean;
}

/**
 * A row of tabs. It only manages the tab strip: show the content of the selected tab yourself.
 *
 * ```html
 * <as-tabs [tabs]="tabs" [(selected)]="current" />
 * @switch (current()) {
 *   @case ('profile') { <app-profile /> }
 *   @case ('billing') { <app-billing /> }
 * }
 * ```
 */
@Component({
  selector: 'as-tabs',
  imports: [AsIcon],
  templateUrl: './as-tabs.html',
  styleUrl: './as-tabs.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AsTabs {
  readonly tabs = input<readonly AsTab[]>([]);
  /** The id of the selected tab. Two-way: `[(selected)]="current"`. */
  readonly selected = model<string>('');
  readonly label = input<string>('Tabs');

  protected select(tab: AsTab): void {
    if (!tab.disabled) this.selected.set(tab.id);
  }

  /** Arrow keys, Home and End move between the tabs that are not disabled. */
  protected onKeydown(event: KeyboardEvent): void {
    const enabled = this.tabs().filter((tab) => !tab.disabled);
    if (enabled.length === 0) return;
    const index = enabled.findIndex((tab) => tab.id === this.selected());

    let next: number;
    switch (event.key) {
      case 'ArrowRight':
        next = (index + 1) % enabled.length;
        break;
      case 'ArrowLeft':
        next = (index - 1 + enabled.length) % enabled.length;
        break;
      case 'Home':
        next = 0;
        break;
      case 'End':
        next = enabled.length - 1;
        break;
      default:
        return;
    }
    event.preventDefault();
    const tab = enabled[next];
    if (!tab) return;
    this.selected.set(tab.id);
    (event.currentTarget as HTMLElement).querySelector<HTMLElement>(`[data-tab="${tab.id}"]`)?.focus();
  }
}
