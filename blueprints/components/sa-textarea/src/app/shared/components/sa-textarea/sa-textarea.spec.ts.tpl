import { TestBed, type ComponentFixture } from '@angular/core/testing';
import { beforeEach, describe, expect, it } from 'vitest';

import { SaTextarea } from './sa-textarea';

describe('SaTextarea · label en reposo', () => {
  let fixture: ComponentFixture<SaTextarea>;
  const label = (): HTMLLabelElement => fixture.nativeElement.querySelector('label');

  beforeEach(async () => {
    await TestBed.configureTestingModule({ imports: [SaTextarea] }).compileComponents();
    fixture = TestBed.createComponent(SaTextarea);
    fixture.componentRef.setInput('label', 'Mensaje');
  });

  it('con una sola fila el label vacío se centra verticalmente, como en un input', () => {
    fixture.componentRef.setInput('rows', 1);
    fixture.detectChanges();

    expect(label().classList.contains('top-1/2')).toBe(true);
    expect(label().classList.contains('-translate-y-1/2')).toBe(true);
  });

  it('con varias filas el label vacío queda arriba, junto a la primera línea, y no flotando en el centro del campo', () => {
    fixture.componentRef.setInput('rows', 4);
    fixture.detectChanges();

    expect(label().classList.contains('top-1/2')).toBe(false);
    expect(label().classList.contains('-translate-y-1/2')).toBe(false);
    expect(label().classList.contains('top-3')).toBe(true);
  });

  it('al escribir, el label flota igual que en las demás variantes (no se toca el estado flotante)', () => {
    fixture.componentRef.setInput('rows', 4);
    fixture.componentRef.setInput('value', 'Hola');
    fixture.detectChanges();
    const textarea: HTMLTextAreaElement = fixture.nativeElement.querySelector('textarea');
    textarea.value = 'Hola';
    textarea.dispatchEvent(new Event('input'));
    fixture.detectChanges();

    expect(label().classList.contains('text-caption-2-bold')).toBe(true);
    expect(label().classList.contains('top-3')).toBe(false);
  });
});

describe('SaTextarea · espacio del label y de los iconos', () => {
  let fixture: ComponentFixture<SaTextarea>;
  const field = (): HTMLTextAreaElement => fixture.nativeElement.querySelector('textarea');
  const label = (): HTMLLabelElement => fixture.nativeElement.querySelector('label');

  beforeEach(async () => {
    await TestBed.configureTestingModule({ imports: [SaTextarea] }).compileComponents();
    fixture = TestBed.createComponent(SaTextarea);
    fixture.componentRef.setInput('label', 'Comentario');
  });

  it('en `in` el texto empieza bajo el label, también con readonlyInput y un valor', () => {
    fixture.componentRef.setInput('variant', 'in');
    fixture.componentRef.setInput('readonlyInput', true);
    fixture.componentRef.setInput('value', 'Solo lectura');
    fixture.detectChanges();

    expect(field().style.paddingTop).toBe('1.5rem');
  });

  it('en `on` y `over` el texto conserva su relleno de siempre', () => {
    for (const variant of ['on', 'over'] as const) {
      fixture.componentRef.setInput('variant', variant);
      fixture.detectChanges();
      expect(field().style.paddingTop).toBe('0.625rem');
    }
  });

  it('un icono a la izquierda empuja el texto y uno a la derecha le deja su lado', () => {
    fixture.componentRef.setInput('lucideIcon', 'Search');
    fixture.detectChanges();
    expect(field().style.paddingLeft).toBe('2.5rem');

    fixture.componentRef.setInput('iconPosition', 'right');
    fixture.detectChanges();
    expect(field().style.paddingLeft).toBe('1rem');
    expect(field().style.paddingRight).toBe('2.5rem');
  });

  it('el icono se alinea con la primera línea: bajo el label en `in`, arriba en el resto', () => {
    fixture.componentRef.setInput('lucideIcon', 'Search');
    fixture.componentRef.setInput('variant', 'in');
    fixture.detectChanges();
    const icon = (): HTMLElement => fixture.nativeElement.querySelector('sa-icon');
    expect(icon().style.top).toBe('1.625rem');

    fixture.componentRef.setInput('variant', 'on');
    fixture.detectChanges();
    expect(icon().style.top).toBe('0.75rem');
  });

  it('el fondo del label se redondea arriba y abajo, como el de los demás campos', () => {
    for (const variant of ['on', 'in', 'over'] as const) {
      fixture.componentRef.setInput('variant', variant);
      fixture.detectChanges();
      expect(label().classList.contains('rounded-md')).toBe(true);
      expect(label().classList.contains('rounded-bl-none')).toBe(false);
    }
  });
});
