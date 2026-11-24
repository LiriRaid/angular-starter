import { computed } from '@angular/core';
import type { AbstractControl } from '@angular/forms';
import type { ValidationErrors } from '@angular/forms';

import { groupNationalDigits } from '@shared/utils/format-phone-number';
import type { SaIconPosition, SaInputType, SaVariant } from './sa-input.entity';

const ALLOWED_INPUT_TYPES: readonly SaInputType[] = ['text', 'password', 'email', 'number', 'date', 'tel', 'url', 'price'];

export function coerceReadonly(value: boolean | string): boolean {
  return value === '' || value === true || value === 'true';
}

/**
 * `price` y `number` se dibujan como texto: el `<input type="number">` nativo borra el valor completo en cuanto queda un
 * estado intermedio inválido como "1." (el instante en que se borra el último decimal) y de paso salta el cursor al inicio.
 * Con texto + `sanitizeDecimalInput` no hay saneo nativo y el punto y el cursor se comportan como en cualquier campo.
 */
export function resolveInputType(type: SaInputType): string {
  return type === 'price' || type === 'number' ? 'text' : ALLOWED_INPUT_TYPES.includes(type) ? type : 'text';
}

/** Deja solo dígitos y un único punto decimal (y, si se pide, un "-" inicial); conserva estados intermedios como "1.". La coma decimal ("2,5") se toma como punto. */
export function sanitizeDecimalInput(input: string, { allowNegative = false }: { allowNegative?: boolean } = {}): string {
  if (!input) return '';

  const negative = allowNegative && input.trim().startsWith('-');
  const [integerPart, ...decimalParts] = input.replace(/,/g, '.').replace(/[^\d.]/g, '').split('.');
  const digits = decimalParts.length > 0 ? `${integerPart}.${decimalParts.join('')}` : integerPart;

  return (negative ? '-' : '') + digits;
}

function decimalPlaces(value: number): number {
  const text = value.toString();
  const dot = text.indexOf('.');

  return dot === -1 ? 0 : text.length - dot - 1;
}

/** Suma redondeando a los decimales que ya traían los operandos: evita 0.1 + 0.2 = 0.30000000000000004. */
export function addPrecise(a: number, b: number): number {
  const factor = 10 ** Math.max(decimalPlaces(a), decimalPlaces(b));

  return Math.round((a + b) * factor) / factor;
}

/**
 * Siguiente valor de las flechas, la rueda o los botones del stepper. No delega en `stepUp()` del navegador porque este
 * realinea al múltiplo de `step` más cercano (con paso 1, 1.5 salta a 2 en vez de a 2.5): aquí se suma el paso directo sobre el
 * valor actual. Un valor vacío cuenta como 0, un paso inválido como 1, y `min`/`max` acotan el resultado.
 */
export function stepNumberValue({ current, direction, step, min, max }: { current: string; direction: 1 | -1; step?: number | string; min?: number; max?: number }): string {
  const parsedStep = typeof step === 'number' ? step : parseFloat(String(step ?? ''));
  const amount = parsedStep || 1;
  let next = addPrecise(parseFloat(current) || 0, amount * direction);

  if (min !== undefined && next < min) next = min;
  if (max !== undefined && next > max) next = max;

  return String(next);
}

export function resolveInputErrorMessage(errors: ValidationErrors | null | undefined, label: string): string {
  if (!errors) return '';
  if (errors['required']) return `${label} es requerido`;
  if (errors['email']) return 'Ingrese un correo electrónico válido';
  if (errors['minlength']) return `${label} debe tener al menos ${errors['minlength'].requiredLength} caracteres`;
  if (errors['maxlength']) return `${label} no puede exceder ${errors['maxlength'].requiredLength} caracteres`;
  if (errors['pattern']) return `${label} tiene un formato inválido`;
  return `${label} es inválido`;
}

export function resolveInputFieldStyles(type: SaInputType, hasLeftIcon: boolean, showCurrencySymbol: boolean, hasRightIcon: boolean, variant: SaVariant, hasStepper = false): Record<string, string> {
  const paddingLeft = type === 'price' ? resolvePricePaddingLeft(hasLeftIcon, showCurrencySymbol) : hasLeftIcon ? '2.5rem' : '1rem';

  return {
    'padding-top': variant === 'in' ? '24px' : '0.625rem',
    'padding-bottom': '0.625rem',
    'padding-left': paddingLeft,
    // Los botones ▲▼ del stepper ocupan el borde derecho: el texto no debe pasar por debajo.
    'padding-right': hasRightIcon ? '2.5rem' : hasStepper ? '2.25rem' : '1rem',
  };
}

