<div
  [ngClass]="{
    'as-select-on': variant() === 'on' && !isCompactMultiSelect(),
    'as-select-in': variant() === 'in' && !isCompactMultiSelect(),
    'as-select-over': variant() === 'over' && !isCompactMultiSelect(),
    'as-select-over-float': variant() === 'over' && !!label() && !isCompactMultiSelect(),
    'as-select-compact': isCompactMultiSelect() || isCompactSingleSelect(),
    'as-select-has-left-icon': hasLeftIcon(),
    'as-select-interaction-disabled': isInteractionDisabled(),
  }"
>

  <!-- Contenido de una opción "rica" (avatar/ícono/color/chip/barra + etiqueta), según
       `optionAvatar`/`optionIcon`/`optionColor`/`optionShape` — un solo template compartido por
       el listado simple y el multiselect en vez de repetirlo. El peso (bold solo si está
       seleccionada) nunca se fija acá: lo hereda de la fila (`.as-select-option--selected`,
       ver select-styles.css), así ningún consumidor necesita declarar nada por su cuenta. -->
  <ng-template #richOptionLabel let-option>
    @if (hasAvatarOption()) {
      <as-avatar [label]="optionAvatarLabelOf(option)" [imageUrl]="optionAvatarOf(option) ?? null" [background]="optionAccent(option)" [shape]="optionAvatarShape()" [size]="22" textClass="text-caption-2-bold" [mode]="optionPresence() ? 'presence' : 'avatar'" [presenceStatus]="optionPresenceOf(option)" />
      <span class="truncate">{{ labelForOption(option) }}</span>
    } @else if (optionIconOf(option); as iconName) {
      @if (optionShape() === 'chip') {
        <span class="as-mselect-chip" [style.background]="'color-mix(in srgb, ' + optionColorOf(option) + ' 14%, transparent)'" [style.border]="'1px solid color-mix(in srgb, ' + optionColorOf(option) + ' 30%, transparent)'">
          <as-icon [name]="iconName" size="12" [color]="optionColorOf(option)" />
          <span class="truncate" [style.color]="optionColorOf(option)">{{ labelForOption(option) }}</span>
        </span>
      } @else if (optionShape() === 'box') {
        <span class="as-mselect-icon-box" [style.background]="'color-mix(in srgb, ' + optionColorOf(option) + ' 14%, transparent)'">
          <as-icon [name]="iconName" size="13" [color]="optionColorOf(option)" />
        </span>
        <span class="truncate">{{ labelForOption(option) }}</span>
      } @else {
        <as-icon [name]="iconName" size="14" [color]="optionColorOf(option)" />
        <span class="truncate">{{ labelForOption(option) }}</span>
      }
    } @else if (optionColorOf(option); as dotColor) {
      @if (optionShape() === 'chip') {
        <span class="as-mselect-chip" [style.background]="'color-mix(in srgb, ' + dotColor + ' 14%, transparent)'" [style.border]="'1px solid color-mix(in srgb, ' + dotColor + ' 30%, transparent)'">
          <span class="as-mselect-dot" [style.background]="dotColor"></span>
          <span class="truncate" [style.color]="dotColor">{{ labelForOption(option) }}</span>
        </span>
      } @else if (optionShape() === 'bar') {
        <span class="as-mselect-bar" [style.background]="dotColor"></span>
        <span class="truncate" [style.color]="dotColor">{{ labelForOption(option) }}</span>
      } @else {
        <span class="as-mselect-dot" [style.background]="dotColor"></span>
        <span class="truncate" [style.color]="dotColor">{{ labelForOption(option) }}</span>
      }
    } @else {
      <span class="truncate">{{ labelForOption(option) }}</span>
    }
  </ng-template>

  <fieldset class="relative w-full rounded-lg border-0 transition-all duration-180" style="padding: 0; margin: 0; min-inline-size: 0" [ngClass]="fieldsetClasses()" [style.box-shadow]="fieldsetBoxShadow()">
    @if (label() && variant() === 'on' && !isCompactMultiSelect() && !isCompactSingleSelect()) {
      <legend class="h-0 invisible overflow-hidden whitespace-nowrap block leading-none" style="padding: 0" [style.margin-left]="legendOffset()" [style.max-width]="legendMaxWidth()" [style.transition]="legendTransition()">
        <span class="px-2 text-caption-2-bold">{{ label() }}</span>
      </legend>
    }

    @if (isMultiSelect()) {
      <div #triggerRef class="as-select-field as-select-field--multi" [class.as-select-field--disabled]="isDisabled() || readonly()" [class.as-select-field--open]="isOpen()" role="combobox" aria-haspopup="listbox" tabindex="0" [attr.id]="resolvedInputId()" [attr.aria-expanded]="isOpen()" [attr.aria-controls]="resolvedInputId() + '-panel'" [attr.aria-describedby]="describedBy()" (keydown)="onTriggerKeydown($event)">
        <div class="as-select-field-label">
          <div class="as-select-multi-value" (click)="onMultiSelectSearchPointer($event)">
            @for (option of selectedOptions(); track optionTrackValue(option)) {
              <span class="as-select-chip" (mousedown)="onSelectedChipPointer($event)" (click)="onSelectedChipPointer($event)">
                <span class="truncate">{{ labelForOption(option) }}</span>

                <button type="button" class="as-select-chip-remove" [disabled]="isDisabled() || readonly()" (mousedown)="onChipRemovePointer($event)" (click)="removeSelectedOption(option, $event)" aria-label="Eliminar opción">
                  <as-icon name="CloseCircle" size="14" />
                </button>
              </span>
            }

            @if (searchable()) {
              <input #multiSearchInput type="text" class="as-select-search-input" [value]="searchTerm()" [placeholder]="multiSearchPlaceholder()" [disabled]="isDisabled() || readonly()" (focus)="onFocus()" (blur)="onBlur()" (click)="onMultiSelectSearchPointer($event)" (input)="onMultiSelectSearchInput($event)" (keydown)="onTriggerKeydown($event)" />
            } @else if (selectedOptions().length === 0 && shouldFloatLabel()) {
              <span class="as-select-placeholder">{{ placeholder() }}</span>
            }
          </div>
        </div>

        @if (showClear() && hasValue() && !isDisabled() && !readonly()) {
          <button type="button" class="as-select-clear-icon" tabindex="-1" aria-label="Limpiar selección" (mousedown)="$event.preventDefault()" (click)="clearValue($event)">
            <as-icon name="X" size="14" />
          </button>
        }

        <button type="button" class="as-select-dropdown" tabindex="-1" aria-hidden="true" (mousedown)="$event.preventDefault()" (click)="togglePanel()">
          <as-icon name="ChevronDown" size="18" class="as-select-dropdown-icon" />
        </button>
      </div>
    } @else if (isCompactMultiSelect()) {
      <button #triggerRef type="button" class="as-select-field as-select-field--count" [class.as-select-field--disabled]="isDisabled() || readonly()" [class.as-select-field--open]="isOpen()" [disabled]="isDisabled() || readonly()" [attr.id]="resolvedInputId()" aria-haspopup="listbox" [attr.aria-expanded]="isOpen()" [attr.aria-controls]="resolvedInputId() + '-panel'" [attr.aria-describedby]="describedBy()" (click)="togglePanel()" (focus)="onFocus()" (blur)="onBlur()" (keydown)="onTriggerKeydown($event)">
        <div class="as-select-field-label">
          <div class="as-select-multi-value--count">
            <span class="as-select-count-label">{{ label() || placeholder() }}</span>
            @if (selectedCount() > 0) {
              <span class="as-select-count-badge">{{ selectedCount() }}</span>
            }
          </div>
        </div>

        <span class="as-select-dropdown">
          <as-icon name="ChevronDown" size="18" class="as-select-dropdown-icon" />
        </span>
      </button>
    } @else if (isCompactSingleSelect()) {
      <button #triggerRef type="button" class="as-select-field as-select-field--count" [class.as-select-field--disabled]="isDisabled() || readonly()" [class.as-select-field--open]="isOpen()" [disabled]="isDisabled() || readonly()" [attr.id]="resolvedInputId()" aria-haspopup="listbox" [attr.aria-expanded]="isOpen()" [attr.aria-controls]="resolvedInputId() + '-panel'" [attr.aria-describedby]="describedBy()" (click)="togglePanel()" (focus)="onFocus()" (blur)="onBlur()" (keydown)="onTriggerKeydown($event)">
        <div class="as-select-field-label">
          <span class="as-select-count-label">{{ hasValue() ? editableValue() : placeholder() }}</span>
        </div>

        <span class="as-select-dropdown">
          <as-icon name="ChevronDown" size="18" class="as-select-dropdown-icon" />
        </span>
      </button>
    } @else {
      <div #triggerRef class="as-select-field" [class.as-select-field--disabled]="isDisabled() || readonly()" [class.as-select-field--open]="isOpen()">
        @if (searchable()) {
          <input
            type="text"
            class="as-select-field-label"
            role="combobox"
            aria-haspopup="listbox"
            [attr.id]="resolvedInputId()"
            [attr.aria-expanded]="isOpen()"
            [attr.aria-controls]="resolvedInputId() + '-panel'"
            [attr.aria-describedby]="describedBy()"
            [value]="editableValue()"
            [placeholder]="!label() || variant() === 'over' ? placeholder() : isFocused() && !hasValue() ? placeholder() : ' '"
            [disabled]="isDisabled() || readonly()"
            (input)="onSelectChange($any($event.target).value)"
            (click)="onEditableTriggerPointer($event)"
            (focus)="onEditableFocus()"
            (blur)="onBlur()"
            (keydown)="onTriggerKeydown($event)"
          />
        } @else {
          <!-- No searchable: nada de <input> — un <span> plano, igual que PrimeNG cuando
               `editable="false"` (ver primeng-select.mjs, rama `*ngIf="!editable"`). Un <input>
               real (aunque sea `readOnly`) sigue siendo foco-able con cursor de texto nativo: al
               clickear cerca del final de un valor truncado, el navegador coloca el caret según
               la posición X contra el string COMPLETO (no el truncado) y hace scroll interno para
               mostrarlo — ahí se "rompía" el truncate. Un <span> nunca tiene caret, así que nunca
               puede pasarle eso. */ -->
          <span
            class="as-select-field-label"
            role="combobox"
            aria-haspopup="listbox"
            tabindex="0"
            [attr.id]="resolvedInputId()"
            [attr.aria-expanded]="isOpen()"
            [attr.aria-controls]="resolvedInputId() + '-panel'"
            [attr.aria-describedby]="describedBy()"
            (click)="togglePanel()"
            (focus)="onEditableFocus()"
            (blur)="onBlur()"
            (keydown)="onTriggerKeydown($event)"
          >
            @if (hasValue()) {
              @if (hasAvatarOption() || optionIcon() || optionColor()) {
                <ng-container *ngTemplateOutlet="richOptionLabel; context: { $implicit: resolvedSelectedOption() }" />
              } @else {
                <span class="truncate">{{ editableValue() }}</span>
              }
            } @else {
              <span class="truncate as-select-placeholder">{{ placeholder() }}</span>
            }
          </span>
        }

        @if (showClear() && hasValue() && !isDisabled() && !readonly()) {
          <button type="button" class="as-select-clear-icon" tabindex="-1" aria-label="Limpiar selección" (mousedown)="$event.preventDefault()" (click)="clearValue($event)">
            <as-icon name="X" size="14" />
          </button>
        }

        <button type="button" class="as-select-dropdown" tabindex="-1" aria-hidden="true" (mousedown)="$event.preventDefault()" (click)="togglePanel()">
          <as-icon name="ChevronDown" size="18" class="as-select-dropdown-icon" />
        </button>
      </div>
    }

    @if (hasIcon() && lucideIcon()) {
      <as-icon
        [name]="lucideIcon()"
        [size]="16"
        class="pointer-events-none absolute top-1/2 z-10 -translate-y-1/2 transition-colors duration-150"
        [ngClass]="{
          'left-3': iconPosition() === 'left',
          'right-9': iconPosition() === 'right',
          'text-(--app-control-disabled-text)': isDisabled() || readonly(),
          'text-(--app-action-icon-color)': !isDisabled() && !readonly(),
        }"
      ></as-icon>
    }

    @if (label() && !isCompactMultiSelect() && !isCompactSingleSelect()) {
      <label class="as-select-label absolute z-10 select-none px-2 py-0.5 pointer-events-none transition-all duration-180 rounded-md" [ngClass]="labelClass()" [style.background]="labelBackground()" [style.color]="labelColor()">
        {{ label() }}
        @if (required()) {
          <span class="text-(--app-error-color)">*</span>
        }
      </label>
    }
  </fieldset>

  @if (hasErrors() && showErrorMessage()) {
    <small [id]="errorId()" class="as-select-error">
      {{ errorMessage() }}
    </small>
  }

  <div #panelRef popover [id]="resolvedInputId() + '-panel'" class="as-select-panel" [class.as-select-panel--multi]="isAnyMultiSelect()" (toggle)="onPanelToggle($event)">
    <div class="as-select-list-container">
      @if (activeOptions().length === 0) {
        <div class="as-select-empty">Sin resultados</div>
      } @else if (isAnyMultiSelect()) {
        <div class="as-select-list as-select-list--multi" role="listbox" aria-multiselectable="true">
          @for (option of activeOptions(); track optionTrackValue(option); let index = $index) {
            <div class="as-select-option" [class.as-select-option--active]="activeIndex() === index" [class.as-select-option--selected]="isOptionSelected(option)" role="option" [attr.aria-selected]="isOptionSelected(option)" (mousedown)="$event.preventDefault()" (click)="selectOption(option)">
            <div class="as-mselect-option-inner" [class.as-mselect-option-inner--all]="isSelectAllOption(option)">
              <span class="as-mselect-cb" [class.as-mselect-cb--checked]="isOptionSelected(option)"></span>

              @if (isSelectAllOption(option)) {
                <span class="truncate">{{ allVisibleSelected() ? 'Quitar todos' : 'Seleccionar todos' }}</span>
              } @else {
                <ng-container *ngTemplateOutlet="richOptionLabel; context: { $implicit: option }" />
              }
            </div>
            </div>
          }
        </div>
      } @else {
        <div class="as-select-list" role="listbox">
          @for (option of activeOptions(); track optionTrackValue(option); let index = $index) {
            <div class="as-select-option" [class.as-select-option--active]="activeIndex() === index" [class.as-select-option--selected]="isOptionSelected(option)" role="option" [attr.aria-selected]="isOptionSelected(option)" (mousedown)="$event.preventDefault()" (click)="selectOption(option)">
              <ng-container *ngTemplateOutlet="richOptionLabel; context: { $implicit: option }" />
            </div>
          }
        </div>
      }
    </div>
  </div>
</div>
