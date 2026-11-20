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
 * A multi-line text field with its label, hint, error and an optional character counter.
 *
 * ```html
 * <as-textarea label="Notes" [rows]="4" [maxlength]="200" [formControl]="notes" />
 * ```
 */
@Component({
  selector: 'as-textarea',
  templateUrl: './as-textarea.html',
  styleUrl: './as-textarea.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [{ provide: NG_VALUE_ACCESSOR, useExisting: forwardRef(() => AsTextarea), multi: true }],
})
export class AsTextarea extends AsFormControl<string> {
  readonly label = input<string>('');
  readonly placeholder = input<string>('');
  readonly hint = input<string>('');
  readonly error = input<string>('');
  readonly rows = input<number>(3);
  readonly maxlength = input<number | null>(null);
  readonly required = input(false, { transform: booleanAttribute });
  readonly readonly = input(false, { transform: booleanAttribute });
  readonly disabled = input(false, { transform: booleanAttribute });
  /** Grows with the text instead of showing a scrollbar. */
  readonly autoResize = input(false, { transform: booleanAttribute });

  protected readonly isDisabled = computed(() => this.disabled() || this.disabledByForm());
  protected readonly count = computed(() => this.value().length);
  protected readonly describedBy = computed(() => {
    if (this.error()) return `${this.uid}-error`;
    return this.hint() ? `${this.uid}-hint` : null;
  });

  protected override empty(): string {
    return '';
  }

  protected onInput(event: Event): void {
    const textarea = event.target as HTMLTextAreaElement;
    if (this.autoResize()) {
      textarea.style.height = 'auto';
      textarea.style.height = `${textarea.scrollHeight}px`;
    }
    this.update(textarea.value);
  }
}
