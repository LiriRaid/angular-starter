<input
  type="checkbox"
  class="sa-checkbox-input"
  [attr.id]="inputId() || null"
  [checked]="value()"
  [indeterminate]="indeterminate() && !value()"
  [disabled]="isDisabled()"
  [attr.aria-label]="ariaLabel() || null"
  [attr.aria-labelledby]="ariaLabelledBy() || null"
  (change)="handleChange()"
  (blur)="onInputBlur()"
/>

<div class="sa-checkbox-box">
  @if (value()) {
    <sa-icon name="Check" size="18" class="sa-checkbox-icon" />
  }
</div>
