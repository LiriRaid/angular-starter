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
    class="as-field__control as-textarea__control"
    [class.as-field__control--invalid]="!!error()"
    [class.as-field__control--disabled]="isDisabled()"
  >
    <textarea
      class="as-field__input as-textarea__input"
      [id]="uid"
      [value]="value()"
      [rows]="rows()"
      [placeholder]="placeholder()"
      [disabled]="isDisabled()"
      [readOnly]="readonly()"
      [required]="required()"
      [attr.maxlength]="maxlength()"
      [attr.aria-invalid]="error() ? 'true' : null"
      [attr.aria-describedby]="describedBy()"
      (input)="onInput($event)"
      (blur)="touch()"
    ></textarea>
  </div>
  <div class="as-textarea__footer">
    @if (error()) {
      <p class="as-field__error" role="alert" [id]="uid + '-error'">{{ error() }}</p>
    } @else if (hint()) {
      <p class="as-field__hint" [id]="uid + '-hint'">{{ hint() }}</p>
    }
    @if (maxlength()) {
      <span class="as-textarea__count">{{ count() }}/{{ maxlength() }}</span>
    }
  </div>
</div>
