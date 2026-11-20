<div class="as-field as-select">
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
    class="as-field__control as-select__trigger"
    [class.as-field__control--invalid]="!!error()"
    [class.as-field__control--disabled]="isDisabled()"
    role="combobox"
    aria-haspopup="listbox"
    [attr.aria-expanded]="open()"
    [attr.aria-controls]="listId()"
    [attr.aria-labelledby]="label() ? uid + '-label' : null"
    [attr.aria-invalid]="error() ? 'true' : null"
    [disabled]="isDisabled()"
    (click)="toggle()"
  >
    <span class="as-select__value" [class.as-select__value--placeholder]="!selected()">
      {{ selected()?.label ?? placeholder() }}
    </span>
    <as-icon class="as-field__icon" [name]="open() ? 'chevron-up' : 'chevron-down'" [size]="16" />
  </button>

  @if (open()) {
    <ul class="as-select__list as-animate-slide-down" role="listbox" [id]="listId()">
      @for (option of options(); track option.value; let index = $index) {
        <li
          class="as-select__option"
          role="option"
          [class.as-select__option--active]="index === active()"
          [class.as-select__option--selected]="option.value === value()"
          [class.as-select__option--disabled]="option.disabled"
          [attr.aria-selected]="option.value === value()"
          [attr.aria-disabled]="option.disabled || null"
          (click)="choose(option)"
          (mouseenter)="active.set(index)"
        >
          <span>{{ option.label }}</span>
          @if (option.value === value()) {
            <as-icon name="check" [size]="16" />
          }
        </li>
      } @empty {
        <li class="as-select__empty">No options</li>
      }
    </ul>
  }
  @if (error()) {
    <p class="as-field__error" role="alert">{{ error() }}</p>
  } @else if (hint()) {
    <p class="as-field__hint">{{ hint() }}</p>
  }
</div>
