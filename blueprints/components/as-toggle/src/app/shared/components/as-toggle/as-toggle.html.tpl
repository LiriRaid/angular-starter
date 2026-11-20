<button
  type="button"
  class="as-toggle"
  role="switch"
  [attr.aria-checked]="value()"
  [attr.aria-label]="label() || null"
  [disabled]="isDisabled()"
  (click)="toggle()"
  (blur)="touch()"
>
  <span class="as-toggle__track"><span class="as-toggle__thumb"></span></span>
  @if (label()) {
    <span class="as-toggle__label">{{ label() }}</span>
  }
</button>
