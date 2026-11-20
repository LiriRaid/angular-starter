<label class="as-checkbox" [class.as-checkbox--disabled]="isDisabled()">
  <input
    class="as-checkbox__input"
    type="checkbox"
    [checked]="value()"
    [indeterminate]="indeterminate()"
    [disabled]="isDisabled()"
    [attr.aria-checked]="indeterminate() ? 'mixed' : value()"
    (change)="onToggle($event)"
    (blur)="touch()"
  />
  <span class="as-checkbox__box" aria-hidden="true"></span>
  @if (label()) {
    <span class="as-checkbox__label">{{ label() }}</span>
  }
</label>
