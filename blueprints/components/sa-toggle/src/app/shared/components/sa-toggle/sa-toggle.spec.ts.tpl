import { ComponentFixture, TestBed } from '@angular/core/testing';
import { describe, expect, it, vi, beforeEach } from 'vitest';
import { ComponentRef } from '@angular/core';
import { AsToggle } from './as-toggle';

type ToggleInternals = { localChecked: () => boolean };

describe('AsToggle', () => {
  let fixture: ComponentFixture<AsToggle>;
  let component: AsToggle;
  let ref: ComponentRef<AsToggle>;

  beforeEach(async () => {
    TestBed.overrideComponent(AsToggle, { set: { imports: [], template: '' } });

    await TestBed.configureTestingModule({
      imports: [AsToggle],
    }).compileComponents();

    fixture = TestBed.createComponent(AsToggle);
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
