<div class="as-field as-datepicker">
  @if (label()) {
    <label class="as-field__label" [attr.id]="uid + '-label'">
      {{ label() }}
      @if (required()) {
        <span class="as-field__required" aria-hidden="true">*</span>
      }
    </label>
  }
  <button
    type="button"
    class="as-field__control as-datepicker__trigger"
    [class.as-field__control--invalid]="!!error()"
    [class.as-field__control--disabled]="isDisabled()"
    aria-haspopup="dialog"
    [attr.aria-expanded]="open()"
    [attr.aria-labelledby]="label() ? uid + '-label' : null"
    [disabled]="isDisabled()"
    (click)="toggle()"
  >
    <as-icon class="as-field__icon" name="calendar" [size]="16" />
    <span class="as-datepicker__text" [class.as-datepicker__text--placeholder]="!text()">{{ text() || placeholder() }}</span>
  </button>

  @if (open()) {
    <div class="as-datepicker__panel as-animate-slide-down" role="dialog" aria-label="Choose a date">
      <div class="as-datepicker__header">
        <button type="button" class="as-datepicker__nav" aria-label="Previous month" (click)="shiftMonth(-1)">
          <as-icon name="chevron-left" [size]="16" />
        </button>
        <span class="as-datepicker__title" aria-live="polite">{{ title() }}</span>
        <button type="button" class="as-datepicker__nav" aria-label="Next month" (click)="shiftMonth(1)">
          <as-icon name="chevron-right" [size]="16" />
        </button>
      </div>
      <table class="as-datepicker__grid" role="grid" (keydown)="onGridKeydown($event)">
        <thead>
          <tr>
            @for (weekday of weekdays(); track $index) {
              <th scope="col" class="as-datepicker__weekday">{{ weekday }}</th>
            }
          </tr>
        </thead>
        <tbody>
          @for (week of weeks(); track $index) {
            <tr>
              @for (day of week; track day.date.getTime()) {
                <td>
                  <button
                    type="button"
                    class="as-datepicker__day"
                    [class.as-datepicker__day--outside]="!day.inMonth"
                    [class.as-datepicker__day--today]="day.today"
                    [class.as-datepicker__day--selected]="day.selected"
                    [attr.data-active]="day.date.getTime() === active().getTime()"
                    [attr.tabindex]="day.date.getTime() === active().getTime() ? 0 : -1"
                    [attr.aria-selected]="day.selected"
                    [disabled]="day.disabled"
                    (click)="pick(day)"
                  >
                    {{ day.date.getDate() }}
                  </button>
                </td>
              }
            </tr>
          }
        </tbody>
      </table>
      @if (value()) {
        <button type="button" class="as-datepicker__clear" (click)="clear()">Clear</button>
      }
    </div>
  }

  @if (error()) {
    <p class="as-field__error" role="alert">{{ error() }}</p>
  } @else if (hint()) {
    <p class="as-field__hint">{{ hint() }}</p>
  }
</div>
