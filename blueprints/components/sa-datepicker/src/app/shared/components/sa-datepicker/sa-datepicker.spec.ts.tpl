import { ComponentFixture, TestBed } from '@angular/core/testing';

import { AsDatepicker } from './as-datepicker';

describe('AsDatepicker', () => {
  let fixture: ComponentFixture<AsDatepicker>;
  let component: AsDatepicker;

  beforeEach(async () => {
    TestBed.overrideComponent(AsDatepicker, { set: { imports: [], template: '' } });

    await TestBed.configureTestingModule({ imports: [AsDatepicker] }).compileComponents();

    fixture = TestBed.createComponent(AsDatepicker);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('creates the component', () => {
    expect(component).toBeTruthy();
  });

  describe('contrato de valor (ControlValueAccessor)', () => {
    it('writeValue con yyyy-mm-dd puebla el texto y el grid del calendario', () => {
      component.writeValue('2026-09-04');

      expect(component.inputValue()).toContain('04/09/2026');
      expect(component.calendarDays().some((day) => day.selected && day.date.getDate() === 4)).toBe(true);
    });

    it('writeValue(null) limpia el valor', () => {
      component.writeValue('2026-09-04');
      component.writeValue(null);

      expect(component.inputValue()).toBe('');
      expect(component.hasSelectedDate()).toBe(false);
    });

    it('seleccionar un día del grid emite yyyy-mm-dd (mismo contrato del <input type="date"> que reemplaza)', () => {
      const onChange = vi.fn();
      component.registerOnChange(onChange);

      const day15 = component.calendarDays().find((day) => day.currentMonth && day.date.getDate() === 15);
      component.selectDate(day15!);

      expect(onChange).toHaveBeenCalledWith(expect.stringMatching(/^\d{4}-\d{2}-\d{2}$/));
    });

    it('no permite seleccionar un día fuera de minDate/maxDate', () => {
      component.writeValue('2026-09-04');
      const onChange = vi.fn();
      component.registerOnChange(onChange);
      fixture.componentRef.setInput('minDate', new Date(2026, 8, 10));

      const outOfRange = component.calendarDays().find((day) => day.currentMonth && day.date.getDate() === 5);
      component.selectDate(outOfRange!);

      expect(onChange).not.toHaveBeenCalled();
    });
  });

  describe('navegación de mes/año', () => {
    it('previousMonth/nextMonth mueven el grid mostrado', () => {
      component.writeValue('2026-09-04'); // septiembre 2026 — 30 días

      component.nextMonth();
      expect(component.calendarDays().filter((day) => day.currentMonth)).toHaveLength(31); // octubre 2026

      component.previousMonth();
      component.previousMonth();
      expect(component.calendarDays().filter((day) => day.currentMonth)).toHaveLength(31); // agosto 2026 — confirma que retrocedió 2 meses desde octubre
    });
  });

  describe('modo con hora manual (allowManualTime)', () => {
    beforeEach(() => {
      fixture.componentRef.setInput('allowManualTime', true);
    });

    it('tipear una fecha+hora válida emite el nuevo valor', () => {
      const onChange = vi.fn();
      component.registerOnChange(onChange);

      component.onInputChange({ target: { value: '04/09/2026 07:40 AM' } } as unknown as Event);

      expect(onChange).toHaveBeenCalledWith(expect.stringContaining('2026-09-04'));
    });

    it('emite datetime completo (con hora), no solo la fecha', () => {
      const onChange = vi.fn();
      component.registerOnChange(onChange);

      component.onInputChange({ target: { value: '04/09/2026 07:40 AM' } } as unknown as Event);

      const emittedValue = onChange.mock.calls.at(-1)?.[0] as string;
      expect(emittedValue).not.toMatch(/^\d{4}-\d{2}-\d{2}$/);
      expect(new Date(emittedValue).getHours()).toBe(7);
    });

    it('texto inválido al perder foco revierte al último valor válido', () => {
      component.writeValue('2026-09-04');
      const validText = component.inputValue();

      component.onInputChange({ target: { value: 'texto que no es una fecha' } } as unknown as Event);
      component.onBlurInput();

      expect(component.inputValue()).toBe(validText);
    });
  });

  describe('selectToday', () => {
    it('respeta minDate/maxDate — no hace nada si hoy queda fuera de rango', () => {
      const onChange = vi.fn();
      component.registerOnChange(onChange);
      const farFuture = new Date();
      farFuture.setFullYear(farFuture.getFullYear() + 5);
      fixture.componentRef.setInput('minDate', farFuture);

      component.selectToday();

      expect(onChange).not.toHaveBeenCalled();
    });
  });
});
