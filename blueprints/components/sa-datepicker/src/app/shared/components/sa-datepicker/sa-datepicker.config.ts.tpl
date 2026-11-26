import { computed } from '@angular/core';
import type { AbstractControl } from '@angular/forms';

import { resolveSide, type IPanelBounds } from '@shared/utils/panel-placement';
import { clamp } from '../sa-popover/sa-popover.config';
// El look del campo (borde, sombra de foco, color del label, etc.) es idéntico al de
// `sa-input` — en vez de duplicar esas fórmulas se reusan directo sus funciones puras
// (ya pensadas para no depender de estado del componente dueño).
import { resolveFieldsetBoxShadow, resolveInputErrorMessage, resolveInputFieldStyles, resolveInputLabelClass, resolveLabelColor } from '../sa-input/sa-input.config';
import type { SaAmPm, SaCalendarDay, SaDatepickerVariant, SaParsedDateTime } from './sa-datepicker.entity';

/** dd/mm/yyyy, with an optional time "hh:mm[:ss] AM/PM": the format accepted when typing a date. */
const DATE_TIME_REGEX = /^(\d{1,2})\/(\d{1,2})\/(\d{4})(?:\s+(\d{1,2}):(\d{1,2})(?::(\d{1,2}))?\s*(AM|PM)?)?$/i;

export function pad2(value: number): string {
  return String(value).padStart(2, '0');
}

/** Valor que viaja por el `FormControl` — `yyyy-mm-dd`, el mismo formato que ya producía el
 *  `<input type="date">` nativo que este componente reemplaza (contrato sin cambios). */
export function formatDateValue(date: Date): string {
  return `${date.getFullYear()}-${pad2(date.getMonth() + 1)}-${pad2(date.getDate())}`;
}

/** Para el futuro modo `allowManualTime` (sin consumidor todavía) — ISO completo con hora. */
export function formatDateTimeValue(date: Date): string {
  return date.toISOString();
}

export function parseDateValue(value: string | null | undefined): Date | null {
  if (!value) return null;

  const isoDateOnly = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value);
  if (isoDateOnly) {
    const [, year, month, day] = isoDateOnly;
    return new Date(Number(year), Number(month) - 1, Number(day));
  }

  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

function capitalize(value: string): string {
  return value.charAt(0).toUpperCase() + value.slice(1);
}

/** Nombres de mes en español vía `Intl` (no hardcodeados) — consistente con el locale `es-HN`
 *  que ya usa `shared/utils/date-time-format.ts` para formatear fechas en el resto de la app. */
export function getMonthNames(): string[] {
  const formatter = new Intl.DateTimeFormat('es-HN', { month: 'long' });
  return Array.from({ length: 12 }, (_, month) => capitalize(formatter.format(new Date(2000, month, 1))));
}

/** Nombres cortos de día de semana, empezando en domingo — mismo criterio de `Intl` que arriba. */
export function getWeekdayNames(): string[] {
  const formatter = new Intl.DateTimeFormat('es-HN', { weekday: 'short' });
  const sunday = new Date(2023, 0, 1); // 1/ene/2023 fue domingo
  return Array.from({ length: 7 }, (_, offset) => capitalize(formatter.format(new Date(sunday.getFullYear(), sunday.getMonth(), sunday.getDate() + offset))));
}

export function buildYearOptions(centerYear: number, before = 50, after = 10): number[] {
  return Array.from({ length: before + after + 1 }, (_, index) => centerYear - before + index);
}

export function isSameDay(a: Date, b: Date): boolean {
  return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
}

function stripTime(date: Date): number {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate()).getTime();
}

export function isDateEnabled(date: Date, minDate?: Date, maxDate?: Date): boolean {
  const day = stripTime(date);
  if (minDate && day < stripTime(minDate)) return false;
  if (maxDate && day > stripTime(maxDate)) return false;
  return true;
}

