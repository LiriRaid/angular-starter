import { Component } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { By } from '@angular/platform-browser';
import { beforeEach, describe, expect, it } from 'vitest';

import { SaTooltip, anchorRectOf } from './sa-tooltip.directive';

@Component({
  template: '<button saTooltip="Detalle">Ver detalle</button>',
  imports: [SaTooltip],
})
class TooltipHost {}

describe('SaTooltip', () => {
  let fixture: ComponentFixture<TooltipHost>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({ imports: [TooltipHost] }).compileComponents();
    fixture = TestBed.createComponent(TooltipHost);
    fixture.detectChanges();
  });

  it('habilita la directiva con una única importación', () => {
    const directive = fixture.debugElement.query(By.directive(SaTooltip)).injector.get(SaTooltip);

    expect(directive.content()).toBe('Detalle');
  });

  it('renderiza el panel desde su template HTML', async () => {
    const button = fixture.nativeElement.querySelector('button') as HTMLButtonElement;
    button.dispatchEvent(new Event('mouseenter'));
    await new Promise((resolve) => setTimeout(resolve));

    expect(document.querySelector<HTMLElement>('[role="tooltip"]')?.textContent).toContain('Detalle');

    button.dispatchEvent(new Event('mouseleave'));
    expect(document.querySelector('[role="tooltip"]')).toBeNull();
  });
});

describe('anchorRectOf', () => {
  const rect = (top: number, bottom: number, left = 0, right = 80): DOMRect => ({ top, bottom, left, right, width: right - left, height: bottom - top, x: left, y: top, toJSON: () => ({}) }) as DOMRect;

  it('un host en línea (un componente como el botón) se ancla a lo que pinta dentro, no a su línea de texto', () => {
    const host = document.createElement('span');
    const inner = document.createElement('button');
    host.appendChild(inner);
    document.body.appendChild(host);
    vi.spyOn(host, 'getBoundingClientRect').mockReturnValue(rect(100, 118));
    vi.spyOn(inner, 'getBoundingClientRect').mockReturnValue(rect(90, 128));

    const anchor = anchorRectOf(host);

    expect(anchor.top).toBe(90);
    expect(anchor.bottom).toBe(128);
    expect(anchor.height).toBe(38);
    host.remove();
  });

  it('un elemento en línea sin hijos (el texto del botón) se ancla a su propio texto', () => {
    const host = document.createElement('span');
    document.body.appendChild(host);
    vi.spyOn(host, 'getBoundingClientRect').mockReturnValue(rect(100, 118));

    expect(anchorRectOf(host).top).toBe(100);
    expect(anchorRectOf(host).bottom).toBe(118);
    host.remove();
  });

  it('un hijo oculto (sin caja) no arrastra el ancla hacia la esquina de la página', () => {
    const host = document.createElement('span');
    const hidden = document.createElement('span');
    host.appendChild(hidden);
    document.body.appendChild(host);
    vi.spyOn(host, 'getBoundingClientRect').mockReturnValue(rect(100, 118, 40, 120));
    vi.spyOn(hidden, 'getBoundingClientRect').mockReturnValue(rect(0, 0, 0, 0));

    const anchor = anchorRectOf(host);

    expect(anchor.top).toBe(100);
    expect(anchor.left).toBe(40);
    host.remove();
  });

  it('un host que no es en línea conserva su propia caja', () => {
    const host = document.createElement('div');
    const inner = document.createElement('button');
    host.appendChild(inner);
    document.body.appendChild(host);
    vi.spyOn(host, 'getBoundingClientRect').mockReturnValue(rect(100, 140));
    vi.spyOn(inner, 'getBoundingClientRect').mockReturnValue(rect(90, 128));

    expect(anchorRectOf(host).top).toBe(100);
    expect(anchorRectOf(host).bottom).toBe(140);
    host.remove();
  });
});
