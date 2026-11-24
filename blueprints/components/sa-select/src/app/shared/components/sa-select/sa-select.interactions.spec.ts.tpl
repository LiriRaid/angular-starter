import type { ElementRef } from '@angular/core';
import { describe, expect, it, vi, beforeEach, afterEach } from 'vitest';
import { createSelectInteractions } from './sa-select.interactions';
import { SELECT_ALL_VALUE } from './sa-select.config';

type Option = { label: string; value: string };

const OPTIONS: Option[] = [
  { label: 'Uno', value: 'a' },
  { label: 'Dos', value: 'b' },
  { label: 'Tres', value: 'c' },
];

function createDeps(overrides: Partial<Record<string, unknown>> = {}) {
  let isOpen = false;
  let activeIndex: number | null = null;
  let currentValues: unknown[] = [];
  let preservePanelOpen = false;

  const deps = {
    isMultiSelect: vi.fn(() => false),
    isAnyMultiSelect: vi.fn(() => false),
    searchable: vi.fn(() => false),
    isDisabled: vi.fn(() => false),
    readonly: vi.fn(() => false),
    interactionDisabled: vi.fn(() => false),
    hasValue: vi.fn(() => currentValues.length > 0),
    allVisibleSelected: vi.fn(() => false),
    currentValues: vi.fn(() => currentValues),
    visibleOptionValues: vi.fn(() => OPTIONS.map((o) => o.value)),
    optionValueOf: vi.fn((option: unknown) => (option as Option).value),
    isValidOptionValue: vi.fn((value: unknown) => OPTIONS.some((o) => o.value === value)),
    setSearchTerm: vi.fn(),
    setFocused: vi.fn(),
    setValue: vi.fn((value: unknown) => {
      currentValues = Array.isArray(value) ? value : value === null ? [] : [value];
    }),
    emitValue: vi.fn(),
    refreshValidation: vi.fn(),
    touch: vi.fn(),
    multiSearchInput: vi.fn(() => ({ nativeElement: { focus: vi.fn() } }) as unknown as ElementRef<HTMLInputElement>),
    preservePanelOpen: Object.assign(
      (() => preservePanelOpen) as { (): boolean; set(value: boolean): void },
      { set: (value: boolean) => (preservePanelOpen = value) },
    ),
    isOpen: vi.fn(() => isOpen),
    showPanel: vi.fn(() => (isOpen = true)),
    hidePanel: vi.fn(() => (isOpen = false)),
    activeOptions: vi.fn(() => OPTIONS),
    activeIndex: Object.assign((() => activeIndex) as { (): number | null; set(value: number | null): void }, {
      set: (value: number | null) => (activeIndex = value),
    }),
    isSelectAllOption: vi.fn((option: unknown) => (option as Option).value === SELECT_ALL_VALUE),
    ...overrides,
  };

  return deps;
}

function keyEvent(key: string): KeyboardEvent {
  return { key, preventDefault: vi.fn(), stopPropagation: vi.fn() } as unknown as KeyboardEvent;
}

