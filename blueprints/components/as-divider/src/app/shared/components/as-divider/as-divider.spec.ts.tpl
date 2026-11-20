import { ComponentFixture, TestBed } from '@angular/core/testing';
import { describe, expect, it, beforeEach } from 'vitest';
import { ComponentRef } from '@angular/core';
import { AsDivider } from './as-divider';

describe('AsDivider', () => {
  let fixture: ComponentFixture<AsDivider>;
  let component: AsDivider;
  let ref: ComponentRef<AsDivider>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [AsDivider],
    }).compileComponents();

    fixture = TestBed.createComponent(AsDivider);
    component = fixture.componentInstance;
    ref = fixture.componentRef;
    fixture.detectChanges();
  });

  it('creates the component', () => {
    expect(component).toBeTruthy();
  });

  it('defaults to a horizontal solid divider aligned left', () => {
    expect(component.hostClasses()).toBe('as-divider as-divider-horizontal as-divider-solid as-divider-left');
  });

  it('reflects layout, type and align inputs in the host classes', () => {
    ref.setInput('layout', 'vertical');
    ref.setInput('type', 'dashed');
    ref.setInput('align', 'bottom');
    fixture.detectChanges();

    expect(component.hostClasses()).toBe('as-divider as-divider-vertical as-divider-dashed as-divider-bottom');
  });

  it('exposes aria-orientation matching the layout', () => {
    ref.setInput('layout', 'vertical');
    fixture.detectChanges();

    expect(fixture.nativeElement.getAttribute('aria-orientation')).toBe('vertical');
    expect(fixture.nativeElement.getAttribute('role')).toBe('separator');
  });
});
