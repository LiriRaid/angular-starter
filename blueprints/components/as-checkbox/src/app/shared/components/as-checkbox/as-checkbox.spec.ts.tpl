import { Component } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { FormControl, ReactiveFormsModule } from '@angular/forms';
import { AsCheckbox } from './as-checkbox';

@Component({
  imports: [AsCheckbox, ReactiveFormsModule],
  template: `<as-checkbox label="Remember me" [formControl]="control" />`,
})
class Host {
  control = new FormControl(false, { nonNullable: true });
}

describe('AsCheckbox', () => {
  function render() {
    TestBed.configureTestingModule({ imports: [Host] });
    const fixture = TestBed.createComponent(Host);
    fixture.detectChanges();
    const element = fixture.nativeElement as HTMLElement;
    return { fixture, host: fixture.componentInstance, input: element.querySelector('input') as HTMLInputElement, element };
  }

  it('shows its label and starts unchecked', () => {
    const { input, element } = render();
    expect(element.textContent).toContain('Remember me');
    expect(input.checked).toBe(false);
  });

  it('writes the checked state to the form control', () => {
    const { input, host } = render();
    input.click();
    expect(host.control.value).toBe(true);
    input.click();
    expect(host.control.value).toBe(false);
  });

  it('follows a value set from the form', async () => {
    const { fixture, host, input } = render();
    host.control.setValue(true);
    fixture.detectChanges();
    await fixture.whenStable();
    expect(input.checked).toBe(true);
  });

  it('is disabled when the form disables it', () => {
    const { fixture, host, input } = render();
    host.control.disable();
    fixture.detectChanges();
    expect(input.disabled).toBe(true);
  });
});

describe('AsCheckbox indeterminate', () => {
  it('announces the mixed state', () => {
    TestBed.configureTestingModule({ imports: [AsCheckbox] });
    const fixture = TestBed.createComponent(AsCheckbox);
    fixture.componentRef.setInput('indeterminate', true);
    fixture.detectChanges();
    const input = (fixture.nativeElement as HTMLElement).querySelector('input') as HTMLInputElement;
    expect(input.indeterminate).toBe(true);
    expect(input.getAttribute('aria-checked')).toBe('mixed');
  });
});
