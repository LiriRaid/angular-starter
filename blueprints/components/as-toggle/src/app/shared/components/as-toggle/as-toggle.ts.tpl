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
 * An on/off switch with its label. A form control of `boolean`.
 *
 * ```html
 * <as-toggle label="Email notifications" [formControl]="notifications" />
 * ```
 */
@Component({
  selector: 'as-toggle',
  templateUrl: './as-toggle.html',
  styleUrl: './as-toggle.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [{ provide: NG_VALUE_ACCESSOR, useExisting: forwardRef(() => AsToggle), multi: true }],
})
export class AsToggle extends AsFormControl<boolean> {
  readonly label = input<string>('');
  readonly disabled = input(false, { transform: booleanAttribute });

  protected readonly isDisabled = computed(() => this.disabled() || this.disabledByForm());

  protected override empty(): boolean {
    return false;
  }

  protected toggle(): void {
    if (!this.isDisabled()) this.update(!this.value());
  }
}
