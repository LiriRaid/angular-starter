import { computed } from '@angular/core';
import type { AbstractControl } from '@angular/forms';
import type { ValidationErrors } from '@angular/forms';

// El look del label (color, sombra del fieldset, posicionamiento flotante) es prácticamente
// idéntico al de `sa-input` — en vez de duplicar esas fórmulas se reusan directo sus
// funciones puras (ya pensadas para no depender de estado del componente dueño).
import { resolveFieldsetBoxShadow, resolveLabelColor, resolveLabelPositionClass } from '../sa-input/sa-input.config';
import { resolveSide, type IPanelBounds } from '@shared/utils/panel-placement';
import type { SaIconPosition, SaSelectVariant } from './sa-select.entity';

export const SELECT_ALL_VALUE = '__all__';

export type SelectPanelLayout = {
  top: number;
  left: number;
  width: number;
  placement: 'top' | 'bottom';
};

/** A diferencia del popover, el panel de Select no lleva flecha y siempre tiene el mismo
 *  ancho que el trigger — prueba abajo primero, si no cabe prueba arriba, y si tampoco cabe
 *  se queda abajo clampeado al viewport (mismo criterio de fallback que el tooltip/popover).
 *  Con `bounds` (el área donde el trigger se ve: la ventana recortada por sus contenedores con scroll)
 *  el espacio se mide contra ese área y no contra toda la ventana; si ningún lado cabe, el que tiene más. */
export function getSelectPanelLayout(triggerRect: DOMRect, panelHeight: number, viewportWidth: number, viewportHeight: number, gap: number = 2, viewportMargin: number = 8, bounds?: IPanelBounds): SelectPanelLayout {
  const belowTop = triggerRect.bottom + gap;
  const aboveTop = triggerRect.top - panelHeight - gap;
  const fitsBelow = belowTop + panelHeight <= viewportHeight - viewportMargin;
  const fitsAbove = aboveTop >= viewportMargin;

  const side = bounds ? resolveSide({ preferred: 'bottom', allowed: ['bottom', 'top'], trigger: triggerRect, size: { width: triggerRect.width, height: panelHeight }, bounds, gap, margin: viewportMargin }) : null;
  const placement: 'top' | 'bottom' = side ? (side === 'top' ? 'top' : 'bottom') : fitsBelow || !fitsAbove ? 'bottom' : 'top';
  const top = clamp(placement === 'bottom' ? belowTop : aboveTop, viewportMargin, viewportHeight - panelHeight - viewportMargin);
  const left = clamp(triggerRect.left, viewportMargin, viewportWidth - triggerRect.width - viewportMargin);

  return { top, left, width: triggerRect.width, placement };
}

function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max);
}

export function coerceBooleanAttribute(value: boolean | string): boolean {
  return value === '' || value === true || value === 'true';
}

export function pluckOption(option: unknown, key: string | undefined): unknown {
  if (key && option && typeof option === 'object') {
    return (option as Record<string, unknown>)[key];
  }

  return option;
}

export function filterSelectOptions(options: unknown[], term: string, searchable: boolean, labelForOption: (option: unknown) => string): unknown[] {
  const normalizedTerm = term.trim().toLowerCase();
  return searchable && normalizedTerm ? options.filter((option) => labelForOption(option).toLowerCase().includes(normalizedTerm)) : options;
}

export function getSelectedOptions(values: readonly unknown[], options: readonly unknown[], optionValueOf: (option: unknown) => unknown): unknown[] {
  return values.map((value) => options.find((option) => optionValueOf(option) === value) ?? null).filter((option): option is NonNullable<typeof option> => option !== null);
}

export function allVisibleOptionsSelected(selectedValues: readonly unknown[], visibleValues: readonly unknown[]): boolean {
  return visibleValues.length > 0 && visibleValues.every((value) => selectedValues.includes(value));
}

export function resolveSelectErrorMessage(errors: ValidationErrors | null | undefined, label: string): string {
  if (!errors) return '';
  return errors['required'] ? `${label} es requerido` : `${label} es inválido`;
}

export function resolveSelectFieldsetBoxShadow(hasErrors: boolean, focused: boolean, disabled: boolean, readonly: boolean): string {
  return resolveFieldsetBoxShadow(hasErrors, focused, disabled, readonly);
}

export function resolveSelectLabelBackground(variant: SaSelectVariant, disabled: boolean, readonly: boolean): string {
  if (variant !== 'on') return 'transparent';
  return disabled || readonly ? 'var(--app-control-disabled-bg)' : 'var(--app-control-surface-bg)';
}

export function resolveSelectLabelColor(hasErrors: boolean, disabled: boolean, focused: boolean, hasValue: boolean): string {
  return resolveLabelColor(hasErrors, disabled, focused, hasValue);
}

export function resolveSelectLabelClass(variant: SaSelectVariant, shouldFloat: boolean, hasLeftIcon: boolean): Record<string, boolean> {
  return resolveLabelPositionClass(variant, shouldFloat, hasLeftIcon, '-top-2.5');
}

export function createSelectAllOption(labelKey: string, valueKey: string): Record<string, unknown> {
  return {
    [labelKey]: 'Seleccionar todos',
    [valueKey]: SELECT_ALL_VALUE,
  };
}

export function normalizeSelectValue(value: unknown, isAnyMultiSelect: boolean): unknown {
  if (isAnyMultiSelect || Array.isArray(value)) {
    return Array.isArray(value) ? value.filter((item) => item !== SELECT_ALL_VALUE) : [];
  }

  return value ?? null;
}

