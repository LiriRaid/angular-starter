import { Component } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { FormControl, ReactiveFormsModule } from '@angular/forms';
import { AsWeeklySchedule, computeWeeklyHours, defaultSchedule, type AsScheduleDay } from './as-weekly-schedule';

describe('weekly schedule helpers', () => {
  it('opens Monday to Friday, 09:00 to 17:00, by default', () => {
    const days = defaultSchedule();
    expect(days).toHaveLength(7);
    expect(days.filter((day) => day.enabled).map((day) => day.day)).toEqual([1, 2, 3, 4, 5]);
    expect(computeWeeklyHours(days)).toBe(40);
  });

  it('counts only enabled days with a closing time after the opening time', () => {
    const days: AsScheduleDay[] = [
      { day: 1, enabled: true, start: '08:00', end: '12:30' },
      { day: 2, enabled: false, start: '08:00', end: '12:00' },
      { day: 3, enabled: true, start: '12:00', end: '08:00' },
    ];
    expect(computeWeeklyHours(days)).toBe(4.5);
  });
});

@Component({
  imports: [AsWeeklySchedule, ReactiveFormsModule],
  template: `<as-weekly-schedule label="Opening hours" locale="en" [formControl]="control" />`,
})
class Host {
  control = new FormControl<AsScheduleDay[]>(defaultSchedule(), { nonNullable: true });
}

describe('AsWeeklySchedule', () => {
  function render() {
    TestBed.configureTestingModule({ imports: [Host] });
    const fixture = TestBed.createComponent(Host);
    fixture.detectChanges();
    const element = fixture.nativeElement as HTMLElement;
    return { fixture, host: fixture.componentInstance, element };
  }

  it('shows a row for each day of the week, with its total', () => {
    const { element } = render();
    expect(element.querySelectorAll('.as-schedule__row')).toHaveLength(7);
    expect(element.textContent).toContain('Monday');
    expect(element.querySelector('.as-schedule__total')?.textContent).toContain('40 hours a week');
  });

  it('writes a changed time to the form control', () => {
    const { fixture, host, element } = render();
    const monday = element.querySelectorAll('.as-schedule__row')[1] as HTMLElement;
    const start = monday.querySelector('input[type="time"]') as HTMLInputElement;
    start.value = '10:00';
    start.dispatchEvent(new Event('change'));
    fixture.detectChanges();
    expect(host.control.value.find((day) => day.day === 1)?.start).toBe('10:00');
    expect(element.querySelector('.as-schedule__total')?.textContent).toContain('39 hours a week');
  });

  it('flags a day that closes before it opens', () => {
    const { fixture, host, element } = render();
    host.control.setValue(defaultSchedule().map((day) => (day.day === 1 ? { ...day, end: '08:00' } : day)));
    fixture.detectChanges();
    expect(element.querySelector('.as-schedule__row--invalid [role="alert"]')).not.toBeNull();
  });

  it('is disabled when the form disables it', () => {
    const { fixture, host, element } = render();
    host.control.disable();
    fixture.detectChanges();
    expect((element.querySelector('fieldset') as HTMLFieldSetElement).disabled).toBe(true);
  });
});
