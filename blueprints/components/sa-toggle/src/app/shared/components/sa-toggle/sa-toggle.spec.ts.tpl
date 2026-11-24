import { ComponentFixture, TestBed } from '@angular/core/testing';
import { describe, expect, it, vi, beforeEach } from 'vitest';
import { ComponentRef } from '@angular/core';
import { SaToggle } from './sa-toggle';

type ToggleInternals = { localChecked: () => boolean };

describe('SaToggle', () => {
  let fixture: ComponentFixture<SaToggle>;
  let component: SaToggle;
  let ref: ComponentRef<SaToggle>;

  beforeEach(async () => {
    TestBed.overrideComponent(SaToggle, { set: { imports: [], template: '' } });

    await TestBed.configureTestingModule({
      imports: [SaToggle],
    }).compileComponents();

    fixture = TestBed.createComponent(SaToggle);
    component = fixture.componentInstance;
    ref = fixture.componentRef;
    fixture.detectChanges();
  });

  it('creates the component', () => {
    expect(component).toBeTruthy();
  });

  it('localChecked mirrors the checked input', () => {
    ref.setInput('checked', true);
    fixture.detectChanges();
    expect((component as unknown as ToggleInternals).localChecked()).toBe(true);
  });

  it('onToggle inverts localChecked', () => {
    component.onToggle();
    expect((component as unknown as ToggleInternals).localChecked()).toBe(true);
    component.onToggle();
    expect((component as unknown as ToggleInternals).localChecked()).toBe(false);
  });

  it('onToggle emits the changed output with the new value', () => {
    const spy = vi.spyOn(component.changed, 'emit');
    ref.setInput('checked', true);
    fixture.detectChanges();
    component.onToggle();
    expect(spy).toHaveBeenCalledWith(false);
  });
});
