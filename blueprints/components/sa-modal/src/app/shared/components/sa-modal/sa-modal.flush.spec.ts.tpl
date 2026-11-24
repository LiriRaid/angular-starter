import { ComponentFixture, TestBed } from '@angular/core/testing';

import { SaModal } from './sa-modal';

describe('SaModal · contenido sin relleno (flush)', () => {
  let fixture: ComponentFixture<SaModal>;
  const panel = () => document.querySelector('.cdk-overlay-container .sa-modal') as HTMLElement;

  beforeEach(async () => {
    await TestBed.configureTestingModule({ imports: [SaModal] }).compileComponents();
    fixture = TestBed.createComponent(SaModal);
    fixture.componentRef.setInput('title', 'Título');
    fixture.componentRef.setInput('visible', true);
    fixture.detectChanges();
    fixture.detectChanges();
  });

  it('por defecto el contenido lleva su relleno', () => {
    expect(panel().classList.contains('sa-modal--flush')).toBe(false);
  });

  it('con flush el panel lo marca para que el contenido maneje su propio espaciado', () => {
    fixture.componentRef.setInput('flush', true);
    fixture.detectChanges();

    expect(panel().classList.contains('sa-modal--flush')).toBe(true);
    expect(panel().classList.contains('sa-modal')).toBe(true);
  });
});
