import { ComponentFixture, TestBed } from '@angular/core/testing';

import { AsModal } from './as-modal';

describe('AsModal · contenido sin relleno (flush)', () => {
  let fixture: ComponentFixture<AsModal>;
  const panel = () => document.querySelector('.cdk-overlay-container .as-modal') as HTMLElement;

  beforeEach(async () => {
    await TestBed.configureTestingModule({ imports: [AsModal] }).compileComponents();
    fixture = TestBed.createComponent(AsModal);
    fixture.componentRef.setInput('title', 'Título');
    fixture.componentRef.setInput('visible', true);
    fixture.detectChanges();
    fixture.detectChanges();
  });

  it('por defecto el contenido lleva su relleno', () => {
    expect(panel().classList.contains('as-modal--flush')).toBe(false);
  });

  it('con flush el panel lo marca para que el contenido maneje su propio espaciado', () => {
    fixture.componentRef.setInput('flush', true);
    fixture.detectChanges();

    expect(panel().classList.contains('as-modal--flush')).toBe(true);
    expect(panel().classList.contains('as-modal')).toBe(true);
  });
});
