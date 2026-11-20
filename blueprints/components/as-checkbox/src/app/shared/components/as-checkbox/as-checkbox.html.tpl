<input
  type="checkbox"
  class="as-checkbox-input"
  [attr.id]="inputId() || null"
  [checked]="value()"
  [indeterminate]="indeterminate() && !value()"
  [disabled]="isDisabled()"
  [attr.aria-label]="ariaLabel() || null"
  [attr.aria-labelledby]="ariaLabelledBy() || null"
  (change)="handleChange()"
  (blur)="onInputBlur()"
/>

<div class="as-checkbox-box">
  @if (value()) {
    <as-icon name="Check" size="18" class="as-checkbox-icon" />
  }
</div>