/**
 * Relleno del `<textarea>` interno de `sa-textarea`: en `in` el label vive dentro, arriba, y el texto
 * empieza debajo (24px, como el input); un icono a la izquierda o a la derecha reserva su lado para que el
 * texto no pase por debajo.
 */
export function resolveTextareaFieldStyles(variant: SaVariant, hasLabel: boolean, hasLeftIcon: boolean, hasRightIcon: boolean): Record<string, string> {
  return {
    'padding-top': variant === 'in' && hasLabel ? '1.5rem' : '0.625rem',
    'padding-bottom': '0.625rem',
    'padding-left': hasLeftIcon ? '2.5rem' : '1rem',
    'padding-right': hasRightIcon ? '2.5rem' : '1rem',
  };
}

export function resolveControlBackground(disabled: boolean, readonly: boolean): string {
  return disabled || readonly ? 'var(--app-control-disabled-bg)' : 'var(--app-control-surface-bg)';
}

export function resolveInputTextColor(disabled: boolean, readonly: boolean): string {
  return disabled || readonly ? 'var(--app-control-disabled-text)' : 'var(--app-control-surface-text)';
}

export function resolveInputBorderColor(hasErrors: boolean, disabled: boolean, readonly: boolean): string {
  if (hasErrors) return '#e51d21';
  return disabled || readonly ? 'var(--app-control-disabled-border)' : 'var(--app-control-surface-border)';
}

export function resolveFocusBoxShadow(hasErrors: boolean, focused: boolean): string {
  if (hasErrors && focused) return 'inset 0 0 0 2px rgba(229, 29, 33, 0.4)';
  return focused ? 'inset 0 0 0 2px var(--app-control-focus-ring)' : 'none';
}

export function resolveFieldsetBoxShadow(hasErrors: boolean, focused: boolean, disabled: boolean, readonly: boolean): string {
  if (hasErrors) return `inset 0 0 0 ${focused ? 2 : 1}px var(--app-error-color)`;
  if (disabled || readonly) return 'inset 0 0 0 1px var(--app-control-disabled-border)';
  return focused ? 'inset 0 0 0 2px var(--app-control-focus-ring)' : 'inset 0 0 0 1px var(--app-control-surface-border)';
}

export function resolveLabelColor(hasErrors: boolean, disabled: boolean, focused: boolean, hasValue: boolean): string {
  if (hasErrors) return '#e51d21';
  if (disabled) return 'var(--app-disabled-text)';
  if (focused) return 'var(--app-text-primary)';
  return hasValue ? 'var(--app-text-muted)' : 'var(--app-text-subtle)';
}

/**
 * Lógica de posicionamiento del label compartida por `sa-input` y `sa-select`
 * (mismas clases de Tailwind, mismas ramas por variante). La única diferencia real entre ambos
 * componentes es el offset vertical del label flotante en la variante "on" (ni `in` ni `over`):
 * `sa-input` usa `-top-2`, `sa-select` usa `-top-2.5` — por eso ese valor se recibe
 * explícito en vez de codificarlo acá, para no perder esa diferencia deliberada entre ambos.
 */
export function resolveLabelPositionClass(variant: string, shouldFloat: boolean, hasLeftAffordance: boolean, defaultFloatOffsetClass: string): Record<string, boolean> {
  const classes: Record<string, boolean> = {
    // `over` vive afuera, arriba del campo: no hay icono debajo que esquivar, así que no se corre.
    [hasLeftAffordance && variant !== 'over' ? 'left-8' : variant === 'on' ? 'left-3' : 'left-2']: true,
  };

  if (variant === 'in') {
    return { ...classes, ...(shouldFloat ? { 'top-2': true, 'translate-y-0': true, 'text-caption-2-bold': true } : centeredLabelClasses()) };
  }

  // `over` — el label vive siempre afuera/arriba del campo (nunca centrado adentro como
  // placeholder): a diferencia de `in`/`on`, no depende de `shouldFloat` en absoluto. -top-4.5
  // (no -top-4) porque el label completo (line-height + padding) mide más que 1rem — con -top-4
  // quedaba pisando el borde superior del campo en vez de quedar arriba con aire.
  if (variant === 'over') {
    return { ...classes, '-top-4.5': true, 'translate-y-0': true, 'text-caption-2-bold': true };
  }

  return { ...classes, ...(shouldFloat ? { [defaultFloatOffsetClass]: true, 'translate-y-0': true, 'text-caption-2-bold': true } : centeredLabelClasses()) };
}

