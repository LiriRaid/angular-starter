import type { ElementRef } from '@angular/core';

import { SELECT_ALL_VALUE } from './sa-select.config';

type SelectInteractionsDeps = {
  isMultiSelect: () => boolean;
  isAnyMultiSelect: () => boolean;
  searchable: () => boolean;
  isDisabled: () => boolean;
  readonly: () => boolean;
  /** Bloquea abrir/cambiar el select SIN aplicar la apariencia visual de disabled (esa la
   *  maneja aparte sa-select.config.ts) — distinto de isDisabled/readonly, que si
   *  cambian el estilo. */
  interactionDisabled: () => boolean;
  hasValue: () => boolean;
  allVisibleSelected: () => boolean;
  currentValues: () => unknown[];
  visibleOptionValues: () => unknown[];
  optionValueOf: (option: unknown) => unknown;
  isValidOptionValue: (value: unknown) => boolean;
  setSearchTerm: (value: string) => void;
  setFocused: (value: boolean) => void;
  setValue: (value: unknown) => void;
  emitValue: (value: unknown) => void;
  refreshValidation: () => void;
  touch: () => void;
  multiSearchInput: () => ElementRef<HTMLInputElement> | undefined;
  preservePanelOpen: {
    set(value: boolean): void;
    (): boolean;
  };
  isOpen: () => boolean;
  showPanel: () => void;
  hidePanel: () => void;
  activeOptions: () => unknown[];
  activeIndex: {
    set(value: number | null): void;
    (): number | null;
  };
  isSelectAllOption: (option: unknown) => boolean;
};

