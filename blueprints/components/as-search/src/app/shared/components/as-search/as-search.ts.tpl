import {
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  inject,
  input,
  model,
  output,
} from '@angular/core';
import { createTimer } from '../../utils/safe-timeout';
import { AsIcon } from '../as-icon/as-icon';

/**
 * A search field: the text is available at once through `value`, and `search` fires once the user
 * stops typing (or presses Enter), so you can query a server without sending a request per key.
 *
 * ```html
 * <as-search placeholder="Find a customer" (search)="query.set($event)" />
 * ```
 */
@Component({
  selector: 'as-search',
  imports: [AsIcon],
  templateUrl: './as-search.html',
  styleUrl: './as-search.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AsSearch {
  /** The text in the field. Two-way: `[(value)]="text"`. */
  readonly value = model('');
  readonly placeholder = input<string>('Search...');
  /** Milliseconds to wait after the last key before `search` fires. */
  readonly debounce = input<number>(300);
  readonly label = input<string>('Search');

  /** The text to search for, after the pause or with Enter. */
  readonly search = output<string>();

  private readonly timer = createTimer(inject(DestroyRef));

  protected onInput(event: Event): void {
    const text = (event.target as HTMLInputElement).value;
    this.value.set(text);
    this.timer.set(() => this.search.emit(text), this.debounce());
  }

  protected submit(): void {
    this.timer.clear();
    this.search.emit(this.value());
  }

  protected clear(): void {
    this.timer.clear();
    this.value.set('');
    this.search.emit('');
  }
}
