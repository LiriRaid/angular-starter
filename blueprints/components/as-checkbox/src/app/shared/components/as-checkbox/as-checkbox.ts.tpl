import {
  ChangeDetectionStrategy,
  Component,
  booleanAttribute,
  computed,
  forwardRef,
  input,
} from '@angular/core';
import { NG_VALUE_ACCESSOR } from '@angular/forms';
import { AsFormControl } from '../as-form-control/as-form-control';

/**
 * A checkbox with its label. A form control of `boolean`.
 *
 * ```html
 * <as-checkbox label="Remember me" [formControl]="remember" />
 * <as-checkbox label="Select all" [indeterminate]="someSelected" [(ngModel)]="all" />
 * ```
 */
@Component({
  selector: 'as-checkbox',
  templateUrl: './as-checkbox.html',
  styleUrl: './as-checkbox.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [{ provide: NG_VALUE_ACCESSOR, useExisting: forwardRef(() => AsCheckbox), multi: true }],
})
export class AsCheckbox extends AsFormControl<boolean> {
  readonly label = input<string>('');
  /** Shows a dash instead of a check, for a "some of them" state. */
  readonly indeterminate = input(false, { transform: booleanAttribute });
  readonly disabled = input(false, { transform: booleanAttribute });

  protected readonly isDisabled = computed(() => this.disabled() || this.disabledByForm());

  protected override empty(): boolean {
    return false;
  }

  protected onToggle(event: Event): void {
    this.update((event.target as HTMLInputElement).checked);
  }
}
