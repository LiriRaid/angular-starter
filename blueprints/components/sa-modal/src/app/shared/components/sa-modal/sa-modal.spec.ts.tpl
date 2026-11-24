import { ComponentFixture, TestBed } from '@angular/core/testing';

import { AsModal } from './as-modal';

describe('AsModal', () => {
  let fixture: ComponentFixture<AsModal>;
  let component: AsModal;

  beforeEach(async () => {
    TestBed.overrideComponent(AsModal, {
      set: {
        imports: [],
        template: '',
      },
    });

    await TestBed.configureTestingModule({
      imports: [AsModal],
    }).compileComponents();

    fixture = TestBed.createComponent(AsModal);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('creates the component', () => {
    expect(component).toBeTruthy();
  });

  it('starts hidden by default', () => {
    expect(component.visible()).toBe(false);
  });

  it('sets visible to false and emits hide when close is called', () => {
    component.visible.set(true);
    const emitSpy = vi.spyOn(component.hide, 'emit');

    component.close();

    expect(component.visible()).toBe(false);
    expect(emitSpy).toHaveBeenCalled();
  });

  it('defaults to the "default" variant', () => {
    expect(component.variant()).toBe('default');
  });

  it('reflects the visible model when set externally', () => {
    fixture.componentRef.setInput('title', 'Detalle');
    component.visible.set(true);

    expect(component.visible()).toBe(true);
    expect(component.title()).toBe('Detalle');
  });

  it('onBackdropClick does not close when closable is false', () => {
    fixture.componentRef.setInput('closable', false);
    fixture.detectChanges();
    component.visible.set(true);

    component.onBackdropClick();

    expect(component.visible()).toBe(true);
  });

  it('onBackdropClick does not close when dismissableMask is false', () => {
    fixture.componentRef.setInput('dismissableMask', false);
    fixture.detectChanges();
    component.visible.set(true);

    component.onBackdropClick();

    expect(component.visible()).toBe(true);
  });

  it('onBackdropClick closes when closable and dismissableMask are true', () => {
    component.visible.set(true);
    const closeSpy = vi.spyOn(component, 'close');

    component.onBackdropClick();

    expect(closeSpy).toHaveBeenCalled();
  });

  it('hostClasses includes the preview modifier and consumer styleClass', () => {
    fixture.componentRef.setInput('variant', 'preview');
    fixture.componentRef.setInput('styleClass', 'admin-host');
    fixture.detectChanges();

    expect(component.hostClasses()).toBe('as-modal as-modal--preview admin-host');
  });
});