/** Grid de 6 semanas (42 celdas) empezando en el domingo anterior (o igual) al día 1 del mes. */
export function buildCalendarDays(month: number, year: number, selected: Date | null, minDate?: Date, maxDate?: Date, today: Date = new Date()): SaCalendarDay[] {
  const startDate = new Date(year, month, 1);
  startDate.setDate(startDate.getDate() - startDate.getDay());

  return Array.from({ length: 42 }, (_, index) => {
    const date = new Date(startDate.getFullYear(), startDate.getMonth(), startDate.getDate() + index);

    return {
      date,
      currentMonth: date.getMonth() === month,
      selected: !!selected && isSameDay(date, selected),
      today: isSameDay(date, today),
      enabled: isDateEnabled(date, minDate, maxDate),
    };
  });
}

export function formatTime12Hour(date: Date): { hour: string; ampm: SaAmPm } {
  const hours24 = date.getHours();
  const ampm: SaAmPm = hours24 >= 12 ? 'PM' : 'AM';
  const hours12 = hours24 % 12 === 0 ? 12 : hours24 % 12;

  return { hour: `${pad2(hours12)}:${pad2(date.getMinutes())}`, ampm };
}

export function convertTo24Hour(hour12: number, ampm: SaAmPm): number {
  if (ampm === 'AM') return hour12 === 12 ? 0 : hour12;
  return hour12 === 12 ? 12 : hour12 + 12;
}

export function formatDisplayDate(date: Date, includeTime: boolean): string {
  const datePart = `${pad2(date.getDate())}/${pad2(date.getMonth() + 1)}/${date.getFullYear()}`;
  if (!includeTime) return datePart;

  const { hour, ampm } = formatTime12Hour(date);
  return `${datePart} ${hour} ${ampm}`;
}

/** Parsea lo tipeado a mano en el input — devuelve `null` si el texto no matchea el formato o
 *  trae valores fuera de rango (ej. 31/02, hora 13 PM). */
export function parseInputDateTime(raw: string, allowTime: boolean): SaParsedDateTime | null {
  const trimmed = raw.trim();
  if (!trimmed) return null;

  const match = DATE_TIME_REGEX.exec(trimmed);
  if (!match) return null;

  const [, dayStr, monthStr, yearStr, hourStr, minuteStr, secondStr, ampmStr] = match;
  const day = Number(dayStr);
  const month = Number(monthStr);
  const year = Number(yearStr);

  if (month < 1 || month > 12 || day < 1 || day > 31) return null;

  const date = new Date(year, month - 1, day);
  if (date.getMonth() !== month - 1 || date.getDate() !== day) return null; // ej. 31/02 no existe

  if (!allowTime || hourStr === undefined) return { date, hasTime: false };

  const hour12 = Number(hourStr);
  const minute = Number(minuteStr);
  const second = secondStr !== undefined ? Number(secondStr) : 0;
  const ampm = (ampmStr?.toUpperCase() as SaAmPm | undefined) || 'AM';

  if (hour12 < 1 || hour12 > 12 || minute < 0 || minute > 59 || second < 0 || second > 59) return null;

  date.setHours(convertTo24Hour(hour12, ampm), minute, second, 0);
  return { date, hasTime: true };
}

/** Autoformatea mientras se escribe la hora manual: solo dígitos, inserta ":" tras 2 dígitos. */
export function formatHourMaskInput(raw: string): string {
  const digits = raw.replace(/\D/g, '').slice(0, 4);
  return digits.length <= 2 ? digits : `${digits.slice(0, 2)}:${digits.slice(2)}`;
}

export interface DatepickerPanelLayout {
  top: number;
  left: number;
  placement: 'top' | 'bottom';
}

/** A diferencia de `getSelectPanelLayout` (que fuerza el ancho del panel al del trigger), acá el
 *  panel tiene su propio ancho natural (necesita espacio para el grid de 7 columnas) — el trigger
 *  puede ser bastante angosto (ej. `min-w-40`), así que no tendría sentido heredar su ancho. */
