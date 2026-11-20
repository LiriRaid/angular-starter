import { ChangeDetectionStrategy, Component, forwardRef, input, signal, ViewEncapsulation } from '@angular/core';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';

import { AsIcon } from '../as-icon/as-icon';

@Component({
  selector: 'as-checkbox',
  standalone: true,
  imports: [AsIcon],
  templateUrl: './as-checkbox.html',
  styleUrl: './as-checkbox.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
  providers: [{ provide: NG_VALUE_ACCESSOR, useExisting: forwardRef(() => AsCheckbox), multi: true }],
  host: {
    '[class.as-checkbox-checked]': 'value()',
    '[class.as-checkbox-indeterminate]': 'indeterminate() && !value()',
    '[class.as-checkbox-disabled]': 'isDisabled()',
    '[attr.data-as-checked]': 'value()',
    '[attr.data-as-disabled]': 'isDisabled()',
  },
})
export class AsCheckbox implements ControlValueAccessor {
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
