import { ComponentFixture, TestBed } from '@angular/core/testing';
import { describe, expect, it, vi, beforeEach } from 'vitest';
import { Component, ComponentRef, signal } from '@angular/core';
import { AsDrawer } from './as-drawer';

describe('AsDrawer', () => {
  let fixture: ComponentFixture<AsDrawer>;
  let component: AsDrawer;
  let ref: ComponentRef<AsDrawer>;

  beforeEach(async () => {
    TestBed.overrideComponent(AsDrawer, { set: { imports: [], template: '' } });

    await TestBed.configureTestingModule({
      imports: [AsDrawer],
    }).compileComponents();

    fixture = TestBed.createComponent(AsDrawer);
    component = fixture.componentInstance;
    ref = fixture.componentRef;
    fixture.detectChanges();
  });

  it('creates the component with sensible defaults', () => {
    expect(component).toBeTruthy();
    expect(component.visible()).toBe(false);
    expect(component.position()).toBe('left');
    expect(component.dismissible()).toBe(true);
    expect(component.closeOnEscape()).toBe(true);
    expect(component.closable()).toBe(true);
  });

  it('onDialogClose sets visible to false and emits onHide', () => {
    ref.setInput('visible', true);
    fixture.detectChanges();

    const spy = vi.spyOn(component.onHide, 'emit');
    component.onDialogClose();

    expect(component.visible()).toBe(false);
    expect(spy).toHaveBeenCalled();
  });

  it('closes on Escape when closeOnEscape is true', () => {
    const spy = vi.spyOn(component, 'close');
    (component as unknown as { onDocumentKeydown: (event: KeyboardEvent) => void }).onDocumentKeydown(new KeyboardEvent('keydown', { key: 'Escape' }));

    expect(spy).toHaveBeenCalled();
  });

  it('does not close on Escape when closeOnEscape is false', () => {
    ref.setInput('closeOnEscape', false);
    fixture.detectChanges();

    const spy = vi.spyOn(component, 'close');
    (component as unknown as { onDocumentKeydown: (event: KeyboardEvent) => void }).onDocumentKeydown(new KeyboardEvent('keydown', { key: 'Escape' }));

    expect(spy).not.toHaveBeenCalled();
  });
});

@Component({
  selector: 'as-drawer-spec-host',
  imports: [AsDrawer],
  template: `
    <as-drawer [visible]="true" position="right" [ariaLabel]="label()" [width]="width()" [density]="density()" [flush]="flush()" [closeIcon]="closeIcon()" [closeLabel]="closeLabel()" styleClass="host-class">
      <h2 drawer-header class="header-title">Título</h2>
      <p class="body">Contenido</p>
      @if (withFooter()) {
        <div drawer-footer class="footer-action">Guardar</div>
      }
    </as-drawer>
  `,
})
class DrawerHost {
  readonly label = signal<string | null>('Filtros avanzados');
  readonly width = signal<string | null>('30rem');
  readonly withFooter = signal(true);
  readonly density = signal<'comfortable' | 'compact'>('comfortable');
  readonly flush = signal(false);
  readonly closeIcon = signal('X');
  readonly closeLabel = signal('Cerrar');
}

describe('AsDrawer · template', () => {
  let fixture: ComponentFixture<DrawerHost>;
  /** El panel se monta en el contenedor de overlays (hijo de <body>), no dentro del host. */
  const dialog = () => document.querySelector('.cdk-overlay-container dialog') as HTMLDialogElement;

  beforeEach(async () => {
    // jsdom no implementa `<dialog>.show()`: el drawer lo llama en un rAF al abrirse.
    HTMLDialogElement.prototype.show ??= function (this: HTMLDialogElement) {
      this.setAttribute('open', '');
    };
    HTMLDialogElement.prototype.close ??= function (this: HTMLDialogElement) {
      this.removeAttribute('open');
    };

    await TestBed.configureTestingModule({ imports: [DrawerHost] }).compileComponents();
    fixture = TestBed.createComponent(DrawerHost);
    fixture.detectChanges();
  });

  it('el diálogo tiene nombre accesible cuando el consumidor lo pasa', () => {
    expect(dialog().getAttribute('aria-label')).toBe('Filtros avanzados');

    fixture.componentInstance.label.set(null);
    fixture.detectChanges();
    expect(dialog().hasAttribute('aria-label')).toBe(false);
  });

  it('el ancho se pasa por la variable --as-drawer-width', () => {
    expect(dialog().style.getPropertyValue('--as-drawer-width')).toBe('30rem');

    fixture.componentInstance.width.set(null);
    fixture.detectChanges();
    expect(dialog().style.getPropertyValue('--as-drawer-width')).toBe('');
  });

  it('el contenido con [drawer-footer] va al pie, fuera del área con scroll', () => {
    const footer = dialog().querySelector('.as-drawer-footer');
    expect(footer?.querySelector('.footer-action')?.textContent).toContain('Guardar');
    expect(
      dialog()
        .querySelector('.as-drawer-content')
        ?.contains(footer as Node),
    ).toBe(false);
  });

  it('sin contenido de pie, el pie queda vacío para que el CSS lo oculte (:empty)', () => {
    fixture.componentInstance.withFooter.set(false);
    fixture.detectChanges();

    const footer = dialog().querySelector('.as-drawer-footer') as HTMLElement;
    expect(footer.childElementCount).toBe(0);
    expect(footer.textContent?.trim()).toBe('');
  });

  it('se monta sobre toda la página: en el contenedor de overlays y no dentro del host', () => {
    expect(dialog()).toBeTruthy();
    expect(fixture.nativeElement.contains(dialog())).toBe(false);
    expect(document.querySelector('.cdk-overlay-container .as-drawer-backdrop')).toBeTruthy();
  });

  it('cabecera, contenido y pie van en ese orden, cada uno en su zona', () => {
    const zones = Array.from(dialog().children).map((el) => el.className);
    expect(zones).toEqual(['as-drawer-header', 'as-drawer-content', 'as-drawer-footer']);
    expect(dialog().querySelector('.as-drawer-header .header-title')?.textContent).toContain('Título');
    expect(dialog().querySelector('.as-drawer-content .body')?.textContent).toContain('Contenido');
  });

  it('el botón de cerrar va en la cabecera con el nombre accesible y el ícono pedidos', () => {
    const button = dialog().querySelector('.as-drawer-header .as-drawer-close-button') as HTMLButtonElement;
    expect(button.getAttribute('aria-label')).toBe('Cerrar');
    expect(button.querySelector('svg.lucide-x')).toBeTruthy();

    fixture.componentInstance.closeLabel.set('Volver');
    fixture.componentInstance.closeIcon.set('ChevronRight');
    fixture.detectChanges();
    expect(button.getAttribute('aria-label')).toBe('Volver');
    expect(button.querySelector('svg.lucide-chevron-right')).toBeTruthy();
  });

  it('density y flush se reflejan como clases del panel, junto con styleClass', () => {
    expect(dialog().classList.contains('as-drawer--compact')).toBe(false);
    expect(dialog().classList.contains('as-drawer--flush')).toBe(false);
    expect(dialog().classList.contains('host-class')).toBe(true);

    fixture.componentInstance.density.set('compact');
    fixture.componentInstance.flush.set(true);
    fixture.detectChanges();
    expect(dialog().classList.contains('as-drawer--compact')).toBe(true);
    expect(dialog().classList.contains('as-drawer--flush')).toBe(true);
    expect(dialog().classList.contains('as-drawer-right')).toBe(true);
  });
});
