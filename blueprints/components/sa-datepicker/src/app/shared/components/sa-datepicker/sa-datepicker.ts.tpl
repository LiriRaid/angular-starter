import { DOCUMENT, NgTemplateOutlet } from '@angular/common';
import { ChangeDetectionStrategy, Component, DestroyRef, ElementRef, Injector, ViewEncapsulation, afterNextRender, computed, forwardRef, inject, input, signal, viewChild } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { AbstractControl, ControlValueAccessor, FormControl, NG_VALUE_ACCESSOR, NgControl, ReactiveFormsModule } from '@angular/forms';

import { NativeOverlayRuntime } from '../../utils/native-overlay-dismiss';
import { SaButton } from '../sa-button/sa-button';
import { SaIcon } from '../sa-icon/sa-icon';
import { SaSelect } from '../sa-select/sa-select';
import { buildCalendarDays, buildDatepickerPanelLayout, buildYearOptions, convertTo24Hour, createDatepickerPresentation, formatDateTimeValue, formatDateValue, formatDisplayDate, formatHourMaskInput, formatTime12Hour, getMonthNames, getWeekdayNames, isDateEnabled, parseDateValue, parseInputDateTime } from './sa-datepicker.config';
import type { SaAmPm, SaCalendarDay, SaDatepickerVariant } from './sa-datepicker.entity';

@Component({
  selector: 'sa-datepicker',
  standalone: true,
  imports: [NgTemplateOutlet, ReactiveFormsModule, SaButton, SaIcon, SaSelect],
  templateUrl: './sa-datepicker.html',
  styleUrl: './sa-datepicker.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
  providers: [{ provide: NG_VALUE_ACCESSOR, useExisting: forwardRef(() => SaDatepicker), multi: true }],
})
export class SaDatepicker implements ControlValueAccessor {
  private static nextId = 0;

  private readonly document = inject(DOCUMENT);
  private readonly injector = inject(Injector);
  private readonly destroyRef = inject(DestroyRef);

  private readonly triggerRef = viewChild<ElementRef<HTMLElement>>('triggerRef');
  private readonly panelRef = viewChild<ElementRef<HTMLElement>>('panelRef');

  readonly label = input<string | undefined>('Fecha');
  readonly placeholder = input<string>('Escriba o seleccione una fecha');
  readonly required = input(false);
  readonly variant = input<SaDatepickerVariant>('over');
  readonly minDate = input<Date | undefined>(undefined);
  readonly maxDate = input<Date | undefined>(undefined);
  /** Habilita hora manual (input HH:MM + AM/PM) — sin consumidor todavía, se deja construido
   *  para reusarse en un futuro campo de fecha+hora sin tener que rehacer el componente. */
  readonly allowManualTime = input(false);
  readonly showCurrentTime = input(true);
  readonly showErrorMessage = input(true);
  readonly inputId = input<string>('');

  readonly isDisabled = signal(false);
  readonly isFocused = signal(false);
  readonly isOpen = signal(false);

  readonly inputValue = signal('');
  readonly currentTime = signal('');
  readonly manualHour = signal('12:00');

  readonly monthCtrl = new FormControl<number>(new Date().getMonth(), { nonNullable: true });
  readonly yearCtrl = new FormControl<number>(new Date().getFullYear(), { nonNullable: true });
  readonly amPmCtrl = new FormControl<SaAmPm>('AM', { nonNullable: true });

  readonly weekdayNames = getWeekdayNames();
  readonly monthOptions = getMonthNames().map((name, index) => ({ label: name, value: index }));
  readonly amPmOptions: { label: string; value: SaAmPm }[] = [
    { label: 'AM', value: 'AM' },
    { label: 'PM', value: 'PM' },
  ];

  readonly yearOptions = computed(() => buildYearOptions(new Date().getFullYear()).map((year) => ({ label: String(year), value: year })));

  private readonly selectedDate = signal<Date | null>(null);
  private readonly currentMonth = signal(new Date().getMonth());
  private readonly currentYear = signal(new Date().getFullYear());
  private readonly validationTick = signal(0);
  private readonly generatedId = `sa-datepicker-${SaDatepicker.nextId++}`;

  private ngControl?: NgControl;

  onChange: (value: unknown) => void = () => {};
  onTouched: () => void = () => {};

  readonly hasValue = computed(() => !!this.inputValue());
  readonly hasSelectedDate = computed(() => !!this.selectedDate());
  readonly formattedSelectedDate = computed(() => {
    const date = this.selectedDate();
    return date ? formatDisplayDate(date, true) : '';
  });

