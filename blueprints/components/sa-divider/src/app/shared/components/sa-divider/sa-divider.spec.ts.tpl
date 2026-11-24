import { ComponentFixture, TestBed } from '@angular/core/testing';
import { describe, expect, it, beforeEach } from 'vitest';
import { ComponentRef } from '@angular/core';
import { SaDivider } from './sa-divider';

describe('SaDivider', () => {
  let fixture: ComponentFixture<SaDivider>;
  let component: SaDivider;
  let ref: ComponentRef<SaDivider>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [SaDivider],
    }).compileComponents();

    fixture = TestBed.createComponent(SaDivider);
    component = fixture.componentInstance;
    ref = fixture.componentRef;
    fixture.detectChanges();
  });

  it('creates the component', () => {
    expect(component).toBeTruthy();
  });

  it('defaults to a horizontal solid divider aligned left', () => {
    expect(component.hostClasses()).toBe('sa-divider sa-divider-horizontal sa-divider-solid sa-divider-left');
  });

  it('reflects layout, type and align inputs in the host classes', () => {
    ref.setInput('layout', 'vertical');
    ref.setInput('type', 'dashed');
    ref.setInput('align', 'bottom');
    fixture.detectChanges();

    expect(component.hostClasses()).toBe('sa-divider sa-divider-vertical sa-divider-dashed sa-divider-bottom');
  });

  it('exposes aria-orientation matching the layout', () => {
    ref.setInput('layout', 'vertical');
    fixture.detectChanges();

    expect(fixture.nativeElement.getAttribute('aria-orientation')).toBe('vertical');
    expect(fixture.nativeElement.getAttribute('role')).toBe('separator');
  });
});
