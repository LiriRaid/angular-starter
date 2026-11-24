import { ComponentFixture, TestBed } from '@angular/core/testing';
import { beforeEach, describe, expect, it, vi } from 'vitest';

import { AsSelectableItem } from './as-selectable-item';

describe('AsSelectableItem', () => {
  let fixture: ComponentFixture<AsSelectableItem>;

  const button = () => fixture.nativeElement.querySelector('button') as HTMLButtonElement;

  beforeEach(() => {
    fixture = TestBed.createComponent(AsSelectableItem);
    fixture.componentRef.setInput('title', 'Conexión principal');
  });

  it('muestra el título y, solo si viene, el subtítulo', () => {
    fixture.detectChanges();
    expect(button().textContent).toContain('Conexión principal');
    expect(fixture.nativeElement.querySelectorAll('span.truncate')).toHaveLength(1);

    fixture.componentRef.setInput('subtitle', '+504 9999 0000');
    fixture.detectChanges();
    expect(button().textContent).toContain('+504 9999 0000');
  });

  it('anuncia si está elegida con aria-pressed y solo entonces muestra el check', () => {
    fixture.detectChanges();
    expect(button().getAttribute('aria-pressed')).toBe('false');
    expect(fixture.nativeElement.querySelector('as-icon')).toBeNull();

    fixture.componentRef.setInput('selected', true);
    fixture.detectChanges();
    expect(button().getAttribute('aria-pressed')).toBe('true');
    expect(fixture.nativeElement.querySelector('as-icon')).not.toBeNull();
  });

  it('el color de acento solo tiñe el borde cuando está elegida', () => {
    fixture.componentRef.setInput('accentColor', '#25d366');
    fixture.detectChanges();
    expect(button().style.borderColor).not.toBe('rgb(37, 211, 102)');

    fixture.componentRef.setInput('selected', true);
    fixture.detectChanges();
    expect(button().style.borderColor).toBe('rgb(37, 211, 102)');
  });

  it('atenuada baja la opacidad y emite itemClick al pulsarla', () => {
    const clicked = vi.fn();
    fixture.componentInstance.itemClick.subscribe(clicked);
    fixture.componentRef.setInput('dimmed', true);
    fixture.detectChanges();

    expect(button().classList.contains('opacity-60')).toBe(true);

    button().click();
    expect(clicked).toHaveBeenCalledTimes(1);
  });
});