  readonly calendarDays = computed<SaCalendarDay[]>(() => buildCalendarDays(this.currentMonth(), this.currentYear(), this.selectedDate(), this.minDate(), this.maxDate()));

  private readonly presentation = createDatepickerPresentation({
    control: () => this.control,
    validationTick: this.validationTick,
    label: this.label,
    placeholder: this.placeholder,
    inputId: this.inputId,
    generatedInputId: this.generatedId,
    showErrorMessage: this.showErrorMessage,
    isDisabled: () => this.isDisabled(),
    isFocused: () => this.isFocused(),
    hasValue: () => this.hasValue(),
    variant: this.variant,
  });

  readonly hasErrors = this.presentation.hasErrors;
  readonly resolvedInputId = this.presentation.resolvedInputId;
  readonly legendOffset = this.presentation.legendOffset;
  readonly legendMaxWidth = this.presentation.legendMaxWidth;
  readonly legendTransition = this.presentation.legendTransition;
  readonly errorId = this.presentation.errorId;
  readonly errorMessage = this.presentation.errorMessage;
  readonly describedBy = this.presentation.describedBy;
  readonly placeholderAttr = this.presentation.placeholderAttr;
  readonly inputFieldStyles = this.presentation.inputFieldStyles;
  readonly fieldsetClasses = this.presentation.fieldsetClasses;
  readonly fieldsetBoxShadow = this.presentation.fieldsetBoxShadow;
  readonly labelBackground = this.presentation.labelBackground;
  readonly labelColor = this.presentation.labelColor;
  readonly labelClass = this.presentation.labelClass;

  private triggerElement: HTMLElement | null = null;
  private panelVisible = false;
  private clockInterval: ReturnType<typeof setInterval> | null = null;

  private readonly overlayRuntime = new NativeOverlayRuntime(this.document, {
    getPanelElement: () => this.panelRef()?.nativeElement,
    getTriggerElement: () => this.triggerElement,
    isVisible: () => this.panelVisible,
    onDismiss: () => this.closeCalendar(),
    onReposition: () => this.positionPanel(),
  });

  constructor() {
    afterNextRender(() => {
      this.ngControl = this.injector.get(NgControl, null) || undefined;
    });

    this.monthCtrl.valueChanges.pipe(takeUntilDestroyed(this.destroyRef)).subscribe((month) => this.currentMonth.set(month));
    this.yearCtrl.valueChanges.pipe(takeUntilDestroyed(this.destroyRef)).subscribe((year) => this.currentYear.set(year));
    this.amPmCtrl.valueChanges.pipe(takeUntilDestroyed(this.destroyRef)).subscribe(() => {
      if (this.allowManualTime()) this.applyManualTime();
    });

    this.destroyRef.onDestroy(() => {
      this.overlayRuntime.cleanup();
      this.stopClock();
    });
  }

  writeValue(value: unknown): void {
    const parsed = typeof value === 'string' ? parseDateValue(value) : null;
    this.selectedDate.set(parsed);
    this.syncCalendarPosition(parsed ?? new Date());
    this.inputValue.set(parsed ? this.displayTextFor(parsed) : '');
    if (parsed && this.allowManualTime()) this.syncManualTimeControls(parsed);
    this.refreshValidation();
  }

  registerOnChange(fn: (value: unknown) => void): void {
    this.onChange = fn;
  }

  registerOnTouched(fn: () => void): void {
    this.onTouched = fn;
  }

  setDisabledState(isDisabled: boolean): void {
    this.isDisabled.set(isDisabled);
    this.refreshValidation();
  }

  toggleCalendar(event: MouseEvent): void {
    event.preventDefault();
    if (this.isDisabled()) return;

    this.triggerElement = this.triggerRef()?.nativeElement ?? null;
    if (this.panelVisible) this.markPanelAsClosing();

    this.panelRef()?.nativeElement.togglePopover();
  }

  closeCalendar(): void {
    this.markPanelAsClosing();
    this.panelRef()?.nativeElement.hidePopover();
  }

  onPanelToggle(event: ToggleEvent): void {
    if (event.newState === 'open') this.handlePanelOpen();
    else this.handlePanelClose();
  }

  onFocusInput(): void {
    this.isFocused.set(true);
  }

  onBlurInput(): void {
    this.isFocused.set(false);
    this.onTouched();
    this.finalizeTypedInput();
  }

  onInputChange(event: Event): void {
    const raw = (event.target as HTMLInputElement).value;
    this.inputValue.set(raw);

    if (!raw.trim()) {
      this.clearDate();
      return;
    }

    const parsed = parseInputDateTime(raw, this.allowManualTime());
    if (parsed) this.applyDate(parsed.date, { closeCalendar: false, reformatText: false });
  }

