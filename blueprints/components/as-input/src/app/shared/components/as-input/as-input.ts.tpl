import {
  ChangeDetectionStrategy,
  Component,
  booleanAttribute,
  computed,
  forwardRef,
  input,
  signal,
} from '@angular/core';
import { NG_VALUE_ACCESSOR } from '@angular/forms';
import { AsFormControl } from '../as-form-control/as-form-control';
import { AsIcon } from '../as-icon/as-icon';

export type AsInputType = 'text' | 'email' | 'password' | 'number' | 'search' | 'tel' | 'url';

/**
 * A text field with its label, hint and error. It is a form control: use it with `formControl`,
 * `formControlName` or `ngModel`.
 *
 * ```html
 * <as-input label="Email" type="email" [formControl]="email" [error]="emailError()" />
 * <as-input label="Search" icon="search" placeholder="Find a customer" [(ngModel)]="query" />
 * ```
 */
@Component({
  selector: 'as-input',
  imports: [AsIcon],
  templateUrl: './as-input.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [{ provide: NG_VALUE_ACCESSOR, useExisting: forwardRef(() => AsInput), multi: true }],
  host: { '[class.as-field-host]': 'true' },
})
export class AsInput extends AsFormControl<string> {
  readonly label = input<string>('');
  readonly type = input<AsInputType>('text');
  readonly placeholder = input<string>('');
  readonly hint = input<string>('');
  /** An error message; while it is set the field looks invalid. */
  readonly error = input<string>('');
  /** Name of an icon shown at the start of the field. */
  readonly icon = input<string>('');
  readonly required = input(false, { transform: booleanAttribute });
  readonly readonly = input(false, { transform: booleanAttribute });
  readonly disabled = input(false, { transform: booleanAttribute });
  readonly autocomplete = input<string>('off');
  readonly maxlength = input<number | null>(null);

  private readonly revealed = signal(false);

  protected readonly isDisabled = computed(() => this.disabled() || this.disabledByForm());
  protected readonly inputType = computed(() =>
    this.type() === 'password' && this.revealed() ? 'text' : this.type(),
  );
  protected readonly describedBy = computed(() => {
    if (this.error()) return `${this.uid}-error`;
    return this.hint() ? `${this.uid}-hint` : null;
  });

  protected override empty(): string {
    return '';
  }

  protected onInput(event: Event): void {
    this.update((event.target as HTMLInputElement).value);
  }

  protected toggleReveal(): void {
    this.revealed.update((value) => !value);
  }
}
