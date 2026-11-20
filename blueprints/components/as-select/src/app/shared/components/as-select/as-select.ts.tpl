import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  booleanAttribute,
  computed,
  forwardRef,
  inject,
  input,
  signal,
} from '@angular/core';
import { NG_VALUE_ACCESSOR } from '@angular/forms';
import { AsFormControl } from '../as-form-control/as-form-control';
import { AsIcon } from '../as-icon/as-icon';

export interface AsSelectOption<T = string> {
  value: T;
  label: string;
  disabled?: boolean;
}

/**
 * A dropdown to pick one option, with keyboard support (arrows, Home, End, Enter, Escape). A form
 * control whose value is the `value` of the chosen option.
 *
 * ```html
 * <as-select label="Country" [options]="countries" placeholder="Choose one" [formControl]="country" />
 * ```
 */
@Component({
  selector: 'as-select',
  imports: [AsIcon],
  templateUrl: './as-select.html',
  styleUrl: './as-select.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [{ provide: NG_VALUE_ACCESSOR, useExisting: forwardRef(() => AsSelect), multi: true }],
  host: {
    '(document:click)': 'closeOnOutsideClick($event)',
    '(keydown)': 'onKeydown($event)',
  },
})
export class AsSelect extends AsFormControl<unknown> {
  readonly options = input<readonly AsSelectOption<unknown>[]>([]);
  readonly label = input<string>('');
  readonly placeholder = input<string>('Select...');
  readonly hint = input<string>('');
  readonly error = input<string>('');
  readonly required = input(false, { transform: booleanAttribute });
  readonly disabled = input(false, { transform: booleanAttribute });

  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef).nativeElement;

  protected readonly open = signal(false);
  /** The option the keyboard is on, while the list is open. */
  protected readonly active = signal(0);

  protected readonly isDisabled = computed(() => this.disabled() || this.disabledByForm());
  protected readonly selected = computed(
    () => this.options().find((option) => option.value === this.value()) ?? null,
  );
  protected readonly listId = computed(() => `${this.uid}-list`);

  protected override empty(): unknown {
    return null;
  }

  protected toggle(): void {
    if (this.isDisabled()) return;
    this.open() ? this.close() : this.openList();
  }

  protected choose(option: AsSelectOption<unknown>): void {
    if (option.disabled) return;
    this.update(option.value);
    this.close();
  }

  protected closeOnOutsideClick(event: Event): void {
    if (this.open() && !this.host.contains(event.target as Node)) this.close();
  }

  protected onKeydown(event: KeyboardEvent): void {
    if (this.isDisabled()) return;
    const count = this.options().length;
    switch (event.key) {
      case 'ArrowDown':
      case 'ArrowUp': {
        event.preventDefault();
        if (!this.open()) return this.openList();
        const step = event.key === 'ArrowDown' ? 1 : -1;
        this.active.set((this.active() + step + count) % Math.max(count, 1));
        break;
      }
      case 'Home':
      case 'End':
        if (this.open()) {
          event.preventDefault();
          this.active.set(event.key === 'Home' ? 0 : Math.max(count - 1, 0));
        }
        break;
      case 'Enter':
      case ' ': {
        const option = this.options()[this.active()];
        if (this.open() && option) {
          event.preventDefault();
          this.choose(option);
        }
        break;
      }
      case 'Escape':
        if (this.open()) {
          event.preventDefault();
          this.close();
        }
        break;
    }
  }

  private openList(): void {
    const index = this.options().findIndex((option) => option.value === this.value());
    this.active.set(Math.max(index, 0));
    this.open.set(true);
  }

  private close(): void {
    this.open.set(false);
    this.touch();
  }
}
