import { Component } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { AsFormControl } from './as-form-control';

/** The smallest control that can be built on the base class, with its protected parts opened. */
@Component({ selector: 'as-test-control', template: '' })
class TestControl extends AsFormControl<string> {
  protected override empty(): string {
    return '';
  }
  current = () => this.value();
  type = (value: string) => this.update(value);
  leave = () => this.touch();
  disabled = () => this.disabledByForm();
  id = () => this.uid;
}

describe('AsFormControl', () => {
  function create(): TestControl {
    TestBed.configureTestingModule({ imports: [TestControl] });
    return TestBed.createComponent(TestControl).componentInstance;
  }

  it('starts with the empty value and takes the one the form writes', () => {
    const control = create();
    expect(control.current()).toBe('');
    control.writeValue('hello');
    expect(control.current()).toBe('hello');
    control.writeValue(null);
    expect(control.current()).toBe('');
  });

  it('tells the form what the user typed', () => {
    const control = create();
    const received: string[] = [];
    control.registerOnChange((value) => received.push(value));
    control.type('abc');
    expect(received).toEqual(['abc']);
    expect(control.current()).toBe('abc');
  });

  it('tells the form when the user leaves the control', () => {
    const control = create();
    let touched = 0;
    control.registerOnTouched(() => touched++);
    control.leave();
    expect(touched).toBe(1);
  });

  it('knows when the form disables it', () => {
    const control = create();
    control.setDisabledState(true);
    expect(control.disabled()).toBe(true);
  });

  it('gives each control its own id', () => {
    const first = create();
    TestBed.resetTestingModule();
    const second = create();
    expect(first.id()).not.toBe(second.id());
  });
});
