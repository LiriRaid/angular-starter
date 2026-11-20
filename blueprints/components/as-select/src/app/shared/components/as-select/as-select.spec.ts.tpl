import { Component } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { FormControl, ReactiveFormsModule } from '@angular/forms';
import { provideAsIcons } from '@core/icons/icons.provider';
import { AsSelect, type AsSelectOption } from './as-select';

const OPTIONS: AsSelectOption[] = [
  { value: 'hn', label: 'Honduras' },
  { value: 'mx', label: 'Mexico' },
  { value: 'xx', label: 'Closed', disabled: true },
];

@Component({
  imports: [AsSelect, ReactiveFormsModule],
  template: `<as-select label="Country" [options]="options" [formControl]="control" />`,
})
class Host {
  options = OPTIONS;
  control = new FormControl<string | null>(null);
}

describe('AsSelect', () => {
  function render() {
    TestBed.configureTestingModule({ imports: [Host], providers: [provideAsIcons()] });
    const fixture = TestBed.createComponent(Host);
    fixture.detectChanges();
    const element = fixture.nativeElement as HTMLElement;
    const trigger = element.querySelector('.as-select__trigger') as HTMLButtonElement;
    const options = () => Array.from(element.querySelectorAll<HTMLElement>('[role="option"]'));
    return { fixture, host: fixture.componentInstance, element, trigger, options };
  }

  it('shows the placeholder until something is chosen, with the list closed', () => {
    const { trigger, options } = render();
    expect(trigger.textContent).toContain('Select...');
    expect(trigger.getAttribute('aria-expanded')).toBe('false');
    expect(options()).toHaveLength(0);
  });

  it('opens the list and writes the chosen value to the form control', () => {
    const { fixture, host, trigger, options } = render();
    trigger.click();
    fixture.detectChanges();
    expect(options().map((option) => option.textContent?.trim())).toEqual(['Honduras', 'Mexico', 'Closed']);

    options()[1]?.click();
    fixture.detectChanges();
    expect(host.control.value).toBe('mx');
    expect(trigger.textContent).toContain('Mexico');
    expect(options()).toHaveLength(0);
  });

  it('does not choose a disabled option', () => {
    const { fixture, host, trigger, options } = render();
    trigger.click();
    fixture.detectChanges();
    options()[2]?.click();
    expect(host.control.value).toBeNull();
  });

  it('works with the keyboard', () => {
    const { fixture, host, element, trigger } = render();
    const press = (key: string) => {
      trigger.dispatchEvent(new KeyboardEvent('keydown', { key, bubbles: true }));
      fixture.detectChanges();
    };
    press('ArrowDown');
    expect(element.querySelector('[role="listbox"]')).not.toBeNull();
    press('ArrowDown');
    press('Enter');
    expect(host.control.value).toBe('mx');

    press('ArrowDown');
    press('Escape');
    expect(element.querySelector('[role="listbox"]')).toBeNull();
  });

  it('closes when the user clicks somewhere else', () => {
    const { fixture, element, trigger } = render();
    trigger.click();
    fixture.detectChanges();
    document.body.click();
    fixture.detectChanges();
    expect(element.querySelector('[role="listbox"]')).toBeNull();
  });

  it('follows a value set from the form and can be disabled by it', async () => {
    const { fixture, host, trigger } = render();
    host.control.setValue('hn');
    fixture.detectChanges();
    await fixture.whenStable();
    expect(trigger.textContent).toContain('Honduras');

    host.control.disable();
    fixture.detectChanges();
    expect(trigger.disabled).toBe(true);
  });
});
