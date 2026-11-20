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
import { formatDate } from '../../utils/date-time';
import { AsFormControl } from '../as-form-control/as-form-control';
import { AsIcon } from '../as-icon/as-icon';

interface CalendarDay {
  date: Date;
  inMonth: boolean;
  disabled: boolean;
  today: boolean;
  selected: boolean;
}

const sameDay = (a: Date | null, b: Date): boolean =>
  !!a && a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();

const startOfDay = (date: Date): Date => new Date(date.getFullYear(), date.getMonth(), date.getDate());

/**
 * A date field with a calendar. A form control whose value is a `Date` (or `null`); it works with
 * the keyboard (arrows move between days, Enter picks, Escape closes).
 *
 * ```html
 * <as-datepicker label="Birthday" [max]="today" [formControl]="birthday" />
 * ```
 */
@Component({
  selector: 'as-datepicker',
  imports: [AsIcon],
  templateUrl: './as-datepicker.html',
  styleUrl: './as-datepicker.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [{ provide: NG_VALUE_ACCESSOR, useExisting: forwardRef(() => AsDatepicker), multi: true }],
  host: {
    '(document:click)': 'closeOnOutsideClick($event)',
    '(keydown.escape)': 'close()',
  },
})
export class AsDatepicker extends AsFormControl<Date | null> {
  readonly label = input<string>('');
  readonly placeholder = input<string>('Select a date');
  readonly hint = input<string>('');
  readonly error = input<string>('');
  readonly min = input<Date | null>(null);
  readonly max = input<Date | null>(null);
  /** BCP 47 language tag for the month and weekday names; the browser's when absent. */
  readonly locale = input<string | undefined>(undefined);
  /** 0 for Sunday, 1 for Monday. */
  readonly weekStartsOn = input<0 | 1>(0);
  readonly required = input(false, { transform: booleanAttribute });
  readonly disabled = input(false, { transform: booleanAttribute });

  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef).nativeElement;

  protected readonly open = signal(false);
  /** The first day of the month on display. */
  protected readonly month = signal(startOfDay(new Date()));
  /** The day the keyboard is on. */
  protected readonly active = signal(startOfDay(new Date()));

  protected readonly isDisabled = computed(() => this.disabled() || this.disabledByForm());
  protected readonly text = computed(() => {
    const date = this.value();
    return date ? formatDate(date, this.locale()) : '';
  });
  protected readonly title = computed(() =>
    new Intl.DateTimeFormat(this.locale(), { month: 'long', year: 'numeric' }).format(this.month()),
  );
  protected readonly weekdays = computed(() => {
    const format = new Intl.DateTimeFormat(this.locale(), { weekday: 'short' });
    // 2023-01-01 was a Sunday.
    return Array.from({ length: 7 }, (_, index) =>
      format.format(new Date(2023, 0, 1 + ((index + this.weekStartsOn()) % 7))),
    );
  });
  protected readonly weeks = computed<CalendarDay[][]>(() => {
    const month = this.month();
    const first = new Date(month.getFullYear(), month.getMonth(), 1);
    const offset = (first.getDay() - this.weekStartsOn() + 7) % 7;
    const today = new Date();
    const selected = this.value();
    const days: CalendarDay[] = Array.from({ length: 42 }, (_, index) => {
      const date = new Date(first.getFullYear(), first.getMonth(), 1 - offset + index);
      return {
        date,
        inMonth: date.getMonth() === first.getMonth(),
        disabled: this.outOfRange(date),
        today: sameDay(today, date),
        selected: sameDay(selected, date),
      };
    });
    return Array.from({ length: 6 }, (_, week) => days.slice(week * 7, week * 7 + 7));
  });

  protected override empty(): Date | null {
    return null;
  }

  protected toggle(): void {
    if (this.isDisabled()) return;
    if (this.open()) return this.close();
    const base = this.value() ?? new Date();
    this.active.set(startOfDay(base));
    this.month.set(new Date(base.getFullYear(), base.getMonth(), 1));
    this.open.set(true);
  }

  protected close(): void {
    if (this.open()) this.touch();
    this.open.set(false);
  }

  protected closeOnOutsideClick(event: Event): void {
    if (this.open() && !this.host.contains(event.target as Node)) this.close();
  }

  protected shiftMonth(step: number): void {
    const month = this.month();
    this.month.set(new Date(month.getFullYear(), month.getMonth() + step, 1));
  }

  protected pick(day: CalendarDay): void {
    if (day.disabled) return;
    this.update(startOfDay(day.date));
    this.close();
  }

  protected clear(): void {
    this.update(null);
  }

  protected onGridKeydown(event: KeyboardEvent): void {
    const steps: Record<string, number> = { ArrowLeft: -1, ArrowRight: 1, ArrowUp: -7, ArrowDown: 7 };
    const step = steps[event.key];
    if (step === undefined) return;
    event.preventDefault();
    const active = this.active();
    const next = new Date(active.getFullYear(), active.getMonth(), active.getDate() + step);
    this.active.set(next);
    this.month.set(new Date(next.getFullYear(), next.getMonth(), 1));
    queueMicrotask(() => this.host.querySelector<HTMLElement>('[data-active="true"]')?.focus());
  }

  private outOfRange(date: Date): boolean {
    const min = this.min();
    const max = this.max();
    return (!!min && date < startOfDay(min)) || (!!max && date > startOfDay(max));
  }
}
