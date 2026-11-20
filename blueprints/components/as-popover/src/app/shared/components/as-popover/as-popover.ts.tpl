import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  inject,
  input,
  model,
  output,
} from '@angular/core';
import { AsIcon } from '../as-icon/as-icon';

export type AsPopoverPlacement = 'bottom-start' | 'bottom-end' | 'top-start' | 'top-end';

/** One entry of the menu a popover can show instead of free content. */
export interface AsPopoverItem {
  id: string;
  label: string;
  /** Name of an icon (see `as-icon`). */
  icon?: string;
  /** Colors the entry as a destructive action. */
  danger?: boolean;
  disabled?: boolean;
}

/**
 * A floating panel next to its trigger: free content, or a menu of actions with `items`. It closes
 * with Escape, when the user clicks outside and after choosing an item.
 *
 * ```html
 * <as-popover [(open)]="menuOpen" [items]="actions" (itemSelected)="run($event)">
 *   <button asPopoverTrigger (click)="menuOpen = !menuOpen">Actions</button>
 * </as-popover>
 *
 * <as-popover [(open)]="infoOpen" placement="top-start">
 *   <button asPopoverTrigger (click)="infoOpen = !infoOpen">Info</button>
 *   <p>Any content you like.</p>
 * </as-popover>
 * ```
 */
@Component({
  selector: 'as-popover',
  imports: [AsIcon],
  templateUrl: './as-popover.html',
  styleUrl: './as-popover.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    '(document:click)': 'closeOnOutsideClick($event)',
    '(keydown.escape)': 'open.set(false)',
  },
})
export class AsPopover {
  /** Two-way: `[(open)]="visible"`. */
  readonly open = model(false);
  readonly placement = input<AsPopoverPlacement>('bottom-start');
  /** When it has items the popover is a menu; without them it shows its content. */
  readonly items = input<readonly AsPopoverItem[]>([]);
  readonly itemSelected = output<AsPopoverItem>();

  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef).nativeElement;

  protected choose(item: AsPopoverItem): void {
    if (item.disabled) return;
    this.itemSelected.emit(item);
    this.open.set(false);
  }

  protected closeOnOutsideClick(event: Event): void {
    if (this.open() && !this.host.contains(event.target as Node)) this.open.set(false);
  }
}