describe('createSelectInteractions', () => {
  describe('single select', () => {
    it('confirma el valor y limpia el termino de busqueda cuando el value coincide con una opcion', () => {
      const deps = createDeps({ searchable: vi.fn(() => true) });
      const interactions = createSelectInteractions(deps);

      interactions.onSelectChange('b');

      expect(deps.setValue).toHaveBeenCalledWith('b');
      expect(deps.emitValue).toHaveBeenCalledWith('b');
      expect(deps.setSearchTerm).toHaveBeenCalledWith('');
    });

    it('no auto-confirma un value vacio aunque exista una opcion con value=""; limpia la seleccion', () => {
      const deps = createDeps({
        searchable: vi.fn(() => true),
        isValidOptionValue: vi.fn(() => true),
        hasValue: vi.fn(() => true),
      });
      const interactions = createSelectInteractions(deps);

      interactions.onSelectChange('');

      expect(deps.setValue).toHaveBeenCalledWith(null);
      expect(deps.emitValue).toHaveBeenCalledWith(null);
    });

    it('abre el panel automaticamente si llega texto tipeado con el panel cerrado', () => {
      const deps = createDeps({ searchable: vi.fn(() => true) });
      const interactions = createSelectInteractions(deps);

      interactions.onSelectChange('xyz-no-existe');

      expect(deps.setSearchTerm).toHaveBeenCalledWith('xyz-no-existe');
      expect(deps.showPanel).toHaveBeenCalled();
    });
  });

  describe('multi select', () => {
    it('togglea todas las opciones visibles cuando el value incluye SELECT_ALL_VALUE', () => {
      const deps = createDeps({ isAnyMultiSelect: vi.fn(() => true) });
      const interactions = createSelectInteractions(deps);

      interactions.onSelectChange([SELECT_ALL_VALUE]);

      expect(deps.setValue).toHaveBeenCalledWith(['a', 'b', 'c']);
    });

    it('selectOption agrega el value si no estaba seleccionado', () => {
      const deps = createDeps({ isAnyMultiSelect: vi.fn(() => true), currentValues: vi.fn(() => ['a']) });
      const interactions = createSelectInteractions(deps);

      interactions.selectOption(OPTIONS[1]);

      expect(deps.setValue).toHaveBeenCalledWith(['a', 'b']);
    });

    it('selectOption quita el value si ya estaba seleccionado', () => {
      const deps = createDeps({ isAnyMultiSelect: vi.fn(() => true), currentValues: vi.fn(() => ['a', 'b']) });
      const interactions = createSelectInteractions(deps);

      interactions.selectOption(OPTIONS[1]);

      expect(deps.setValue).toHaveBeenCalledWith(['a']);
    });

    it('toggleAllVisibleOptions deselecciona todo si ya estaban todas seleccionadas', () => {
      const deps = createDeps({
        isAnyMultiSelect: vi.fn(() => true),
        allVisibleSelected: vi.fn(() => true),
        currentValues: vi.fn(() => ['a', 'b', 'c']),
      });
      const interactions = createSelectInteractions(deps);

      interactions.toggleAllVisibleOptions();

      expect(deps.setValue).toHaveBeenCalledWith([]);
    });

    it('removeSelectedOption quita el value indicado del array actual', () => {
      const deps = createDeps({ isMultiSelect: vi.fn(() => true), currentValues: vi.fn(() => ['a', 'b']) });
      const interactions = createSelectInteractions(deps);

      interactions.removeSelectedOption(OPTIONS[0]);

      expect(deps.setValue).toHaveBeenCalledWith(['b']);
    });
  });

  describe('navegacion por teclado (onTriggerKeydown)', () => {
    it('ArrowDown abre el panel si estaba cerrado y activa el primer index', () => {
      const deps = createDeps();
      const interactions = createSelectInteractions(deps);

      interactions.onTriggerKeydown(keyEvent('ArrowDown'));

      expect(deps.showPanel).toHaveBeenCalled();
      expect(deps.activeIndex()).toBe(0);
    });

    it('ArrowDown avanza el index activo cuando el panel ya esta abierto', () => {
      const deps = createDeps();
      const interactions = createSelectInteractions(deps);
      interactions.openPanel();
      deps.activeIndex.set(0);

      interactions.onTriggerKeydown(keyEvent('ArrowDown'));

      expect(deps.activeIndex()).toBe(1);
    });

    it('ArrowUp retrocede el index activo y no baja de 0', () => {
      const deps = createDeps();
      const interactions = createSelectInteractions(deps);
      interactions.openPanel();
      deps.activeIndex.set(0);

      interactions.onTriggerKeydown(keyEvent('ArrowUp'));

      expect(deps.activeIndex()).toBe(0);
    });

    it('Home mueve el index activo a 0 solo si el panel esta abierto', () => {
      const deps = createDeps();
      const interactions = createSelectInteractions(deps);
      interactions.openPanel();
      deps.activeIndex.set(2);

      interactions.onTriggerKeydown(keyEvent('Home'));

      expect(deps.activeIndex()).toBe(0);
    });

    it('End mueve el index activo al ultimo elemento', () => {
      const deps = createDeps();
      const interactions = createSelectInteractions(deps);
      interactions.openPanel();

      interactions.onTriggerKeydown(keyEvent('End'));

      expect(deps.activeIndex()).toBe(OPTIONS.length - 1);
    });

    it('Enter selecciona la opcion activa y cierra el panel (single select)', () => {
      const deps = createDeps();
      const interactions = createSelectInteractions(deps);
      interactions.openPanel();
      deps.activeIndex.set(1);

      interactions.onTriggerKeydown(keyEvent('Enter'));

      expect(deps.setValue).toHaveBeenCalledWith('b');
      expect(deps.isOpen()).toBe(false);
    });

    it('Enter no hace nada si no hay index activo', () => {
      const deps = createDeps();
      const interactions = createSelectInteractions(deps);
      interactions.openPanel();

      interactions.onTriggerKeydown(keyEvent('Enter'));

      expect(deps.setValue).not.toHaveBeenCalled();
    });

    it('Escape cierra el panel', () => {
      const deps = createDeps();
      const interactions = createSelectInteractions(deps);
      interactions.openPanel();

      interactions.onTriggerKeydown(keyEvent('Escape'));

      expect(deps.isOpen()).toBe(false);
    });

    it('Tab cierra el panel sin prevenir el comportamiento default', () => {
      const deps = createDeps();
      const interactions = createSelectInteractions(deps);
      interactions.openPanel();
      const event = keyEvent('Tab');

      interactions.onTriggerKeydown(event);

      expect(deps.isOpen()).toBe(false);
      expect(event.preventDefault).not.toHaveBeenCalled();
    });

    it('ignora las teclas si el select esta disabled', () => {
      const deps = createDeps({ isDisabled: vi.fn(() => true) });
      const interactions = createSelectInteractions(deps);

      interactions.onTriggerKeydown(keyEvent('ArrowDown'));

      expect(deps.showPanel).not.toHaveBeenCalled();
    });
  });

  describe('togglePanel / openPanel / closePanel', () => {
    it('togglePanel abre el panel si estaba cerrado', () => {
      const deps = createDeps();
      const interactions = createSelectInteractions(deps);

      interactions.togglePanel();

      expect(deps.isOpen()).toBe(true);
    });

    it('togglePanel cierra el panel si estaba abierto', () => {
      const deps = createDeps();
      const interactions = createSelectInteractions(deps);
      interactions.openPanel();

      interactions.togglePanel();

      expect(deps.isOpen()).toBe(false);
    });

    it('openPanel no hace nada si el select esta disabled o readonly', () => {
      const deps = createDeps({ isDisabled: vi.fn(() => true) });
      const interactions = createSelectInteractions(deps);

      interactions.openPanel();

      expect(deps.showPanel).not.toHaveBeenCalled();
    });
  });

  describe('blur / focus con temporizadores', () => {
    beforeEach(() => {
      vi.useFakeTimers();
    });

    afterEach(() => {
      vi.useRealTimers();
    });

    it('onBlur cierra el panel tras el tick asincrono', () => {
      const deps = createDeps();
      const interactions = createSelectInteractions(deps);
      interactions.openPanel();

      interactions.onBlur();
      vi.runAllTimers();

      expect(deps.setFocused).toHaveBeenCalledWith(false);
      expect(deps.isOpen()).toBe(false);
      expect(deps.touch).toHaveBeenCalled();
    });

    it('onBlur no cierra el panel si preservePanelOpen esta activo (multiselect manteniendo apertura)', () => {
      const deps = createDeps({ isAnyMultiSelect: vi.fn(() => true) });
      const interactions = createSelectInteractions(deps);
      interactions.selectOption(OPTIONS[0]);

      interactions.onBlur();
      vi.runAllTimers();

      expect(deps.isOpen()).toBe(true);
    });

    it('onFocus cancela un blur pendiente', () => {
      const deps = createDeps();
      const interactions = createSelectInteractions(deps);
      interactions.openPanel();

      interactions.onBlur();
      interactions.onFocus();
      vi.runAllTimers();

      expect(deps.isOpen()).toBe(true);
      expect(deps.setFocused).toHaveBeenLastCalledWith(true);
    });

    it('selectOption en multiselect mantiene el panel abierto tras los 120ms de keepMultiSelectPanelOpen', () => {
      const deps = createDeps({ isAnyMultiSelect: vi.fn(() => true) });
      const interactions = createSelectInteractions(deps);

      interactions.selectOption(OPTIONS[0]);
      expect(deps.isOpen()).toBe(true);

      vi.advanceTimersByTime(120);

      expect(deps.isOpen()).toBe(true);
      expect(deps.preservePanelOpen()).toBe(false);
    });
  });

  describe('clearValue', () => {
    it('limpia la seleccion en single select', () => {
      const deps = createDeps({ hasValue: vi.fn(() => true) });
      const interactions = createSelectInteractions(deps);

      interactions.clearValue();

      expect(deps.setValue).toHaveBeenCalledWith(null);
      expect(deps.touch).toHaveBeenCalled();
    });

    it('limpia la seleccion en multi select con un array vacio', () => {
      const deps = createDeps({ isAnyMultiSelect: vi.fn(() => true), hasValue: vi.fn(() => true) });
      const interactions = createSelectInteractions(deps);

      interactions.clearValue();

      expect(deps.setValue).toHaveBeenCalledWith([]);
    });

    it('no hace nada si el select esta disabled', () => {
      const deps = createDeps({ isDisabled: vi.fn(() => true), hasValue: vi.fn(() => true) });
      const interactions = createSelectInteractions(deps);

      interactions.clearValue();

      expect(deps.setValue).not.toHaveBeenCalled();
    });
  });
});
