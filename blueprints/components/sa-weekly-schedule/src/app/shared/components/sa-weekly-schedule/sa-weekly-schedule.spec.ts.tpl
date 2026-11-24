import { ComponentFixture, TestBed } from '@angular/core/testing';
import { beforeEach, describe, expect, it } from 'vitest';

import { AsWeeklySchedule, computeWeeklyHours, parseSchedule } from './as-weekly-schedule';

describe('AsWeeklySchedule', () => {
  let fixture: ComponentFixture<AsWeeklySchedule>;
  let component: AsWeeklySchedule;

  beforeEach(async () => {
    await TestBed.configureTestingModule({ imports: [AsWeeklySchedule] }).compileComponents();

    fixture = TestBed.createComponent(AsWeeklySchedule);
    component = fixture.componentInstance;
    fixture.detectChanges();
    // El default (Lun-Vie 8:00-17:00) se siembra hacia `value` con un effect propio: hay que dejarlo asentar antes de leer el estado inicial.
    await fixture.whenStable();
  });

  it('por defecto activa Lun-Vie 08:00-17:00 y lo refleja en value', () => {
    expect(component.summary()).toBe('Lun-Vie 8:00-17:00');
    expect(component.weeklyHours()).toBe(45);
    expect(component.value()).toBe('Lun-Vie 8:00-17:00');
  });

  it('applyPreset "all-9-23" activa los 7 días', () => {
    component.applyPreset('all-9-23');
    expect(component.summary()).toBe('Todos los días 9:00-23:00');
    expect(component.value()).toBe('Todos los días 9:00-23:00');
  });

  it('applyPreset "24h" reporta 168 horas semanales', () => {
    component.applyPreset('24h');
    expect(component.summary()).toBe('Todos los días 24 horas');
    expect(component.weeklyHours()).toBe(168);
  });

  it('toggleDay desactiva un día y lo excluye del resumen', () => {
    component.toggleDay(4); // Viernes
    expect(component.days()[4].enabled).toBe(false);
    expect(component.summary()).toBe('Lun-Jue 8:00-17:00');
  });

  it('con todos los días cerrados el resumen lo dice', () => {
    for (let index = 0; index < 5; index++) component.toggleDay(index);

    expect(component.summary()).toBe('Cerrado toda la semana');
    expect(component.weeklyHours()).toBe(0);
  });

  it('copyDay replica el horario del día a los demás días activos', () => {
    component.updateTime(0, 'start', '09:00');
    component.updateTime(0, 'end', '18:00');
    component.copyDay(0);
    expect(component.summary()).toBe('Lun-Vie 9:00-18:00');
  });

  it('reparsea un valor externo real (ej. cargado de una entidad guardada)', async () => {
    fixture.componentRef.setInput('value', 'Lun-Vie 7:00-18:00 · Sáb 8:00-13:00');
    fixture.detectChanges();
    await fixture.whenStable();

    expect(component.summary()).toBe('Lun-Vie 7:00-18:00 · Sáb 8:00-13:00');
    expect(component.days()[5].enabled).toBe(true); // Sábado
    expect(component.days()[5].start).toBe('08:00');
    expect(component.days()[6].enabled).toBe(false); // Domingo sigue cerrado
  });

  it('resetea al default cuando el valor externo pasa de uno real a vacío (reuso sin destruir, ej. un modal que edita distintos registros)', async () => {
    fixture.componentRef.setInput('value', 'Lun-Vie 9:00-18:00');
    fixture.detectChanges();
    await fixture.whenStable();
    expect(component.summary()).toBe('Lun-Vie 9:00-18:00');

    fixture.componentRef.setInput('value', '');
    fixture.detectChanges();
    await fixture.whenStable();

    // El horario del registro anterior no debe "filtrarse" hacia el nuevo.
    expect(component.summary()).toBe('Lun-Vie 8:00-17:00');
    expect(component.value()).toBe('Lun-Vie 8:00-17:00');
  });

  it('borrar la hora de un campo no cambia el horario: se conserva la anterior', () => {
    component.updateTime(0, 'start', '');
    component.updateTime(0, 'end', 'abc');

    expect(component.days()[0].start).toBe('08:00');
    expect(component.days()[0].end).toBe('17:00');
    expect(component.summary()).toBe('Lun-Vie 8:00-17:00');
    expect(component.weeklyHours()).toBe(45);
    expect(component.value()).toBe('Lun-Vie 8:00-17:00');
  });

  it('al borrar la hora en el campo, este vuelve a mostrar la hora que sigue vigente', () => {
    const [start] = fixture.nativeElement.querySelectorAll('input[type="time"]') as NodeListOf<HTMLInputElement>;

    start.value = '';
    start.dispatchEvent(new Event('change'));

    expect(start.value).toBe('08:00');
    expect(component.summary()).toBe('Lun-Vie 8:00-17:00');
  });

  it('cada interruptor de día tiene nombre accesible', () => {
    const toggles = [...fixture.nativeElement.querySelectorAll('as-toggle button')] as HTMLElement[];

    expect(toggles).toHaveLength(7);
    expect(toggles[0].getAttribute('aria-label')).toBe('Activar Lunes');
  });
});

describe('computeWeeklyHours / parseSchedule', () => {
  it('un horario que cruza la medianoche cuenta las horas hasta el día siguiente', () => {
    const days = parseSchedule('Lun 22:00-06:00');

    expect(computeWeeklyHours(days)).toBe(8);
  });

  it('una hora mal formada no produce NaN: el total ignora ese día', () => {
    const days = parseSchedule('Lun 08:00-17:00');
    days[0].end = '';

    expect(Number.isNaN(computeWeeklyHours(days))).toBe(false);
    expect(computeWeeklyHours(days)).toBe(0);
  });

  it('un valor vacío deja todos los días cerrados', () => {
    expect(parseSchedule('').every((day) => !day.enabled)).toBe(true);
  });
});
