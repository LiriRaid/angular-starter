import { TestBed } from '@angular/core/testing';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import { AlertService } from './alert.service';

describe('AlertService', () => {
  let service: AlertService;

  beforeEach(() => {
    vi.useFakeTimers();
    TestBed.configureTestingModule({});
    service = TestBed.inject(AlertService);
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('encola los mensajes mostrados antes de markToastReady() sin commitearlos', () => {
    service.showSuccess('Título', 'Mensaje');

    expect(service.messages()).toEqual([]);
    expect(service.toastActive()).toBe(true);

    service.markToastReady();

    expect(service.messages()).toHaveLength(1);
    expect(service.messages()[0].title).toBe('Título');
  });

  it('commitea inmediatamente los mensajes mostrados después de markToastReady()', () => {
    service.markToastReady();

    service.showError('Error', 'Algo falló');

    expect(service.messages()).toHaveLength(1);
    expect(service.messages()[0].message).toBe('Algo falló');
  });

  it('los mensajes nuevos se insertan al inicio de la lista', () => {
    service.markToastReady();

    service.showInfo('Primero', 'a');
    service.showInfo('Segundo', 'b');

    expect(service.messages().map((m) => m.title)).toEqual(['Segundo', 'Primero']);
  });

  it('asigna la duración por defecto según el tipo de toast', () => {
    service.markToastReady();

    service.showError('Error', 'x');
    service.showWarning('Warning', 'x');
    service.showSuccess('Success', 'x');

    const [warn, error] = [service.messages()[1], service.messages()[2]];
    expect(error.duration).toBe(6000);
    expect(warn.duration).toBe(5000);
    expect(service.messages()[0].duration).toBe(4000);
  });

  it('se auto-elimina tras vencer su duración', () => {
    service.markToastReady();
    service.showSuccess('Título', 'Mensaje', undefined, 1000);

    const id = service.messages()[0].id;
    vi.advanceTimersByTime(1000);
    expect(service.leavingIds().has(id)).toBe(true);

    vi.advanceTimersByTime(450);
    expect(service.messages()).toEqual([]);
    expect(service.leavingIds().has(id)).toBe(false);
  });

  it('un toast persistente (showWarning con persistent=true) no se auto-elimina', () => {
    service.markToastReady();
    service.showWarning('Título', 'Mensaje', undefined, undefined, true);

    vi.advanceTimersByTime(60_000);

    expect(service.messages()).toHaveLength(1);
  });

  it('removeMessage marca el id como "leaving" y lo remueve tras la transición de salida', () => {
    service.markToastReady();
    service.showInfo('Título', 'Mensaje', undefined, 100_000);

    const id = service.messages()[0].id;
    service.removeMessage(id);

    expect(service.leavingIds().has(id)).toBe(true);
    expect(service.messages()).toHaveLength(1);

    vi.advanceTimersByTime(450);

    expect(service.messages()).toEqual([]);
    expect(service.leavingIds().has(id)).toBe(false);
  });

  it('toastActive vuelve a false 300ms después de que se vacía la lista de mensajes', () => {
    service.markToastReady();
    service.showInfo('Título', 'Mensaje', undefined, 100);

    expect(service.toastActive()).toBe(true);

    vi.advanceTimersByTime(100 + 450);
    expect(service.messages()).toEqual([]);
    expect(service.toastActive()).toBe(true);

    vi.advanceTimersByTime(300);
    expect(service.toastActive()).toBe(false);
  });

  it('clear() vacía los mensajes y cancela los timers de auto-eliminación pendientes', () => {
    service.markToastReady();
    service.showInfo('Título', 'Mensaje', undefined, 5000);

    service.clear();

    expect(service.messages()).toEqual([]);

    vi.advanceTimersByTime(5000);
    expect(service.messages()).toEqual([]);
  });

  it('mostrar un nuevo toast cancela el destroyTimer pendiente y mantiene toastActive en true', () => {
    service.markToastReady();
    service.showInfo('Uno', 'a', undefined, 100);

    vi.advanceTimersByTime(100 + 450);
    expect(service.toastActive()).toBe(true);

    service.showInfo('Dos', 'b', undefined, 5000);
    vi.advanceTimersByTime(300);

    expect(service.toastActive()).toBe(true);
  });
});
