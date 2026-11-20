<!-- Botones ▲▼ de [showStepper]: un solo template para las dos ramas del campo (con y sin label sobre el borde). -->
<ng-template #stepperButtons>
  <div class="as-input-stepper-group">
    <button type="button" class="as-input-stepper-btn" [disabled]="isDisabled() || readonly()" aria-label="Aumentar" (click)="stepValue(1)">
      <svg width="9" height="5" viewBox="0 0 10 8" aria-hidden="true"><polygon points="5,1 9,7 1,7" fill="currentColor" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round" /></svg>
    </button>
    <button type="button" class="as-input-stepper-btn" [disabled]="isDisabled() || readonly()" aria-label="Disminuir" (click)="stepValue(-1)">
      <svg width="9" height="5" viewBox="0 0 10 8" aria-hidden="true" style="transform: rotate(180deg)"><polygon points="5,1 9,7 1,7" fill="currentColor" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round" /></svg>
    </button>
  </div>
</ng-template>

<div
  class="as-input-wrapper"
  [ngClass]="{
    'as-input-invalid': hasErrors(),
    'as-input-on': variant() === 'on',
    'as-input-in': variant() === 'in',
    'as-input-over': variant() === 'over',
    'as-input-over-float': variant() === 'over' && !!label(),
  }"
