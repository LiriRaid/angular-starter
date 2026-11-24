import { ComponentFixture, TestBed } from '@angular/core/testing';
import { describe, expect, it, vi, beforeEach } from 'vitest';
import { AsCheckbox } from './as-checkbox';

describe('AsCheckbox', () => {
  let fixture: ComponentFixture<AsCheckbox>;
  let component: AsCheckbox;

  beforeEach(async () => {
    TestBed.overrideComponent(AsCheckbox, { set: { imports: [], template: '' } });

    await TestBed.configureTestingModule({
      imports: [AsCheckbox],
    }).compileComponents();

    fixture = TestBed.createComponent(AsCheckbox);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('creates the component', () => {
    expect(component).toBeTruthy();
  });

  it('writeValue reflects the incoming boolean into value()', () => {
    component.writeValue(true);
    expect(component.value()).toBe(true);

    component.writeValue(undefined);
    expect(component.value()).toBe(false);
  });

  it('handleChange toggles value() and notifies onChange', () => {
    const onChange = vi.fn();
    component.registerOnChange(onChange);

    component.handleChange();
    expect(component.value()).toBe(true);
    expect(onChange).toHaveBeenCalledWith(true);

    component.handleChange();
    expect(component.value()).toBe(false);
    expect(onChange).toHaveBeenCalledWith(false);
  });

  it('setDisabledState updates isDisabled()', () => {
    component.setDisabledState(true);
    expect(component.isDisabled()).toBe(true);
  });

  it('onInputBlur notifies onTouched', () => {
    const onTouched = vi.fn();
    component.registerOnTouched(onTouched);

    component.onInputBlur();
    expect(onTouched).toHaveBeenCalled();
  });
});