export function createSelectInteractions(deps: SelectInteractionsDeps) {
  let blurTimer: ReturnType<typeof setTimeout> | undefined;

  const commitSingleSelectValue = (value: unknown): void => {
    deps.setValue(value);
    deps.emitValue(value);
  };

  const commitMultiSelectValue = (value: unknown[]): void => {
    deps.setValue(value);
    deps.emitValue(value);
  };

  const clearSelection = (): void => {
    if (!deps.hasValue()) return;
    if (deps.isAnyMultiSelect()) {
      commitMultiSelectValue([]);
      return;
    }
    commitSingleSelectValue(null);
  };

  const openPanel = (): void => {
    if (deps.isDisabled() || deps.readonly() || deps.interactionDisabled()) return;
    deps.showPanel();
    deps.setFocused(true);
  };

  const closePanel = (): void => {
    deps.hidePanel();
    deps.activeIndex.set(null);
  };

  const focusMultiSelectSearchInput = (): void => {
    if (!deps.isMultiSelect() || !deps.searchable()) return;
    setTimeout(() => deps.multiSearchInput()?.nativeElement.focus());
  };

  const keepMultiSelectPanelOpen = (): void => {
    if (!deps.isAnyMultiSelect()) return;

    deps.preservePanelOpen.set(true);
    openPanel();
    focusMultiSelectSearchInput();

    setTimeout(() => {
      openPanel();
      focusMultiSelectSearchInput();
      deps.preservePanelOpen.set(false);
    }, 120);
  };

  const stopEvent = (event: Event): void => {
    event.preventDefault();
    event.stopPropagation();
  };

  const toggleAllVisibleOptions = (event?: Event): void => {
    if (!deps.isAnyMultiSelect() || deps.isDisabled() || deps.readonly() || deps.interactionDisabled()) return;
    if (event) stopEvent(event);

    const selectedValues = deps.currentValues();
    const visibleValues = deps.visibleOptionValues();
    if (visibleValues.length === 0) return;

    const nextValues = deps.allVisibleSelected() ? selectedValues.filter((value) => !visibleValues.includes(value)) : [...new Set([...selectedValues, ...visibleValues])];
    commitMultiSelectValue(nextValues);
    keepMultiSelectPanelOpen();
  };

  const moveActiveIndex = (delta: number): void => {
    const count = deps.activeOptions().length;
    if (count === 0) return;

    const current = deps.activeIndex();
    const next = current === null ? (delta > 0 ? 0 : count - 1) : Math.min(Math.max(current + delta, 0), count - 1);
    deps.activeIndex.set(next);
  };

  const selectOption = (option: unknown): void => {
    if (deps.isAnyMultiSelect()) {
      if (deps.isSelectAllOption(option)) {
        toggleAllVisibleOptions();
        return;
      }

      const value = deps.optionValueOf(option);
      const values = deps.currentValues();
      const nextValues = values.includes(value) ? values.filter((item) => item !== value) : [...values, value];
      commitMultiSelectValue(nextValues);
      keepMultiSelectPanelOpen();
      return;
    }

    commitSingleSelectValue(deps.optionValueOf(option));
    deps.setSearchTerm('');
    closePanel();
  };

  return {
    onSelectChange(value: unknown): void {
      if (deps.isAnyMultiSelect()) {
        const rawValues = Array.isArray(value) ? [...value] : [];
        if (rawValues.includes(SELECT_ALL_VALUE)) {
          toggleAllVisibleOptions();
        } else {
          commitMultiSelectValue(rawValues.filter((item) => item !== SELECT_ALL_VALUE));
        }
        return;
      }

      const typedValue = typeof value === 'string' ? value : '';

      // Vacío nunca debe auto-confirmar una opción, aunque coincida con una que tenga
      // value: '' (ej. "Todos los roles") — si no, borrar todo el texto "selecciona" esa
      // opción de casualidad y el campo se ve como si se hubiera reiniciado a ella.
      if (deps.searchable() && (!typedValue.trim() || !deps.isValidOptionValue(value))) {
        deps.setSearchTerm(typedValue);
        if (!typedValue.trim()) {
          clearSelection();
        } else if (!deps.isOpen()) {
          // Como en PrimeNG: escribir con el panel cerrado (ej. tras llegar con Tab, sin
          // click previo) debe abrirlo automáticamente si hay texto tipeado.
          openPanel();
        }
        return;
      }

      commitSingleSelectValue(value);
      deps.setSearchTerm('');
    },
    onFocus(): void {
      clearTimeout(blurTimer);
      deps.setFocused(true);
      deps.refreshValidation();
    },
    onBlur(): void {
      clearTimeout(blurTimer);
      blurTimer = setTimeout(() => {
        if (deps.preservePanelOpen()) return;
        deps.setFocused(false);
        if (!deps.isAnyMultiSelect() && deps.searchable()) {
          deps.setSearchTerm('');
        }
        closePanel();
        deps.touch();
        deps.refreshValidation();
      });
    },
    onEditableTriggerPointer(event: Event): void {
      if (deps.isMultiSelect() || deps.isDisabled() || deps.readonly() || deps.interactionDisabled()) return;
      stopEvent(event);
      openPanel();
    },
    onMultiSelectSearchPointer(event: Event): void {
      if (!deps.isMultiSelect() || deps.isDisabled() || deps.readonly() || deps.interactionDisabled()) return;
      stopEvent(event);
      openPanel();
      focusMultiSelectSearchInput();
    },
    onMultiSelectSearchInput(event: Event): void {
      if (!deps.isMultiSelect()) return;
      const target = event.target;
      if (!(target instanceof HTMLInputElement)) return;
      deps.setSearchTerm(target.value);
      openPanel();
    },
    onSelectedChipPointer: stopEvent,
    onChipRemovePointer: stopEvent,
    removeSelectedOption(option: unknown, event?: Event): void {
      if (!deps.isMultiSelect() || deps.isDisabled() || deps.readonly() || deps.interactionDisabled()) return;
      if (event) stopEvent(event);
      commitMultiSelectValue(deps.currentValues().filter((value) => value !== deps.optionValueOf(option)));
      keepMultiSelectPanelOpen();
    },
    toggleAllVisibleOptions,
    selectOption,
    clearValue(event?: Event): void {
      if (deps.isDisabled() || deps.readonly() || deps.interactionDisabled()) return;
      if (event) stopEvent(event);
      clearSelection();
      deps.touch();
    },
    openPanel,
    closePanel,
    togglePanel(): void {
      if (deps.isOpen()) {
        closePanel();
      } else {
        openPanel();
        if (deps.isMultiSelect()) focusMultiSelectSearchInput();
      }
    },
    onTriggerKeydown(event: KeyboardEvent): void {
      if (deps.isDisabled() || deps.readonly() || deps.interactionDisabled()) return;

      switch (event.key) {
        case 'ArrowDown':
          event.preventDefault();
          if (!deps.isOpen()) openPanel();
          moveActiveIndex(1);
          break;
        case 'ArrowUp':
          event.preventDefault();
          if (!deps.isOpen()) openPanel();
          moveActiveIndex(-1);
          break;
        case 'Home':
          if (deps.isOpen()) {
            event.preventDefault();
            deps.activeIndex.set(0);
          }
          break;
        case 'End':
          if (deps.isOpen()) {
            event.preventDefault();
            deps.activeIndex.set(deps.activeOptions().length - 1);
          }
          break;
        case 'Enter': {
          const index = deps.activeIndex();
          if (deps.isOpen() && index !== null) {
            event.preventDefault();
            selectOption(deps.activeOptions()[index]);
          }
          break;
        }
        case 'Escape':
          if (deps.isOpen()) {
            event.preventDefault();
            closePanel();
          }
          break;
        case 'Tab':
          closePanel();
          break;
      }
    },
  };
}
