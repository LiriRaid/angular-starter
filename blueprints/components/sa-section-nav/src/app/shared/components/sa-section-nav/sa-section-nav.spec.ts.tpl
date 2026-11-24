import { Component, signal } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { beforeEach, describe, expect, it } from 'vitest';

import { AsSectionNav, type AsSectionNavItem } from './as-section-nav';

const ITEMS: readonly AsSectionNavItem[] = [
  { id: 'metas', icon: 'Globe', title: 'Metas', summary: 'se dibujan como meta' },
  { id: 'cobertura', icon: 'Clock', title: 'Horario de cobertura', summary: 'fuera del horario se excluye' },
  { id: 'privacidad', icon: 'Lock', title: 'Privacidad' },
];

@Component({
  imports: [AsSectionNav],
  template: `
    <as-section-nav title="Métricas y Papers" description="Metas y alertas." [items]="items()" [(active)]="active">
      <a sectionNavAction href="/metrics">Ir al módulo</a>
      <p class="body">cuerpo de {{ active() }}</p>
      <button sectionNavFooter type="button">Guardar</button>
    </as-section-nav>
  `,
})
class Host {
  readonly items = signal<readonly AsSectionNavItem[]>(ITEMS);
  readonly active = signal('metas');
}

describe('AsSectionNav', () => {
  let fixture: ComponentFixture<Host>;

  const root = () => fixture.nativeElement as HTMLElement;
  const buttons = () => [...root().querySelectorAll<HTMLButtonElement>('nav button')];

  beforeEach(() => {
    fixture = TestBed.createComponent(Host);
    fixture.detectChanges();
  });

  it('lista un botón por sección con su ícono, su nombre y su número en el orden dado', () => {
    expect(buttons().map((button) => button.querySelector('.truncate')?.textContent?.trim())).toEqual(['Metas', 'Horario de cobertura', 'Privacidad']);
    expect(buttons().map((button) => button.querySelector('[data-section-number]')?.textContent?.trim())).toEqual(['1', '2', '3']);
    expect(buttons().every((button) => button.querySelector('as-icon') !== null)).toBe(true);
    expect(root().querySelector('nav')?.getAttribute('aria-label')).toBe('Métricas y Papers');
    expect(root().textContent).toContain('Metas y alertas.');
    expect(root().querySelector('a[href="/metrics"]')?.textContent).toContain('Ir al módulo');
  });

  it('marca solo la sección activa y muestra su título y resumen sobre el contenido', () => {
    expect(buttons().map((button) => button.getAttribute('aria-current'))).toEqual(['true', null, null]);
    expect(root().querySelector('h2')?.textContent).toContain('Metas');
    expect(root().textContent).toContain('se dibujan como meta');
    expect(root().querySelector('.body')?.textContent).toBe('cuerpo de metas');
  });

  it('al elegir otra sección cambia `active`, el título y el contenido', () => {
    buttons()[1].click();
    fixture.detectChanges();

    expect(fixture.componentInstance.active()).toBe('cobertura');
    expect(buttons().map((button) => button.getAttribute('aria-current'))).toEqual([null, 'true', null]);
    expect(root().querySelector('h2')?.textContent).toContain('Horario de cobertura');
    expect(root().querySelector('.body')?.textContent).toBe('cuerpo de cobertura');
  });

  it('una sección sin resumen no dibuja la pista, y el pie va después del contenido', () => {
    buttons()[2].click();
    fixture.detectChanges();

    expect(root().querySelector('[data-section-hint]')).toBeNull();
    const body = root().querySelector('.body')!;
    const footer = root().querySelector('[sectionNavFooter]')!;
    expect(body.compareDocumentPosition(footer) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy();
  });

  it('con la lista vacía (datos que aún no llegan) no falla y no dibuja botones ni título', () => {
    fixture.componentInstance.items.set([]);
    expect(() => fixture.detectChanges()).not.toThrow();

    expect(buttons()).toHaveLength(0);
    expect(root().querySelector('h2')).toBeNull();
  });

  it('con una sección activa que no existe cae a la primera en vez de romper', () => {
    fixture.componentInstance.active.set('inexistente');
    fixture.detectChanges();

    expect(root().querySelector('h2')?.textContent).toContain('Metas');
    expect(buttons().map((button) => button.getAttribute('aria-current'))).toEqual(['true', null, null]);
  });
});
