import { ComponentFixture, TestBed } from '@angular/core/testing';

import { SaModal } from './sa-modal';

describe('SaModal · título con punto de color', () => {
  let fixture: ComponentFixture<SaModal>;
  const header = () => document.querySelector('.cdk-overlay-container .sa-modal-header-title') as HTMLElement | null;

  beforeEach(async () => {
    await TestBed.configureTestingModule({ imports: [SaModal] }).compileComponents();
    fixture = TestBed.createComponent(SaModal);
    fixture.componentRef.setInput('title', 'Etiqueta');
    fixture.componentRef.setInput('visible', true);
    fixture.detectChanges();
    fixture.detectChanges();
  });

  it('con titleDotColor pinta el punto y no el ícono', () => {
    fixture.componentRef.setInput('titleIcon', 'User');
    fixture.componentRef.setInput('titleDotColor', '#ef4444');
    fixture.detectChanges();

    const dot = header()?.querySelector('.sa-modal-title-dot') as HTMLElement | null;
    expect(dot).toBeTruthy();
    expect(dot?.style.background).toContain('rgb(239, 68, 68)');
    expect(header()?.querySelector('sa-icon')).toBeNull();
  });

  it('sin titleDotColor sigue mostrando el ícono del título', () => {
    fixture.componentRef.setInput('titleIcon', 'User');
    fixture.detectChanges();

    expect(header()?.querySelector('.sa-modal-title-dot')).toBeNull();
    expect(header()?.querySelector('sa-icon')).toBeTruthy();
  });

  it('el encabezado aparece con solo un punto de color, sin título ni ícono', () => {
    fixture.componentRef.setInput('title', '');
    fixture.componentRef.setInput('titleDotColor', '#10b981');
    fixture.detectChanges();

    expect(header()?.querySelector('.sa-modal-title-dot')).toBeTruthy();
  });
});
