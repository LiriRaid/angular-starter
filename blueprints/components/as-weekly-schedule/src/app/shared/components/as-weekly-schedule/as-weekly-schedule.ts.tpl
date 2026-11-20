import {
  ChangeDetectionStrategy,
  Component,
  booleanAttribute,
  computed,
  forwardRef,
  input,
} from '@angular/core';
import { FormsModule, NG_VALUE_ACCESSOR } from '@angular/forms';
import { AsFormControl } from '../as-form-control/as-form-control';
import { AsToggle } from '../as-toggle/as-toggle';

/** One day of the schedule. `day` is 0 for Sunday up to 6 for Saturday; times are `HH:mm`. */
export interface AsScheduleDay {
  day: number;
  enabled: boolean;
  start: string;
  end: string;
}

/** Monday to Friday, 09:00 to 17:00. */
export function defaultSchedule(): AsScheduleDay[] {
  return Array.from({ length: 7 }, (_, day) => ({
    day,
    enabled: day >= 1 && day <= 5,
    start: '09:00',
    end: '17:00',
  }));
}

const minutes = (time: string): number => {
  const [hours = '0', mins = '0'] = time.split(':');
  return Number(hours) * 60 + Number(mins);
};

/** Whether the day is open for a positive amount of time. */
export const isValidDay = (day: AsScheduleDay): boolean => minutes(day.end) > minutes(day.start);

/** The hours the schedule is open in a week, counting only valid enabled days. */
export function computeWeeklyHours(days: readonly AsScheduleDay[]): number {
  const total = days
    .filter((day) => day.enabled && isValidDay(day))
    .reduce((sum, day) => sum + minutes(day.end) - minutes(day.start), 0);
  return total / 60;
}

/**
 * An editor for opening hours: a switch and a start and end time for each day of the week. A form
 * control of `AsScheduleDay[]`.
 *
 * ```html
 * <as-weekly-schedule label="Opening hours" [formControl]="hours" />
 * ```
 */
@Component({
  selector: 'as-weekly-schedule',
  imports: [AsToggle, FormsModule],
  templateUrl: './as-weekly-schedule.html',
  styleUrl: './as-weekly-schedule.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    { provide: NG_VALUE_ACCESSOR, useExisting: forwardRef(() => AsWeeklySchedule), multi: true },
  ],
})
export class AsWeeklySchedule extends AsFormControl<AsScheduleDay[]> {
  readonly label = input<string>('Weekly schedule');
  /** BCP 47 language tag for the names of the days; the browser's when absent. */
  readonly locale = input<string | undefined>(undefined);
  readonly disabled = input(false, { transform: booleanAttribute });

  protected readonly isDisabled = computed(() => this.disabled() || this.disabledByForm());
  protected readonly hours = computed(() => computeWeeklyHours(this.value()));
  protected readonly dayName = computed(() => {
    const format = new Intl.DateTimeFormat(this.locale(), { weekday: 'long' });
    // 2023-01-01 was a Sunday.
    return (day: number): string => format.format(new Date(2023, 0, 1 + day));
  });

  protected override empty(): AsScheduleDay[] {
    return defaultSchedule();
  }

  protected isInvalid(day: AsScheduleDay): boolean {
    return day.enabled && !isValidDay(day);
  }

  protected patch(day: number, change: Partial<AsScheduleDay>): void {
    this.update(this.value().map((entry) => (entry.day === day ? { ...entry, ...change } : entry)));
  }

  protected onTime(day: number, field: 'start' | 'end', event: Event): void {
    this.patch(day, { [field]: (event.target as HTMLInputElement).value });
  }
}