export function resolveInputLabelClass(variant: SaVariant, shouldFloat: boolean, hasLeftAffordance: boolean): Record<string, boolean> {
  return resolveLabelPositionClass(variant, shouldFloat, hasLeftAffordance, '-top-2');
}

export function unformatPrice(input: string): string {
  if (!input) return '';

  const stripped = input.replace(/,/g, '').replace(/[^\d.]/g, '');
  const parts = stripped.split('.');
  return parts.length > 1 ? parts[0] + '.' + parts.slice(1).join('') : stripped;
}

export function formatPrice(raw: string): string {
  if (!raw) return '';

  const sign = raw.startsWith('-') ? '-' : '';
  const cleaned = raw.replace(/[^0-9.]/g, '');
  const [intPartRaw, decPartRaw] = cleaned.split('.');
  const intPart = (intPartRaw || '').replace(/^0+(?=\d)/, '');
  const withCommas = (intPart || '0').replace(/\B(?=(\d{3})+(?!\d))/g, ',');

  return sign + (decPartRaw !== undefined && decPartRaw !== '' ? `${withCommas}.${decPartRaw}` : withCommas);
}

function resolvePricePaddingLeft(hasLeftIcon: boolean, showCurrencySymbol: boolean): string {
  if (showCurrencySymbol) return hasLeftIcon ? '3rem' : '2rem';
  return hasLeftIcon ? '2.5rem' : '1rem';
}

function centeredLabelClasses(): Record<string, boolean> {
  return { 'top-1/2': true, '-translate-y-1/2': true, 'text-caption-1-medium': true };
}

type InputPresentationDeps = {
  control: () => AbstractControl | null;
  validationTick: () => number;
  type: () => SaInputType;
  isTagInput: () => boolean;
  tags: () => readonly string[];
  value: () => string;
  label: () => string | undefined;
  placeholder: () => string;
  inputId: () => string;
  generatedInputId: string;
  showErrorMessage: () => boolean;
  isDisabled: () => boolean;
  readonly: () => boolean;
  isFocused: () => boolean;
  isInputFocused: () => boolean;
  variant: () => SaVariant;
  hasIcon: () => boolean;
  iconPosition: () => SaIconPosition;
  /** Ausente en consumidores sin stepper numérico (ej. sa-textarea). */
  showStepper?: () => boolean;
  /** Ausente en consumidores que no tienen modo teléfono (ej. sa-textarea). */
  phoneCountryPicker?: () => boolean;
  /** iso2 del país seleccionado en el picker — define el patrón de agrupación de dígitos. */
  phoneCountryIso2?: () => string | undefined;
};

