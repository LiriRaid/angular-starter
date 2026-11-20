import { Component } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { FormControl, ReactiveFormsModule } from '@angular/forms';
import { provideAsIcons } from '@core/icons/icons.provider';
import { AsDatepicker } from './as-datepicker';

@Component({
  imports: [AsDatepicker, ReactiveFormsModule],
  template: `<as-datepicker label="Birthday" locale="en" [min]="min" [max]="max" [formControl]="control" />`,
})
class Host {
  min = new Date(2026, 0, 10);
  max = new Date(2026, 0, 20);
  control = new FormControl<Date | null>(new Date(2026, 0, 15));
}

describe('AsDatepicker', () => {
  function render() {
    TestBed.configureTestingModule({ imports: [Host], providers: [provideAsIcons()] });
    const fixture = TestBed.createComponent(Host);
    fixture.detectChanges();
    const element = fixture.nativeElement as HTMLElement;
    const trigger = element.querySelector('.as-datepicker__trigger') as HTMLButtonElement;
    const days = () => Array.from(element.querySelectorAll<HTMLButtonElement>('.as-datepicker__day'));
    const dayButton = (label: string) =>
      days().find((day) => day.textContent?.trim() === label && !day.classList.contains('as-datepicker__day--outside'));
    return { fixture, host: fixture.componentInstance, element, trigger, days, dayButton };
  }

  it('shows the date of the form control, formatted', () => {
    const { trigger } = render();
    expect(trigger.textContent).toContain('Jan 15, 2026');
  });

  it('opens a calendar on the month of the value', () => {
    const { fixture, trigger, element, days } = render();
    trigger.click();
    fixture.detectChanges();
    expect(element.querySelector('.as-datepicker__title')?.textContent).toContain('January 2026');
    expect(days()).toHaveLength(42);
    expect(element.querySelector('.as-datepicker__day--selected')?.textContent?.trim()).toBe('15');
  });

  it('writes the picked day to the form control and closes', () => {
    const { fixture, host, trigger, element, dayButton } = render();
    trigger.click();
    fixture.detectChanges();
    dayButton('18')?.click();
    fixture.detectChanges();
    expect(host.control.value).toEqual(new Date(2026, 0, 18));
    expect(element.querySelector('[role="dialog"]')).toBeNull();
  });

  it('does not let the user pick a day outside of min and max', () => {
    const { fixture, host, trigger, dayButton } = render();
    trigger.click();
    fixture.detectChanges();
    expect(dayButton('5')?.disabled).toBe(true);
    expect(dayButton('25')?.disabled).toBe(true);
    dayButton('25')?.click();
    expect(host.control.value).toEqual(new Date(2026, 0, 15));
  });

  it('moves between months', () => {
    const { fixture, trigger, element } = render();
    trigger.click();
    fixture.detectChanges();
    (element.querySelector('[aria-label="Next month"]') as HTMLButtonElement).click();
    fixture.detectChanges();
    expect(element.querySelector('.as-datepicker__title')?.textContent).toContain('February 2026');
  });

  it('clears the value', () => {
    const { fixture, host, trigger, element } = render();
    trigger.click();
    fixture.detectChanges();
    (element.querySelector('.as-datepicker__clear') as HTMLButtonElement).click();
    expect(host.control.value).toBeNull();
  });

  it('closes with Escape and when the user clicks outside', () => {
    const { fixture, trigger, element } = render();
    trigger.click();
    fixture.detectChanges();
    (element.querySelector('as-datepicker') as HTMLElement).dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }));
    fixture.detectChanges();
    expect(element.querySelector('[role="dialog"]')).toBeNull();

    trigger.click();
    fixture.detectChanges();
    document.body.click();
    fixture.detectChanges();
    expect(element.querySelector('[role="dialog"]')).toBeNull();
  });

  it('is disabled when the form disables it', () => {
    const { fixture, host, trigger } = render();
    host.control.disable();
    fixture.detectChanges();
    expect(trigger.disabled).toBe(true);
  });
});