>
  <div class="relative w-full">
    @if (phoneCountryPicker()) {
      <div class="flex w-full flex-col gap-1">
        <!-- `over` reusa el mismo label flotante-arriba (con soporte de asterisco) que el input
             plano — a diferencia de `on`/`in`, que acá SIEMPRE mostraron un label estático
             (nunca miraron `variant()`); esas otras 2 pantallas (WhatsApp/Canal) no pasan
             `variant`, así que su look de siempre queda intacto en la rama `@else`. -->
        @if (variant() !== 'over' && label()) {
          <span class="text-caption-2-regular" [ngClass]="hasErrors() ? 'text-(--app-error-color)' : 'text-(--app-text-subtle)'">
            {{ label() }}
            @if (required()) {
              <span class="text-(--app-error-color)">*</span>
            }
          </span>
        }

        <div class="relative w-full">
          <div class="relative flex w-full items-stretch overflow-hidden rounded-lg text-caption-1-medium transition-all duration-180" [ngClass]="fieldsetClasses()" [style.box-shadow]="fieldsetBoxShadow()">
            <as-button
              #dialCodeTrigger
              type="button"
              variant="text"
              size="medium"
              [disabled]="isDisabled() || readonly()"
              [trailingIcon]="isDisabled() || readonly() ? null : 'ChevronDown'"
              trailingIconSize="14"
              trailingIconExtraClass="as-btn-trigger-chevron text-(--app-text-subtle)"
              [ariaExpanded]="dialCodeMenuOpen()"
              styleClass="!rounded-none !rounded-l-lg !outline-none !bg-transparent shrink-0 px-3 gap-1.5 !text-(--app-control-surface-text) hover:!bg-transparent hover:!text-(--app-text-primary)"
              (onClick)="toggleDialCodeMenu()"
            >
              @if (selectedCountry(); as country) {
                <svg class="shrink-0 rounded-xs" style="width: 1.15rem; height: 0.85rem" aria-hidden="true"><use [attr.href]="'assets/flags-sprite.svg#fi-' + country.iso2" /></svg>
                <span class="text-caption-1-medium">+{{ country.dialCode }}</span>
              } @else {
                <span class="text-caption-1-medium text-(--app-text-subtle)">País</span>
              }
            </as-button>

            <span class="w-px shrink-0 self-stretch bg-(--app-control-surface-border)"></span>

            <input
              [id]="resolvedInputId()"
              type="tel"
              [disabled]="isDisabled()"
              [value]="displayValue()"
              [readOnly]="readonly()"
              (input)="onPhoneNumberInput($event)"
              (keyup)="keyup.emit($event)"
              (focus)="onFocusInput()"
              (blur)="onBlurInput()"
              [attr.autocomplete]="autocomplete() || null"
              [attr.placeholder]="placeholder() || ' '"
              [attr.aria-invalid]="hasErrors() ? 'true' : null"
              [attr.aria-describedby]="describedBy()"
              class="as-input-field peer w-full min-w-0 border-0 focus:outline-none focus:ring-0"
              [ngStyle]="inputFieldStyles()"
              [ngClass]="{ 'as-input-field--disabled': isDisabled() || readonly() }"
            />
          </div>

          @if (variant() === 'over' && label()) {
            <label [attr.for]="resolvedInputId()" class="absolute z-10 px-2 py-px leading-none select-none pointer-events-none transition-all duration-150 rounded-tl-md rounded-tr-md rounded-bl-none rounded-br-none" [class.transition-none]="!transitionReady()" [ngClass]="labelClass()" [style.background]="labelBackground()" [style.color]="labelColor()">
              {{ label() }}
              @if (required()) {
                <span class="text-(--app-error-color)">*</span>
              }
            </label>
          }
        </div>

        <div #countryPanel popover [id]="resolvedInputId() + '-country-panel'" class="as-phone-country-panel" (toggle)="onCountryPanelToggle($event)">
          <div class="as-phone-country-search">
            <input type="text" [value]="countrySearch()" (input)="onCountrySearch($event)" placeholder="Buscar país..." />
          </div>

          <div class="as-phone-country-list">
            @for (country of filteredPhoneCountries(); track country.iso2) {
              <button type="button" class="as-phone-country-option" [class.as-phone-country-option--selected]="country.iso2 === selectedCountry()?.iso2" [class.text-caption-2-bold]="country.iso2 === selectedCountry()?.iso2" (click)="selectCountry(country)">
                <svg class="shrink-0 rounded-xs" style="width: 1.15rem; height: 0.85rem" aria-hidden="true"><use [attr.href]="'assets/flags-sprite.svg#fi-' + country.iso2" /></svg>
                <span class="shrink-0">+{{ country.dialCode }}</span>
                <span class="truncate">{{ country.name }}</span>
              </button>
            } @empty {
              <div class="as-phone-country-empty">Sin resultados</div>
            }
          </div>
        </div>
      </div>
    } @else if (!isTagInput()) {
      @if (label() && variant() === 'on') {
        <fieldset class="relative w-full rounded-lg border-0 text-caption-1-medium transition-all duration-180" style="padding: 0; margin: 0; min-inline-size: 0" [ngClass]="fieldsetClasses()" [class]="inputClass()" [style.box-shadow]="fieldsetBoxShadow()">
          <legend class="h-0 invisible overflow-hidden whitespace-nowrap block leading-none" style="padding: 0" [style.margin-left]="legendOffset()" [style.max-width]="legendMaxWidth()" [style.transition]="legendTransition()">
            <span class="px-2 text-caption-2-bold">{{ label() }}</span>
          </legend>

          <input [id]="resolvedInputId()" [type]="inputType()" [disabled]="isDisabled()" [value]="displayValue()" [readOnly]="readonly()" (input)="onInput($event)" (focus)="onFocusInput()" (blur)="onBlurInput()" (keyup)="keyup.emit($event)" (keydown)="onNumberKeydown($event)" (wheel)="onNumberWheel($event)" [attr.inputmode]="type() === 'price' || type() === 'number' ? 'decimal' : null" [attr.autocomplete]="autocomplete() || null" [attr.placeholder]="placeholderAttr()" [attr.aria-invalid]="hasErrors() ? 'true' : null" [attr.aria-describedby]="describedBy()" class="as-input-field peer" [ngClass]="inputFieldNgClass()" [class]="inputClass()" [ngStyle]="inputFieldStyles()" />

          @if (hasNumberStepper()) {
            <ng-container *ngTemplateOutlet="stepperButtons" />
          }

          @if (showCurrencySymbol()) {
            <span
              class="absolute top-1/2 -translate-y-1/2 pointer-events-none select-none text-caption-1-medium"
              [ngClass]="{
                'left-3': !hasLeftIcon(),
                'left-8': hasLeftIcon(),
                'text-(--app-control-disabled-text)': isDisabled() || readonly(),
                'text-(--app-text-subtle)': !isDisabled() && !readonly(),
              }"
              >{{ currencySymbol() }}</span
            >
          }

          @if (hasIcon() && lucideIcon()) {
            <as-icon
              [name]="lucideIcon()"
              [size]="iconSize()"
              class="absolute top-1/2 -translate-y-1/2 transition-colors duration-150"
              [ngClass]="{
                'left-2.75': iconPosition() === 'left',
                'right-3': iconPosition() === 'right',
                'text-(--app-control-disabled-text)': isDisabled() || readonly(),
                'text-(--app-action-icon-color)': !isDisabled() && !readonly() && !iconClickable(),
                'cursor-pointer text-(--app-action-icon-color) hover:text-(--app-text-primary)': iconClickable() && !isDisabled() && !readonly(),
              }"
              (click)="onIconClick($event)"
            ></as-icon>
          }

          <label [attr.for]="resolvedInputId()" class="absolute z-10 px-2 py-px leading-none select-none pointer-events-none transition-all duration-180 rounded-tl-md rounded-tr-md rounded-bl-none rounded-br-none" [class.transition-none]="!transitionReady()" [ngClass]="labelClass()" [style.background]="labelBackground()" [style.color]="labelColor()">
            {{ label() }}
            @if (required()) {
              <span class="text-(--app-error-color)">*</span>
            }
          </label>
        </fieldset>
      } @else {
        <div class="relative w-full rounded-lg text-caption-1-medium transition-all duration-180" [ngClass]="fieldsetClasses()" [class]="inputClass()" [style.box-shadow]="fieldsetBoxShadow()">
          <input [id]="resolvedInputId()" [type]="inputType()" [disabled]="isDisabled()" [value]="displayValue()" [readOnly]="readonly()" (input)="onInput($event)" (focus)="onFocusInput()" (blur)="onBlurInput()" (keyup)="keyup.emit($event)" (keydown)="onNumberKeydown($event)" (wheel)="onNumberWheel($event)" [attr.inputmode]="type() === 'price' || type() === 'number' ? 'decimal' : null" [attr.autocomplete]="autocomplete() || null" [attr.placeholder]="placeholderAttr()" [attr.aria-invalid]="hasErrors() ? 'true' : null" [attr.aria-describedby]="describedBy()" class="as-input-field peer" [ngClass]="inputFieldNgClass()" [class]="inputClass()" [ngStyle]="inputFieldStyles()" />

          @if (hasNumberStepper()) {
            <ng-container *ngTemplateOutlet="stepperButtons" />
          }

          @if (showCurrencySymbol()) {
            <span
              class="absolute top-1/2 -translate-y-1/2 pointer-events-none select-none text-caption-1-medium"
              [ngClass]="{
                'left-3': !hasLeftIcon(),
                'left-8': hasLeftIcon(),
                'text-(--app-control-disabled-text)': isDisabled() || readonly(),
                'text-(--app-text-subtle)': !isDisabled() && !readonly(),
              }"
              >{{ currencySymbol() }}</span
            >
          }

          @if (hasIcon() && lucideIcon()) {
            <as-icon
              [name]="lucideIcon()"
              [size]="iconSize()"
              class="absolute top-1/2 -translate-y-1/2 transition-colors duration-150"
              [ngClass]="{
                'left-2.75': iconPosition() === 'left',
                'right-3': iconPosition() === 'right',
                'text-(--app-control-disabled-text)': isDisabled() || readonly(),
                'text-(--app-action-icon-color)': !isDisabled() && !readonly() && !iconClickable(),
                'cursor-pointer text-(--app-action-icon-color) hover:text-(--app-text-primary)': iconClickable() && !isDisabled() && !readonly(),
              }"
              (click)="onIconClick($event)"
            ></as-icon>
          }

          @if (label()) {
            <label [attr.for]="resolvedInputId()" class="absolute z-10 px-2 py-px leading-none select-none pointer-events-none transition-all duration-150 rounded-tl-md rounded-tr-md rounded-bl-none rounded-br-none" [class.transition-none]="!transitionReady()" [ngClass]="labelClass()" [style.background]="labelBackground()" [style.color]="labelColor()">
              {{ label() }}
              @if (required()) {
                <span class="text-(--app-error-color)">*</span>
              }
            </label>
          }
        </div>
      }
    } @else if (label() && variant() === 'on') {
      <!-- `<fieldset>`/`<legend>` real (no un `<label>` con fondo tapando el borde) — el
           navegador recorta el borde solo, sin depender de que el fondo del label calce exacto
           con el fondo real detrás. Mismo patrón 1:1 que la variante "on" normal de este mismo
           componente (arriba). -->
      <fieldset class="relative w-full rounded-lg border-0 transition-all duration-180" style="padding: 0; margin: 0; min-inline-size: 0" [ngClass]="fieldsetClasses()" [style.box-shadow]="tagContainerBoxShadow()">
        <legend class="h-0 invisible overflow-hidden whitespace-nowrap block leading-none" style="padding: 0" [style.margin-left]="legendOffset()" [style.max-width]="legendMaxWidth()" [style.transition]="legendTransition()">
          <span class="px-2 text-caption-2-bold">{{ label() }}</span>
        </legend>

        <div class="relative z-20 flex flex-wrap items-center gap-2 px-3 py-2.5" [class.has-content]="tags().length > 0">
          @for (tag of tags(); track $index; let i = $index) {
            <span class="tag border flex items-center gap-2 flex-none bg-(--app-chip-bg) border-(--app-chip-border) text-(--app-chip-text)">
              <p class="text-caption-2-bold truncate">{{ tag }}</p>

              @if (!readonly() && !isDisabled()) {
                <button type="button" (click)="removeTag(i)" class="shrink-0 transition-colors duration-150 cursor-pointer text-(--app-action-icon-color) hover:text-(--app-text-primary)">
                  <as-icon name="CloseCircle" size="16"></as-icon>
                </button>
              }
            </span>
          }

          @if (readonly() && tags().length === 0) {
            <span class="cursor-not-allowed text-caption-1-medium px-2 py-0.5 flex-auto min-w-0 whitespace-normal wrap-break-words text-(--app-disabled-text)"> No hay números de serie registrados </span>
          }

          @if (!readonly() && !isDisabled()) {
            <input type="text" [id]="resolvedInputId()" [value]="currentTagValue()" [placeholder]="tags().length > 0 || isFocused() ? tagPlaceholder() : ' '" [attr.autocomplete]="autocomplete() || null" [attr.aria-invalid]="hasErrors() ? 'true' : null" [attr.aria-describedby]="describedBy()" (input)="onInput($event)" (keydown)="onTagKeyDown($event)" (focus)="onFocus()" (blur)="onBlur()" class="outline-none text-caption-1-regular px-2 py-0.5 border-none rounded-md max-w-full flex-1 min-w-40 bg-transparent text-(--app-control-surface-text)" [class.placeholder-transparent]="!isFocused() && tags().length === 0" />
          }
        </div>

        <label [attr.for]="resolvedInputId()" class="absolute z-10 px-2 py-px leading-none select-none pointer-events-none transition-all duration-180 rounded-tl-md rounded-tr-md rounded-bl-none rounded-br-none" [class.transition-none]="!transitionReady()" [ngClass]="labelClass()" [style.background]="labelBackground()" [style.color]="labelColor()">
          {{ label() }}
          @if (required()) {
            <span class="text-(--app-error-color)">*</span>
          }
        </label>
      </fieldset>
    } @else {
      <div
        class="peer w-full py-2 border rounded-lg px-3 transition-all duration-150 focus-within:outline-none"
        [ngClass]="{
          'bg-(--app-control-surface-bg) text-(--app-control-surface-text) border-(--app-control-surface-border)': !isDisabled() && !readonly() && !hasErrors(),
          'focus-within:ring-2 focus-within:ring-(--app-control-focus-ring) focus-within:border-transparent': !hasErrors(),
          'cursor-not-allowed bg-(--app-control-disabled-bg) text-(--app-control-disabled-text) border-(--app-control-disabled-border)': isDisabled() || readonly(),
          'bg-(--app-control-surface-bg) text-(--app-control-surface-text) border-(--app-error-color) focus-within:ring-2 focus-within:ring-(--app-error-ring) focus-within:border-transparent': hasErrors(),
        }"
        [class.has-content]="tags().length > 0"
      >
        <div class="relative z-20 flex flex-wrap items-center gap-2">
          @for (tag of tags(); track $index; let i = $index) {
            <span class="tag border flex items-center gap-2 flex-none bg-(--app-chip-bg) border-(--app-chip-border) text-(--app-chip-text)">
              <p class="text-caption-2-bold truncate">{{ tag }}</p>

              @if (!readonly() && !isDisabled()) {
                <button type="button" (click)="removeTag(i)" class="shrink-0 transition-colors duration-150 cursor-pointer text-(--app-action-icon-color) hover:text-(--app-text-primary)">
                  <as-icon name="CloseCircle" size="16"></as-icon>
                </button>
              }
            </span>
          }

          @if (readonly() && tags().length === 0) {
            <span class="cursor-not-allowed text-caption-1-medium px-2 py-0.5 flex-auto min-w-0 whitespace-normal wrap-break-words text-(--app-disabled-text)"> No hay números de serie registrados </span>
          }

          @if (!readonly() && !isDisabled()) {
            <input type="text" [id]="resolvedInputId()" [value]="currentTagValue()" [placeholder]="tags().length > 0 || isFocused() ? tagPlaceholder() : ' '" [attr.autocomplete]="autocomplete() || null" [attr.aria-invalid]="hasErrors() ? 'true' : null" [attr.aria-describedby]="describedBy()" (input)="onInput($event)" (keydown)="onTagKeyDown($event)" (focus)="onFocus()" (blur)="onBlur()" class="outline-none text-caption-1-regular px-2 py-0.5 border-none rounded-md max-w-full flex-1 min-w-40 bg-transparent text-(--app-control-surface-text)" [class.placeholder-transparent]="!isFocused() && tags().length === 0" />
          }
        </div>

        @if (label()) {
          <label
            [attr.for]="resolvedInputId()"
            class="absolute left-3 z-10 px-2 py-px select-none pointer-events-none transition-all duration-150 rounded-tl-md rounded-tr-md rounded-bl-none rounded-br-none bg-(--app-panel-bg)"
            [class.transition-none]="!transitionReady()"
            [ngClass]="{
              'top-1/2 -translate-y-1/2 text-caption-1-medium': !hasValue() && !readonly() && !hasErrors() && !isFocused(),
              '-top-3 translate-y-0 text-caption-1-medium': hasValue() || readonly() || hasErrors() || isFocused(),
              'text-(--app-error-color)': hasErrors(),
              'text-(--app-control-disabled-text)': (isDisabled() || readonly()) && !hasErrors(),
              'text-(--app-text-subtle)': !isDisabled() && !readonly() && !hasErrors(),
            }"
          >
            {{ label() }}
            @if (required()) {
              <span class="text-(--app-error-color)">*</span>
            }
          </label>
        }
      </div>
    }
  </div>

  @if (hasErrors() && showErrorMessage()) {
    <small [id]="errorId()" class="as-input-error">
      {{ errorMessage() }}
    </small>
  }
</div>
