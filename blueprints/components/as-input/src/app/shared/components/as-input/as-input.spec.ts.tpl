import { Component, signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { FormControl, ReactiveFormsModule } from '@angular/forms';
import { provideAsIcons } from '@core/icons/icons.provider';
import { AsInput } from './as-input';

@Component({
  imports: [AsInput, ReactiveFormsModule],
  template: `<as-input label="Email" type="email" [formControl]="control" [error]="error()" />`,
})
class Host {
  control = new FormControl('ada@example.com', { nonNullable: true });
  error = signal('');
}

describe('AsInput', () => {
  function render() {
    TestBed.configureTestingModule({ imports: [Host], providers: [provideAsIcons()] });
    const fixture = TestBed.createComponent(Host);
    fixture.detectChanges();
    const element = fixture.nativeElement as HTMLElement;
    return { fixture, host: fixture.componentInstance, input: element.querySelector('input') as HTMLInputElement, element };
  }

  it('shows the label and the value of the form control', () => {
    const { input, element } = render();
    expect(element.querySelector('label')?.textContent).toContain('Email');
    expect(input.value).toBe('ada@example.com');
    expect(input.type).toBe('email');
  });

  it('connects the label to the input', () => {
    const { input, element } = render();
    expect(element.querySelector('label')?.getAttribute('for')).toBe(input.id);
  });

  it('writes what the user types to the form control and marks it touched', () => {
    const { input, host } = render();
    input.value = 'grace@example.com';
    input.dispatchEvent(new Event('input'));
    expect(host.control.value).toBe('grace@example.com');

    input.dispatchEvent(new Event('blur'));
    expect(host.control.touched).toBe(true);
  });

  it('follows a value set from the form', async () => {
    const { fixture, host, input } = render();
    host.control.setValue('new@example.com');
    fixture.detectChanges();
    await fixture.whenStable();
    expect(input.value).toBe('new@example.com');
  });

  it('is disabled when the form disables it', () => {
    const { fixture, host, input } = render();
    host.control.disable();
    fixture.detectChanges();
    expect(input.disabled).toBe(true);
  });

  it('shows an error, marks the field invalid and links the message', () => {
    const { fixture, host, input, element } = render();
    host.error.set('Enter a valid email');
    fixture.detectChanges();
    const message = element.querySelector('[role="alert"]');
    expect(message?.textContent).toContain('Enter a valid email');
    expect(input.getAttribute('aria-invalid')).toBe('true');
    expect(input.getAttribute('aria-describedby')).toBe(message?.id);
  });
});

describe('AsInput as a password field', () => {
  it('can show and hide the password', () => {
    TestBed.configureTestingModule({ imports: [AsInput], providers: [provideAsIcons()] });
    const fixture = TestBed.createComponent(AsInput);
    fixture.componentRef.setInput('type', 'password');
    fixture.detectChanges();
    const element = fixture.nativeElement as HTMLElement;
    const input = element.querySelector('input') as HTMLInputElement;
    expect(input.type).toBe('password');

    (element.querySelector('.as-field__action') as HTMLButtonElement).click();
    fixture.detectChanges();
    expect(input.type).toBe('text');
  });
});
