import { TestBed, type ComponentFixture } from '@angular/core/testing';
import { beforeEach, describe, expect, it } from 'vitest';

import { AsTextarea } from './as-textarea';

describe('AsTextarea · label en reposo', () => {
  let fixture: ComponentFixture<AsTextarea>;
  const label = (): HTMLLabelElement => fixture.nativeElement.querySelector('label');

  beforeEach(async () => {
    await TestBed.configureTestingModule({ imports: [AsTextarea] }).compileComponents();
    fixture = TestBed.createComponent(AsTextarea);
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