type SelectPresentationDeps = {
  control: () => AbstractControl | null;
  validationTick: () => number;
  multiselect: () => boolean | string;
  readonlyInput: () => boolean | string;
  value: () => unknown;
  options: () => unknown[];
  optionLabel: () => string | undefined;
  optionValue: () => string | undefined;
  searchTerm: () => string;
  searchable: () => boolean;
  placeholder: () => string;
  label: () => string | undefined;
  inputId: () => string;
  generatedId: string;
  showErrorMessage: () => boolean;
  lucideIcon: () => unknown;
  iconPosition: () => SaIconPosition;
  isFocused: () => boolean;
  isDisabled: () => boolean;
  isInteractionDisabled: () => boolean;
  variant: () => SaSelectVariant;
  currentValues: () => unknown[];
  optionValueOf: (option: unknown) => unknown;
  labelForOption: (option: unknown) => string;
  selectAllOption: () => Record<string, unknown>;
};

export function createSelectPresentation(deps: SelectPresentationDeps) {
  const isMultiSelect = computed(() => coerceBooleanAttribute(deps.multiselect()));
  const isCompactMultiSelect = computed(() => deps.multiselect() === 'compact');
  const isAnyMultiSelect = computed(() => isMultiSelect() || isCompactMultiSelect());
  const isCompactSingleSelect = computed(() => deps.variant() === 'compact' && !isAnyMultiSelect());
  const readonly = computed(() => coerceBooleanAttribute(deps.readonlyInput()));
  const selectedCount = computed(() => deps.currentValues().length);
  const hasIcon = computed(() => !!deps.lucideIcon());
  const hasLeftIcon = computed(() => hasIcon() && deps.iconPosition() === 'left');
  const resolvedInputId = computed(() => deps.inputId().trim() || deps.generatedId);
  const displayOptions = computed(() => filterSelectOptions(deps.options(), deps.searchTerm(), deps.searchable(), deps.labelForOption));
  const visibleOptionValues = computed(() => displayOptions().map(deps.optionValueOf));
  const selectedOptions = computed(() => (deps.currentValues().length === 0 ? [] : getSelectedOptions(deps.currentValues(), deps.options(), deps.optionValueOf)));
  const allVisibleSelected = computed(() => isAnyMultiSelect() && allVisibleOptionsSelected(deps.currentValues(), visibleOptionValues()));
  const hasErrors = computed(() => {
    deps.validationTick();
    const control = deps.control();
    return !!(control?.invalid && (control.touched || control.dirty));
  });
  const hasValue = computed(() => {
    if (isAnyMultiSelect()) return deps.currentValues().length > 0;
    const value = deps.value();
    return value !== null && value !== undefined && (value !== '' || deps.options().some((option) => deps.optionValueOf(option) === value));
  });
  const shouldFloat = computed(() => hasValue() || deps.isFocused() || hasErrors());
  const shouldFloatLabel = computed(() => shouldFloat() || (isMultiSelect() && deps.searchTerm().trim().length > 0));

  return {
    isMultiSelect,
    isCompactMultiSelect,
    isCompactSingleSelect,
    isAnyMultiSelect,
    readonly,
    selectedCount,
    hasIcon,
    hasLeftIcon,
    resolvedInputId,
    displayOptions,
    selectedOptions,
    allVisibleSelected,
    hasErrors,
    hasValue,
    shouldFloat,
    shouldFloatLabel,
    value: computed(() => deps.value()),
    errorId: computed(() => `${resolvedInputId()}-error`),
    multiselectOptions: computed(() => (isAnyMultiSelect() ? [deps.selectAllOption(), ...displayOptions()] : displayOptions())),
    errorMessage: computed(() => (hasErrors() ? resolveSelectErrorMessage(deps.control()?.errors, deps.label() || deps.placeholder() || 'Este campo') : '')),
    describedBy: computed(() => (hasErrors() && deps.showErrorMessage() ? `${resolvedInputId()}-error` : null)),
    multiSearchPlaceholder: computed(() => (!deps.searchable() || !shouldFloatLabel() ? '' : selectedOptions().length === 0 ? deps.placeholder() : 'Buscar...')),
    legendOffset: computed(() => (hasLeftIcon() ? '2rem' : '0.75rem')),
    legendMaxWidth: computed(() => (shouldFloatLabel() ? '999px' : '0px')),
    legendTransition: computed(() => (shouldFloatLabel() ? 'max-width 180ms ease' : 'max-width 80ms ease')),
    fieldsetBoxShadow: computed(() => resolveSelectFieldsetBoxShadow(hasErrors(), deps.isFocused(), deps.isDisabled(), readonly())),
    fieldsetClasses: computed(() => ({
      'bg-(--app-control-surface-bg)': !deps.isDisabled() && !readonly() && !deps.isInteractionDisabled(),
      'cursor-not-allowed bg-(--app-control-disabled-bg)': deps.isDisabled() || readonly() || deps.isInteractionDisabled(),
    })),
    labelBackground: computed(() => resolveSelectLabelBackground(deps.variant(), deps.isDisabled(), readonly())),
    labelColor: computed(() => resolveSelectLabelColor(hasErrors(), deps.isDisabled(), deps.isFocused(), hasValue())),
    labelClass: computed(() => resolveSelectLabelClass(deps.variant(), shouldFloatLabel(), hasLeftIcon())),
  };
}