  onKeyDown(event: KeyboardEvent): void {
    if (event.key !== 'Enter') return;

    event.preventDefault();
    this.finalizeTypedInput();
    (event.target as HTMLInputElement).blur();
  }

  onHourInputChange(event: Event): void {
    const target = event.target as HTMLInputElement;
    const masked = formatHourMaskInput(target.value);
    this.manualHour.set(masked);
    target.value = masked;

    if (/^\d{1,2}:\d{2}$/.test(masked)) this.applyManualTime();
  }

  onHourKeyDown(event: KeyboardEvent): void {
    if (event.key !== 'Enter') return;

    event.preventDefault();
    this.applyManualTime();
    this.closeCalendar();
  }

  selectDate(day: SaCalendarDay): void {
    if (!day.enabled || this.isDisabled()) return;

    const base = this.selectedDate();
    const newDate = new Date(day.date);

    if (this.allowManualTime()) {
      const [hour24, minute]: [number, number] = base ? [base.getHours(), base.getMinutes()] : this.manualHourParts();
      newDate.setHours(hour24, minute, 0, 0);
    } else {
      newDate.setHours(0, 0, 0, 0);
    }

    this.applyDate(newDate, { closeCalendar: !this.allowManualTime(), reformatText: true });
    this.onTouched();
  }

  selectToday(): void {
    const today = new Date();
    if (!isDateEnabled(today, this.minDate(), this.maxDate())) return;

    const base = this.allowManualTime() ? today : new Date(today.getFullYear(), today.getMonth(), today.getDate());
    this.applyDate(base, { closeCalendar: !this.allowManualTime(), reformatText: true });
    this.onTouched();
  }

  previousMonth(): void {
    const month = this.currentMonth();
    const year = this.currentYear();

    if (month === 0) {
      this.currentMonth.set(11);
      this.currentYear.set(year - 1);
      this.monthCtrl.setValue(11, { emitEvent: false });
      this.yearCtrl.setValue(year - 1, { emitEvent: false });
    } else {
      this.currentMonth.set(month - 1);
      this.monthCtrl.setValue(month - 1, { emitEvent: false });
    }
  }

  nextMonth(): void {
    const month = this.currentMonth();
    const year = this.currentYear();

    if (month === 11) {
      this.currentMonth.set(0);
      this.currentYear.set(year + 1);
      this.monthCtrl.setValue(0, { emitEvent: false });
      this.yearCtrl.setValue(year + 1, { emitEvent: false });
    } else {
      this.currentMonth.set(month + 1);
      this.monthCtrl.setValue(month + 1, { emitEvent: false });
    }
  }

  // Cada clase en su propia clave (el binding `[class]` del template, a diferencia de
  // `[ngClass]`, no soporta varias clases separadas por espacio dentro de una misma clave).
  dayClass(day: SaCalendarDay): Record<string, boolean> {
    return {
      'bg-(--sa-primary-color)': day.selected,
      'text-white': day.selected,
      'border-(--sa-primary-color)': day.today && !day.selected,
      'text-(--sa-primary-color)': day.today && !day.selected,
      'text-(--app-text-subtle)': !day.currentMonth && !day.selected,
      'text-(--app-text-color)': day.currentMonth && !day.selected && !day.today,
      'opacity-40': !day.enabled,
      'cursor-not-allowed': !day.enabled,
    };
  }

  private manualHourParts(): [number, number] {
    const [hourStr, minuteStr] = this.manualHour().split(':');
    const hour12 = Number(hourStr) || 12;
    const minute = Number(minuteStr) || 0;
    return [convertTo24Hour(hour12, this.amPmCtrl.value), minute];
  }

  private applyManualTime(): void {
    const base = this.selectedDate();
    if (!base) return;

    const [hour24, minute] = this.manualHourParts();
    const updated = new Date(base);
    updated.setHours(hour24, minute, 0, 0);
    this.applyDate(updated, { closeCalendar: false, reformatText: true });
  }

  private applyDate(date: Date, opts: { closeCalendar: boolean; reformatText: boolean }): void {
    this.selectedDate.set(date);
    this.syncCalendarPosition(date);
    if (opts.reformatText) this.inputValue.set(this.displayTextFor(date));
    if (this.allowManualTime()) this.syncManualTimeControls(date);
    this.emitValue(date);
    if (opts.closeCalendar) this.closeCalendar();
  }

  /** With `allowManualTime` the real time of the value (the one typed by hand) is shown. Without
   *  it there is no "real" time to show (the stored value is always midnight), so the current time
   *  is displayed instead. */
  private displayTextFor(date: Date): string {
    if (this.allowManualTime()) return formatDisplayDate(date, true);

    const { hour, ampm } = formatTime12Hour(new Date());
    return `${formatDisplayDate(date, false)} ${hour} ${ampm}`;
  }

