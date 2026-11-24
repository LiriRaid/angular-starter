<div
  class="sa-textarea-wrapper"
  [ngClass]="{
    'sa-textarea-invalid': hasErrors(),
    'sa-textarea-over': variant() === 'over',
    'sa-textarea-over-float': variant() === 'over' && !!label(),
  }"
>
  <div class="relative w-full">
    @if (label() && variant() === 'on') {
      <fieldset class="sa-textarea-grip relative w-full rounded-lg border-0 text-caption-1-medium transition-all duration-180" style="padding: 0; margin: 0; min-inline-size: 0" [ngClass]="fieldsetClasses()" [style.box-shadow]="fieldsetBoxShadow()">
        <legend class="h-0 invisible overflow-hidden whitespace-nowrap block leading-none" style="padding: 0" [style.margin-left]="legendOffset()" [style.max-width]="legendMaxWidth()" [style.transition]="legendTransition()">
          <span class="px-2 text-caption-2-bold">{{ label() }}</span>
        </legend>

        <textarea #textareaEl [id]="resolvedInputId()" [rows]="rows()" [disabled]="isDisabled()" [value]="displayValue()" [readOnly]="readonlyInput()" (input)="onInput($event)" (focus)="onFocus()" (blur)="onBlur()" (keyup)="keyup.emit($event)" [attr.autocomplete]="autocomplete() || null" [attr.placeholder]="placeholderAttr()" [attr.aria-invalid]="hasErrors() ? 'true' : null" [attr.aria-describedby]="describedBy()" [attr.data-resize-tick]="resizeTick()" class="sa-textarea-field peer" [ngStyle]="fieldStyles()"></textarea>

        @if (hasIcon() && lucideIcon()) {
          <sa-icon
            [name]="lucideIcon()"
            [size]="iconSize()"
            class="absolute transition-colors duration-150"
            [style.top]="iconTop()"
            [ngClass]="{
              'left-2.75': iconPosition() === 'left',
              'right-3': iconPosition() === 'right',
              'text-(--app-control-disabled-text)': isDisabled() || readonlyInput(),
              'text-(--app-action-icon-color)': !isDisabled() && !readonlyInput(),
            }"
          ></sa-icon>
        }

        <label [attr.for]="resolvedInputId()" class="absolute z-10 px-2 py-px leading-none select-none pointer-events-none transition-all duration-180 rounded-md" [class.transition-none]="!transitionReady()" [ngClass]="resolvedLabelClass()" [style.background]="labelBackground()" [style.color]="labelColor()">
          {{ label() }}
          @if (required()) {
            <span class="text-(--app-error-color)">*</span>
          }
        </label>
      </fieldset>
    } @else {
      <div class="sa-textarea-grip relative w-full rounded-lg text-caption-1-medium transition-all duration-180" [ngClass]="fieldsetClasses()" [style.box-shadow]="fieldsetBoxShadow()">
        <textarea #textareaEl [id]="resolvedInputId()" [rows]="rows()" [disabled]="isDisabled()" [value]="displayValue()" [readOnly]="readonlyInput()" (input)="onInput($event)" (focus)="onFocus()" (blur)="onBlur()" (keyup)="keyup.emit($event)" [attr.autocomplete]="autocomplete() || null" [attr.placeholder]="placeholderAttr()" [attr.aria-invalid]="hasErrors() ? 'true' : null" [attr.aria-describedby]="describedBy()" [attr.data-resize-tick]="resizeTick()" class="sa-textarea-field peer" [ngStyle]="fieldStyles()"></textarea>

        @if (hasIcon() && lucideIcon()) {
          <sa-icon
            [name]="lucideIcon()"
            [size]="iconSize()"
            class="absolute transition-colors duration-150"
            [style.top]="iconTop()"
            [ngClass]="{
              'left-2.75': iconPosition() === 'left',
              'right-3': iconPosition() === 'right',
              'text-(--app-control-disabled-text)': isDisabled() || readonlyInput(),
              'text-(--app-action-icon-color)': !isDisabled() && !readonlyInput(),
            }"
          ></sa-icon>
        }
      </div>

      @if (label()) {
        <label [attr.for]="resolvedInputId()" class="absolute z-10 px-2 py-px leading-none select-none pointer-events-none transition-all duration-150 rounded-md" [class.transition-none]="!transitionReady()" [ngClass]="resolvedLabelClass()" [style.background]="labelBackground()" [style.color]="labelColor()">
          {{ label() }}
          @if (required()) {
            <span class="text-(--app-error-color)">*</span>
          }
        </label>
      }
    }
  </div>

  @if (hasErrors() && showErrorMessage()) {
    <small [id]="errorId()" class="sa-textarea-error">
      {{ errorMessage() }}
    </small>
  }
</div>
