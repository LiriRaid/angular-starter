<fieldset class="as-schedule" [disabled]="isDisabled()">
  <legend class="as-field__label">{{ label() }}</legend>
  @for (entry of value(); track entry.day) {
    <div class="as-schedule__row" [class.as-schedule__row--invalid]="isInvalid(entry)">
      <as-toggle class="as-schedule__day" [label]="dayName()(entry.day)" [ngModel]="entry.enabled" (ngModelChange)="patch(entry.day, { enabled: $event })" />
      <input
        class="as-schedule__time"
        type="time"
        [attr.aria-label]="dayName()(entry.day) + ' opens'"
        [value]="entry.start"
        [disabled]="!entry.enabled || isDisabled()"
        (change)="onTime(entry.day, 'start', $event)"
      />
      <span aria-hidden="true">–</span>
      <input
        class="as-schedule__time"
        type="time"
        [attr.aria-label]="dayName()(entry.day) + ' closes'"
        [value]="entry.end"
        [disabled]="!entry.enabled || isDisabled()"
        (change)="onTime(entry.day, 'end', $event)"
      />
      @if (isInvalid(entry)) {
        <span class="as-field__error" role="alert">Closing time must be after opening time</span>
      }
    </div>
  }
  <p class="as-schedule__total">{{ hours() }} hours a week</p>
</fieldset>
