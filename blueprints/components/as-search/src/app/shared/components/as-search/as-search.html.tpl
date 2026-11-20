<div class="as-field__control as-search" role="search">
  <as-icon class="as-field__icon" name="search" [size]="16" />
  <input
    class="as-field__input"
    type="search"
    [value]="value()"
    [placeholder]="placeholder()"
    [attr.aria-label]="label()"
    (input)="onInput($event)"
    (keydown.enter)="submit()"
  />
  @if (value()) {
    <button type="button" class="as-field__action" aria-label="Clear search" (click)="clear()">
      <as-icon name="x" [size]="16" />
    </button>
  }
</div>
