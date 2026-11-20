import { Directive, signal } from '@angular/core';
import type { ControlValueAccessor } from '@angular/forms';

let nextId = 0;

/**
 * What every form component of the starter shares: the plumbing of `ControlValueAccessor`, so the
 * component works with `formControl`, `formControlName` and `ngModel`, plus a unique id for its
 * label and messages. Extend it and call `update(value)` when the user changes the value.
 */
@Directive()
export abstract class AsFormControl<T> implements ControlValueAccessor {
  protected readonly uid = `as-control-${nextId++}`;

  /** The current value. */
  protected readonly value = signal<T>(this.empty());
  /** Disabled by the form (`control.disable()`), as opposed to the `disabled` input. */
  protected readonly disabledByForm = signal(false);

  private emitChange: (value: T) => void = () => undefined;
  private emitTouched: () => void = () => undefined;

  /** The value of a control that has none yet. */
  protected abstract empty(): T;

  writeValue(value: T | null | undefined): void {
    this.value.set(value ?? this.empty());
  }

  registerOnChange(callback: (value: T) => void): void {
    this.emitChange = callback;
  }

  registerOnTouched(callback: () => void): void {
    this.emitTouched = callback;
  }

  setDisabledState(disabled: boolean): void {
    this.disabledByForm.set(disabled);
  }

  /** Stores the value the user chose and tells the form. */
  protected update(value: T): void {
    this.value.set(value);
    this.emitChange(value);
  }

  protected touch(): void {
    this.emitTouched();
  }
}
