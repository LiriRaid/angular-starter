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
    <as-drawer [visible]="true" position="right" [ariaLabel]="label()" [width]="width()">
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
}

describe('AsDrawer · template', () => {
  let fixture: ComponentFixture<DrawerHost>;
  const dialog = () => fixture.nativeElement.querySelector('dialog') as HTMLDialogElement;

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
    expect(dialog().querySelector('.as-drawer-content')?.contains(footer as Node)).toBe(false);
  });

  it('sin contenido de pie, el pie queda vacío para que el CSS lo oculte (:empty)', () => {
    fixture.componentInstance.withFooter.set(false);
    fixture.detectChanges();

    const footer = dialog().querySelector('.as-drawer-footer') as HTMLElement;
    expect(footer.childElementCount).toBe(0);
    expect(footer.textContent?.trim()).toBe('');
  });
});