export function createInputPresentation(deps: InputPresentationDeps) {
  const hasErrors = computed(() => {
    deps.validationTick();
    const control = deps.control();
    return !!(control?.invalid && (control.touched || control.dirty));
  });
  const hasValue = computed(() => (deps.isTagInput() ? deps.tags().length > 0 : !!deps.value()));
  const hasLeftIcon = computed(() => deps.hasIcon() && deps.iconPosition() === 'left');
  const showCurrencySymbol = computed(() => deps.type() === 'price' && (deps.isInputFocused() || !!deps.value()));
  // `isFocused` es el foco del modo tag (ver onFocus/onBlur en el input de texto de un tag);
  // `isInputFocused` es el foco del resto de modos — sin el OR, el label de un tag-input no
  // flotaba mientras se escribía el primer tag (sin tags aún, sin `isInputFocused` seteado).
  const shouldFloat = computed(() => hasValue() || deps.isInputFocused() || deps.isFocused() || hasErrors());
  // Sin label, o con variant="over" (el label ya no se superpone al campo — vive afuera, arriba,
  // siempre visible), el placeholder se muestra siempre; si no, solo mientras está enfocado o en
  // error (para no pisar el label flotante de `in`/`on`).
  const shouldShowPlaceholder = computed(() => !deps.isDisabled() && !deps.readonly() && (!deps.label() || deps.variant() === 'over' || deps.isInputFocused() || hasErrors()));
  const resolvedInputId = computed(() => deps.inputId().trim() || deps.generatedInputId);

  return {
    hasErrors,
    hasValue,
    hasLeftIcon,
    showCurrencySymbol,
    shouldFloat,
    resolvedInputId,
    errorId: computed(() => `${resolvedInputId()}-error`),
    errorMessage: computed(() => (hasErrors() ? resolveInputErrorMessage(deps.control()?.errors, deps.label() || deps.placeholder() || 'Este campo') : '')),
    displayValue: computed(() => {
      if (deps.isTagInput()) return '';
      if (deps.phoneCountryPicker?.()) return groupNationalDigits(deps.value(), deps.phoneCountryIso2?.());
      return deps.type() === 'price' && !deps.isInputFocused() ? formatPrice(deps.value()) : deps.value();
    }),
    inputType: computed(() => resolveInputType(deps.type())),
    describedBy: computed(() => (hasErrors() && deps.showErrorMessage() ? `${resolvedInputId()}-error` : null)),
    placeholderAttr: computed(() => {
      const placeholder = deps.placeholder();
      if (!placeholder) return ' ';
      return !deps.label() || shouldShowPlaceholder() ? placeholder : ' ';
    }),
    inputFieldStyles: computed(() => resolveInputFieldStyles(deps.type(), hasLeftIcon(), showCurrencySymbol(), deps.hasIcon() && deps.iconPosition() === 'right', deps.variant(), deps.type() === 'number' && !!deps.showStepper?.())),
    inputFieldNgClass: computed(() => ({
      'sa-input-field--disabled': deps.isDisabled() || deps.readonly(),
      'sa-input-field--placeholder-hidden': !shouldShowPlaceholder(),
    })),
    inputBackground: computed(() => resolveControlBackground(deps.isDisabled(), deps.readonly())),
    inputTextColor: computed(() => resolveInputTextColor(deps.isDisabled(), deps.readonly())),
    inputBorderColor: computed(() => resolveInputBorderColor(hasErrors(), deps.isDisabled(), deps.readonly())),
    inputBoxShadow: computed(() => resolveFocusBoxShadow(hasErrors(), deps.isInputFocused())),
    tagContainerBackground: computed(() => resolveControlBackground(deps.isDisabled(), deps.readonly())),
    // Igual que `fieldsetBoxShadow` (el borde SIEMPRE es un box-shadow inset visible, nunca
    // `resolveFocusBoxShadow` que devuelve 'none' en reposo) — acá con `isFocused` (el foco del
    // sub-input de texto en modo tag) en vez de `isInputFocused`. Sin esto, el fieldset del modo
    // tag quedaba sin borde en reposo y el <legend> no tenía nada que "recortar" para el label.
    tagContainerBoxShadow: computed(() => resolveFieldsetBoxShadow(hasErrors(), deps.isFocused(), deps.isDisabled(), deps.readonly())),
    legendOffset: computed(() => (hasLeftIcon() || showCurrencySymbol() ? '2rem' : '0.75rem')),
    legendMaxWidth: computed(() => (shouldFloat() ? '999px' : '0px')),
    legendTransition: computed(() => (shouldFloat() ? 'max-width 180ms ease' : 'max-width 80ms ease')),
    fieldsetClasses: computed(() => ({
      'bg-(--app-control-surface-bg)': !deps.isDisabled() && !deps.readonly(),
      'cursor-not-allowed bg-(--app-control-disabled-bg)': deps.isDisabled() || deps.readonly(),
    })),
    fieldsetBoxShadow: computed(() => resolveFieldsetBoxShadow(hasErrors(), deps.isInputFocused(), deps.isDisabled(), deps.readonly())),
    labelBackground: computed(() => (deps.variant() === 'on' ? resolveControlBackground(deps.isDisabled(), deps.readonly()) : 'transparent')),
    labelColor: computed(() => resolveLabelColor(hasErrors(), deps.isDisabled(), deps.isInputFocused() || deps.isFocused(), hasValue())),
    labelClass: computed(() => resolveInputLabelClass(deps.variant(), shouldFloat(), hasLeftIcon() || showCurrencySymbol())),
  };
}
