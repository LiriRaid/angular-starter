import { ChangeDetectionStrategy, Component, forwardRef, input, signal, ViewEncapsulation } from '@angular/core';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';

import { SaIcon } from '../sa-icon/sa-icon';

@Component({
  selector: 'sa-checkbox',
  standalone: true,
  imports: [SaIcon],
  templateUrl: './sa-checkbox.html',
  styleUrl: './sa-checkbox.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
  providers: [{ provide: NG_VALUE_ACCESSOR, useExisting: forwardRef(() => SaCheckbox), multi: true }],
  host: {
    '[class.sa-checkbox-checked]': 'value()',
    '[class.sa-checkbox-indeterminate]': 'indeterminate() && !value()',
    '[class.sa-checkbox-disabled]': 'isDisabled()',
    '[attr.data-sa-checked]': 'value()',
    '[attr.data-sa-disabled]': 'isDisabled()',
  },
})
export class SaCheckbox implements ControlValueAccessor {
  readonly inputId = input<string>('');
  readonly ariaLabel = input<string | undefined>(undefined);
  readonly ariaLabelledBy = input<string | undefined>(undefined);
  /** Solo marca el atributo nativo `indeterminate` del `<input>` (para lectores de pantalla) —
   *  no tiene tratamiento visual propio a propósito: con selección parcial (ej. el "seleccionar
   *  todos" de la tabla) el checkbox debe verse igual que sin selección, y solo pintarse cuando
   *  esté 100% seleccionado. No forma parte del value del control. */
  readonly indeterminate = input<boolean>(false);

  readonly value = signal(false);
  readonly isDisabled = signal(false);

  onChange: (value: boolean) => void = () => {};
  onTouched: () => void = () => {};

  writeValue(value: unknown): void {
    this.value.set(!!value);
  }

  registerOnChange(fn: (value: boolean) => void): void {
    this.onChange = fn;
  }

  registerOnTouched(fn: () => void): void {
    this.onTouched = fn;
  }

  setDisabledState(isDisabled: boolean): void {
    this.isDisabled.set(isDisabled);
  }

  handleChange(): void {
    const next = !this.value();
    this.value.set(next);
    this.onChange(next);
  }

  onInputBlur(): void {
    this.onTouched();
  }
}
