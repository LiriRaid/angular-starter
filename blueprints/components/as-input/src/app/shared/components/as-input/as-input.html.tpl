<div class="as-field">
  @if (label()) {
    <label class="as-field__label" [attr.for]="uid">
      {{ label() }}
      @if (required()) {
        <span class="as-field__required" aria-hidden="true">*</span>
      }
    </label>
  }
  <div
    class="as-field__control"
    [class.as-field__control--invalid]="!!error()"
    [class.as-field__control--disabled]="isDisabled()"
  >
    @if (icon()) {
      <as-icon class="as-field__icon" [name]="icon()" [size]="16" />
    }
    <input
      class="as-field__input"
      [id]="uid"
      [type]="inputType()"
      [value]="value()"
      [placeholder]="placeholder()"
      [disabled]="isDisabled()"
      [readOnly]="readonly()"
      [required]="required()"
      [attr.autocomplete]="autocomplete()"
      [attr.maxlength]="maxlength()"
      [attr.aria-invalid]="error() ? 'true' : null"
      [attr.aria-describedby]="describedBy()"
      (input)="onInput($event)"
      (blur)="touch()"
    />
    @if (type() === 'password') {
      <button
        type="button"
        class="as-field__action"
        [attr.aria-label]="inputType() === 'password' ? 'Show password' : 'Hide password'"
        [disabled]="isDisabled()"
        (click)="toggleReveal()"
      >
        <as-icon [name]="inputType() === 'password' ? 'eye' : 'eye-off'" [size]="16" />
      </button>
    }
  </div>
  @if (error()) {
    <p class="as-field__error" role="alert" [id]="uid + '-error'">{{ error() }}</p>
  } @else if (hint()) {
    <p class="as-field__hint" [id]="uid + '-hint'">{{ hint() }}</p>
  }
</div>
