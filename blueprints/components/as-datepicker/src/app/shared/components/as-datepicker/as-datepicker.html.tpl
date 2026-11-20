<div
  class="flex w-full flex-col gap-1"
  [class]="{
    'as-datepicker-on': variant() === 'on',
    'as-datepicker-in': variant() === 'in',
    'as-datepicker-over': variant() === 'over',
    'as-datepicker-over-float': variant() === 'over' && !!label(),
  }"
>
  <ng-template #fieldContent>
    @if (allowManualTime()) {
      <input
        [id]="resolvedInputId()"
        type="text"
        inputmode="numeric"
        [disabled]="isDisabled()"
        [value]="inputValue()"
        (input)="onInputChange($event)"
        (focus)="onFocusInput()"
        (blur)="onBlurInput()"
        (keydown)="onKeyDown($event)"
        [attr.placeholder]="placeholderAttr()"
        [attr.aria-invalid]="hasErrors() ? 'true' : null"
        [attr.aria-describedby]="describedBy()"
        [attr.aria-expanded]="isOpen()"
        class="as-datepicker-input peer"
        [style]="inputFieldStyles()"
      />

      <button type="button" class="absolute inset-y-0 right-0 flex items-center px-3 transition-colors duration-150" [class]="isDisabled() ? 'text-(--app-control-disabled-text)' : 'text-(--app-action-icon-color) hover:text-(--app-text-primary)'" [disabled]="isDisabled()" (click)="toggleCalendar($event)">
        <as-icon name="Calendar" size="18" />
      </button>
    } @else {
      <!-- Sin hora manual no hay nada que tipear — el campo entero ES el botón (no un input +
           un botón de ícono repitiendo la misma acción): un solo elemento, un solo click handler,
           y el hover de "todo el campo" pinta el ícono vía `group-hover` en vez de necesitar su
           propio :hover aparte. -->
      <button
        type="button"
        [id]="resolvedInputId()"
        class="group relative flex w-full items-center rounded-lg text-left as-datepicker-input peer"
        [class.as-datepicker-input--pickable]="!isDisabled()"
        [style]="inputFieldStyles()"
        [disabled]="isDisabled()"
        [attr.aria-haspopup]="true"
        [attr.aria-invalid]="hasErrors() ? 'true' : null"
        [attr.aria-describedby]="describedBy()"
        [attr.aria-expanded]="isOpen()"
        (click)="toggleCalendar($event)"
        (focus)="onFocusInput()"
        (blur)="onBlurInput()"
      >
        <span class="truncate" [class]="{ 'text-(--app-placeholder-color)': !inputValue() }">{{ inputValue() || placeholder() }}</span>

        <span class="pointer-events-none absolute inset-y-0 right-0 flex items-center px-3 transition-colors duration-150" [class]="isDisabled() ? 'text-(--app-control-disabled-text)' : 'text-(--app-action-icon-color) group-hover:text-(--app-text-primary)'">
          <as-icon name="Calendar" size="18" />
        </span>
      </button>
    }
  </ng-template>

  <div class="relative w-full">
    @if (label() && variant() === 'on') {
      <fieldset #triggerRef class="relative w-full rounded-lg border-0 text-caption-1-medium transition-all duration-180" style="padding: 0; margin: 0; min-inline-size: 0" [class]="fieldsetClasses()" [style.box-shadow]="fieldsetBoxShadow()">
        <legend class="h-0 invisible overflow-hidden whitespace-nowrap block leading-none" style="padding: 0" [style.margin-left]="legendOffset()" [style.max-width]="legendMaxWidth()" [style.transition]="legendTransition()">
          <span class="px-2 text-caption-2-bold">{{ label() }}</span>
        </legend>

        <ng-container *ngTemplateOutlet="fieldContent" />

        <label [attr.for]="resolvedInputId()" class="absolute z-10 px-2 py-px leading-none select-none pointer-events-none transition-all duration-180 rounded-tl-md rounded-tr-md" [class]="labelClass()" [style.background]="labelBackground()" [style.color]="labelColor()">
          {{ label() }}
          @if (required()) {
            <span class="text-(--app-error-color)">*</span>
          }
        </label>
      </fieldset>
    } @else {
      <div #triggerRef class="relative flex w-full items-stretch rounded-lg text-caption-1-medium transition-all duration-180" [class]="fieldsetClasses()" [style.box-shadow]="fieldsetBoxShadow()">
        <ng-container *ngTemplateOutlet="fieldContent" />
      </div>

      @if (label()) {
        <label [attr.for]="resolvedInputId()" class="absolute z-10 px-2 py-px leading-none select-none pointer-events-none transition-all duration-150 rounded-tl-md rounded-tr-md" [class]="labelClass()" [style.background]="labelBackground()" [style.color]="labelColor()">
          {{ label() }}
          @if (required()) {
            <span class="text-(--app-error-color)">*</span>
          }
        </label>
      }
    }
  </div>

  @if (hasErrors() && showErrorMessage()) {
    <small [id]="errorId()" class="as-datepicker-error">{{ errorMessage() }}</small>
  }

  <div #panelRef popover="manual" [id]="resolvedInputId() + '-panel'" class="as-datepicker-panel" (toggle)="onPanelToggle($event)">
    <div class="flex flex-col gap-2 p-3">
      <div class="flex items-center justify-between gap-1.5">
        <as-button icon="ChevronLeft" variant="text" size="small" ariaLabel="Mes anterior" (onClick)="previousMonth()" />

        <div class="flex min-w-0 flex-1 items-center justify-center gap-2">
          <as-select class="w-[9.5rem]" [formControl]="monthCtrl" [options]="monthOptions" optionLabel="label" optionValue="value" [searchable]="false" [showErrorMessage]="false" variant="compact" />
          <as-select class="w-28" [formControl]="yearCtrl" [options]="yearOptions()" optionLabel="label" optionValue="value" [searchable]="false" [showErrorMessage]="false" variant="compact" />
        </div>

        <as-button icon="ChevronRight" variant="text" size="small" ariaLabel="Mes siguiente" (onClick)="nextMonth()" />
      </div>

      <div class="grid grid-cols-7 gap-1">
        @for (day of weekdayNames; track day) {
          <span class="py-1 text-center text-caption-2-medium text-(--app-text-subtle)">{{ day }}</span>
        }
      </div>

      <div class="grid grid-cols-7 gap-1 justify-items-center">
        @for (day of calendarDays(); track day.date.getTime()) {
          <button type="button" class="as-datepicker-day flex h-8 w-8 items-center justify-center rounded-full text-caption-2-medium transition-colors duration-150" [disabled]="!day.enabled" [class]="dayClass(day)" (click)="selectDate(day)">
            {{ day.date.getDate() }}
          </button>
        }
      </div>

      @if (allowManualTime() && hasSelectedDate()) {
        <div class="flex items-center gap-2 rounded-lg border border-(--color-blue-200) bg-(--color-blue-50) px-3 py-2">
          <as-icon name="Info" size="14" color="var(--color-blue-600)" />
          <span class="text-caption-2-regular text-(--app-text-muted)">Fecha seleccionada: {{ formattedSelectedDate() }}</span>
        </div>
      }

      <hr class="border-(--app-border-color)" />

      <div class="flex items-center justify-between gap-2">
        <div class="flex items-center gap-2">
          <as-button label="Hoy" variant="text" size="small" (onClick)="selectToday()" />

          @if (allowManualTime()) {
            <div class="flex items-center gap-1.5">
              <input type="text" class="as-datepicker-hour-input" maxlength="5" placeholder="HH:MM" [value]="manualHour()" (input)="onHourInputChange($event)" (keydown)="onHourKeyDown($event)" />
              <as-select class="w-24" [formControl]="amPmCtrl" [options]="amPmOptions" optionLabel="label" optionValue="value" [searchable]="false" [showErrorMessage]="false" variant="compact" />
            </div>
          } @else if (showCurrentTime()) {
            <span class="text-caption-1-regular text-(--app-text-subtle)">{{ currentTime() }}</span>
          }
        </div>

        <as-button label="Cerrar" variant="outlined" size="small" (onClick)="closeCalendar()" />
      </div>
    </div>
  </div>
</div>