  private clearDate(): void {
    this.selectedDate.set(null);
    this.inputValue.set('');
    this.manualHour.set('12:00');
    this.amPmCtrl.setValue('AM', { emitEvent: false });
    this.syncCalendarPosition(new Date());
    this.emitValue(null);
  }

  private finalizeTypedInput(): void {
    const raw = this.inputValue().trim();
    if (!raw) {
      if (this.selectedDate()) this.clearDate();
      return;
    }

    const parsed = parseInputDateTime(raw, this.allowManualTime());
    if (parsed) {
      this.applyDate(parsed.date, { closeCalendar: false, reformatText: true });
      return;
    }

    // Texto inválido: revierte al último valor válido (o lo limpia si nunca hubo uno).
    const current = this.selectedDate();
    this.inputValue.set(current ? this.displayTextFor(current) : '');
  }

  private syncCalendarPosition(date: Date): void {
    this.currentMonth.set(date.getMonth());
    this.currentYear.set(date.getFullYear());
    this.monthCtrl.setValue(date.getMonth(), { emitEvent: false });
    this.yearCtrl.setValue(date.getFullYear(), { emitEvent: false });
  }

  private syncManualTimeControls(date: Date): void {
    const { hour, ampm } = formatTime12Hour(date);
    this.manualHour.set(hour);
    this.amPmCtrl.setValue(ampm, { emitEvent: false });
  }

  private emitValue(date: Date | null): void {
    const value = date ? (this.allowManualTime() ? formatDateTimeValue(date) : formatDateValue(date)) : null;
    this.onChange(value);
    this.refreshValidation();
  }

  private handlePanelOpen(): void {
    this.isOpen.set(true);
    this.panelVisible = true;
    this.syncCalendarPosition(this.selectedDate() ?? new Date());
    this.overlayRuntime.addListeners();
    requestAnimationFrame(() => this.positionPanel());
    if (!this.allowManualTime() && this.showCurrentTime()) this.startClock();
  }

  private handlePanelClose(): void {
    this.isOpen.set(false);
    this.panelVisible = false;
    this.triggerElement = null;
    this.overlayRuntime.cleanup();
    this.stopClock();
    this.resetPanelPosition();
    this.finalizeTypedInput();
  }

  private markPanelAsClosing(): void {
    this.isOpen.set(false);
    this.panelVisible = false;
    this.overlayRuntime.cleanup();
  }

  private positionPanel(): void {
    const panel = this.panelRef()?.nativeElement;
    const trigger = this.triggerElement;
    if (!panel || !trigger) return;

    const triggerRect = trigger.getBoundingClientRect();
    const panelWidth = panel.offsetWidth;
    const panelHeight = panel.offsetHeight;
    const viewportWidth = this.document.documentElement.clientWidth;
    const viewportHeight = this.document.documentElement.clientHeight;

    const layout = buildDatepickerPanelLayout(triggerRect, panelWidth, panelHeight, viewportWidth, viewportHeight);

    panel.style.setProperty('position', 'fixed', 'important');
    panel.style.setProperty('top', `${layout.top}px`, 'important');
    panel.style.setProperty('left', `${layout.left}px`, 'important');
    panel.style.setProperty('right', 'auto', 'important');
    panel.style.setProperty('bottom', 'auto', 'important');
    panel.style.setProperty('transform', 'none', 'important');
    panel.style.setProperty('margin', '0', 'important');
    panel.dataset['placement'] = layout.placement;
    panel.dataset['positioned'] = 'true';
  }

  private resetPanelPosition(): void {
    const panel = this.panelRef()?.nativeElement;
    if (!panel) return;

    for (const property of ['position', 'top', 'left', 'right', 'bottom', 'transform', 'margin']) {
      panel.style.removeProperty(property);
    }
    delete panel.dataset['placement'];
    delete panel.dataset['positioned'];
  }

  private startClock(): void {
    this.updateClock();
    this.clockInterval = setInterval(() => this.updateClock(), 1000);
  }

  private stopClock(): void {
    if (this.clockInterval !== null) {
      clearInterval(this.clockInterval);
      this.clockInterval = null;
    }
  }

  private updateClock(): void {
    const { hour, ampm } = formatTime12Hour(new Date());
    this.currentTime.set(`${hour} ${ampm}`);
  }

  private get control(): AbstractControl | null {
    return this.ngControl?.control ?? null;
  }

  private refreshValidation(): void {
    this.validationTick.update((value) => value + 1);
  }
}
