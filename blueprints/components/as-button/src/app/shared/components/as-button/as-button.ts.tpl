import { NgTemplateOutlet } from '@angular/common';
import {
  ChangeDetectionStrategy,
  Component,
  booleanAttribute,
  computed,
  input,
  output,
} from '@angular/core';
import { AsIcon } from '../as-icon/as-icon';

export type AsButtonSeverity = 'primary' | 'secondary' | 'success' | 'info' | 'warn' | 'danger';
export type AsButtonVariant = 'solid' | 'outlined' | 'text';
export type AsButtonSize = 'sm' | 'md' | 'lg';

/**
 * A button, or a link when it has an `href`.
 *
 * ```html
 * <as-button label="Save" icon="save" (clicked)="save()" />
 * <as-button label="Delete" severity="danger" variant="outlined" />
 * <as-button icon="plus" ariaLabel="Add" variant="text" />
 * <as-button label="Docs" href="https://angular.dev" target="_blank" />
 * ```
 */
@Component({
  selector: 'as-button',
  imports: [AsIcon, NgTemplateOutlet],
  templateUrl: './as-button.html',
  styleUrl: './as-button.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { '[class.as-button--block]': 'block()' },
})
export class AsButton {
  readonly label = input<string>('');
  /** Name of an icon (see `as-icon`). */
  readonly icon = input<string>('');
  readonly iconPosition = input<'left' | 'right'>('left');
  readonly severity = input<AsButtonSeverity>('primary');
  readonly variant = input<AsButtonVariant>('solid');
  readonly size = input<AsButtonSize>('md');
  readonly type = input<'button' | 'submit' | 'reset'>('button');
  readonly loading = input(false, { transform: booleanAttribute });
  readonly disabled = input(false, { transform: booleanAttribute });
  /** Makes the button fill the width of its container. */
  readonly block = input(false, { transform: booleanAttribute });
  /** Turns the button into a link. */
  readonly href = input<string>('');
  readonly target = input<string>('');
  /** Required when the button has an icon and no label. */
  readonly ariaLabel = input<string>('');

  /** Emits the click, unless the button is disabled or loading. */
  readonly clicked = output<MouseEvent>();

  protected readonly inactive = computed(() => this.disabled() || this.loading());
  protected readonly classes = computed(
    () => `as-btn as-btn--${this.variant()} as-btn--${this.severity()} as-btn--${this.size()}`,
  );
  protected readonly iconOnly = computed(() => !this.label() && !!this.icon());

  protected handleClick(event: MouseEvent): void {
    if (this.inactive()) {
      event.preventDefault();
      return;
    }
    this.clicked.emit(event);
  }
}
