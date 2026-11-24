import { ComponentFixture, TestBed } from '@angular/core/testing';

import { AsModal } from './as-modal';

describe('AsModal · arrastre', () => {
  let fixture: ComponentFixture<AsModal>;
  const panel = () => document.querySelector('.cdk-overlay-container .as-modal') as HTMLElement;
  const header = () => panel().querySelector('.as-modal-header') as HTMLElement;
  const press = (target: HTMLElement) => target.dispatchEvent(new MouseEvent('mousedown', { bubbles: true, clientX: 10, clientY: 10 }));

  beforeEach(async () => {
    await TestBed.configureTestingModule({ imports: [AsModal] }).compileComponents();
    fixture = TestBed.createComponent(AsModal);
    fixture.componentRef.setInput('title', 'Título');
    fixture.componentRef.setInput('visible', true);
    fixture.detectChanges();
    fixture.detectChanges();
  });

  afterEach(() => {
    document.dispatchEvent(new MouseEvent('mouseup'));
  });

  it('por defecto se arrastra desde el encabezado, como siempre', () => {
    expect(fixture.componentInstance.draggable()).toBe(true);

    press(header());

    expect(panel().style.position).toBe('fixed');
  });

  it('con draggable apagado el encabezado no mueve el panel y este conserva su centrado', () => {
    fixture.componentRef.setInput('draggable', false);
    fixture.detectChanges();

    press(header());

    expect(panel().style.position).toBe('');
    expect(panel().style.margin).toBe('');
    expect(panel().classList.contains('as-modal--fixed')).toBe(true);
  });

  it('con draggable apagado el botón de cerrar y el resize siguen funcionando', () => {
    fixture.componentRef.setInput('draggable', false);
    fixture.detectChanges();

    expect(panel().querySelector('.as-modal-resize-handle')).not.toBeNull();
    expect(header().querySelector('as-button')).not.toBeNull();
  });
});
