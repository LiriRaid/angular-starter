import { Component } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { FormControl, ReactiveFormsModule } from '@angular/forms';
import { AsToggle } from './as-toggle';

@Component({
  imports: [AsToggle, ReactiveFormsModule],
  template: `<as-toggle label="Notifications" [formControl]="control" />`,
})
class Host {
  control = new FormControl(false, { nonNullable: true });
}

describe('AsToggle', () => {
  function render() {
    TestBed.configureTestingModule({ imports: [Host] });
    const fixture = TestBed.createComponent(Host);
    fixture.detectChanges();
    const element = fixture.nativeElement as HTMLElement;
    return { fixture, host: fixture.componentInstance, button: element.querySelector('button') as HTMLButtonElement, element };
  }

  it('is a switch with its label, off at the start', () => {
    const { button, element } = render();
    expect(button.getAttribute('role')).toBe('switch');
    expect(button.getAttribute('aria-checked')).toBe('false');
    expect(element.textContent).toContain('Notifications');
  });

  it('writes the new state to the form control when clicked', () => {
    const { fixture, host, button } = render();
    button.click();
    fixture.detectChanges();
    expect(host.control.value).toBe(true);
    expect(button.getAttribute('aria-checked')).toBe('true');
  });

  it('follows a value set from the form', () => {
    const { fixture, host, button } = render();
    host.control.setValue(true);
    fixture.detectChanges();
    expect(button.getAttribute('aria-checked')).toBe('true');
  });

  it('does not change when the form disables it', () => {
    const { fixture, host, button } = render();
    host.control.disable();
    fixture.detectChanges();
    expect(button.disabled).toBe(true);
    button.click();
    expect(host.control.value).toBe(false);
  });
});