export function buildDatepickerPanelLayout(triggerRect: DOMRect, panelWidth: number, panelHeight: number, viewportWidth: number, viewportHeight: number, gap = 4, margin = 8, bounds?: IPanelBounds): DatepickerPanelLayout {
  const belowTop = triggerRect.bottom + gap;
  const aboveTop = triggerRect.top - panelHeight - gap;
  const fitsBelow = belowTop + panelHeight <= viewportHeight - margin;
  const fitsAbove = aboveTop >= margin;

  // Con `bounds` (el área donde el campo se ve: la ventana recortada por sus contenedores con scroll) el espacio se mide contra ese área.
  const side = bounds ? resolveSide({ preferred: 'bottom', allowed: ['bottom', 'top'], trigger: triggerRect, size: { width: panelWidth, height: panelHeight }, bounds, gap, margin }) : null;
  const placement: 'top' | 'bottom' = side ? (side === 'top' ? 'top' : 'bottom') : fitsBelow || !fitsAbove ? 'bottom' : 'top';
  const top = clamp(placement === 'bottom' ? belowTop : aboveTop, margin, viewportHeight - panelHeight - margin);
  const left = clamp(triggerRect.left, margin, viewportWidth - panelWidth - margin);

  return { top, left, placement };
}

type DatepickerPresentationDeps = {
  control: () => AbstractControl | null;
  validationTick: () => number;
  label: () => string | undefined;
  placeholder: () => string;
  inputId: () => string;
  generatedInputId: string;
  showErrorMessage: () => boolean;
  isDisabled: () => boolean;
  isFocused: () => boolean;
  hasValue: () => boolean;
  variant: () => SaDatepickerVariant;
};

export function createDatepickerPresentation(deps: DatepickerPresentationDeps) {
  const hasErrors = computed(() => {
    deps.validationTick();
    const control = deps.control();
    return !!(control?.invalid && (control.touched || control.dirty));
  });

  const resolvedInputId = computed(() => deps.inputId().trim() || deps.generatedInputId);
  const shouldFloat = computed(() => deps.hasValue() || deps.isFocused() || hasErrors());
  const shouldShowPlaceholder = computed(() => !deps.isDisabled() && (!deps.label() || deps.variant() === 'over' || deps.isFocused() || hasErrors()));

  return {
    hasErrors,
    shouldFloat,
    resolvedInputId,
    // Solo lo usa la variante `on` (fieldset + legend que corta el borde, igual que
    // `sa-input`) — acá no hay ícono a la izquierda que desplace el corte, por eso el
    // offset es siempre el mismo (a diferencia de `sa-input`, que sí lo varía).
    legendOffset: computed(() => '0.75rem'),
    legendMaxWidth: computed(() => (shouldFloat() ? '999px' : '0px')),
    legendTransition: computed(() => (shouldFloat() ? 'max-width 180ms ease' : 'max-width 80ms ease')),
    errorId: computed(() => `${resolvedInputId()}-error`),
    errorMessage: computed(() => (hasErrors() ? resolveInputErrorMessage(deps.control()?.errors, deps.label() || deps.placeholder() || 'Este campo') : '')),
    describedBy: computed(() => (hasErrors() && deps.showErrorMessage() ? `${resolvedInputId()}-error` : null)),
    placeholderAttr: computed(() => {
      const placeholder = deps.placeholder();
      if (!placeholder) return ' ';
      return !deps.label() || shouldShowPlaceholder() ? placeholder : ' ';
    }),
    inputFieldStyles: computed(() => resolveInputFieldStyles('text', false, false, true, deps.variant())),
    // Cada clase en su propia clave (nunca combinadas en una sola como
    // `'a b': cond`) — el binding nativo `[class]` del template (en vez de `[ngClass]`) no
    // soporta varias clases separadas por espacio dentro de una misma clave.
    fieldsetClasses: computed(() => ({
      'bg-(--app-control-surface-bg)': !deps.isDisabled(),
      'cursor-not-allowed': deps.isDisabled(),
      'bg-(--app-control-disabled-bg)': deps.isDisabled(),
    })),
    fieldsetBoxShadow: computed(() => resolveFieldsetBoxShadow(hasErrors(), deps.isFocused(), deps.isDisabled(), false)),
    labelBackground: computed(() => 'transparent'),
    labelColor: computed(() => resolveLabelColor(hasErrors(), deps.isDisabled(), deps.isFocused(), deps.hasValue())),
    labelClass: computed(() => resolveInputLabelClass(deps.variant(), shouldFloat(), false)),
  };
}
