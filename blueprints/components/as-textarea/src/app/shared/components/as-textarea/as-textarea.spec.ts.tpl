import { Component } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { FormControl, ReactiveFormsModule } from '@angular/forms';
import { AsTextarea } from './as-textarea';

@Component({
  imports: [AsTextarea, ReactiveFormsModule],
  template: `<as-textarea label="Notes" [maxlength]="20" [formControl]="control" />`,
})
class Host {
  control = new FormControl('Hello', { nonNullable: true });
}

describe('AsTextarea', () => {
  function render() {
    TestBed.configureTestingModule({ imports: [Host] });
    const fixture = TestBed.createComponent(Host);
    fixture.detectChanges();
    const element = fixture.nativeElement as HTMLElement;
    return { fixture, host: fixture.componentInstance, textarea: element.querySelector('textarea') as HTMLTextAreaElement, element };
  }

  it('shows the label and the value of the form control', () => {
    const { textarea, element } = render();
    expect(element.querySelector('label')?.textContent).toContain('Notes');
    expect(textarea.value).toBe('Hello');
  });

  it('writes what the user types to the form control', () => {
    const { fixture, host, textarea, element } = render();
    textarea.value = 'Hello there';
    textarea.dispatchEvent(new Event('input'));
    fixture.detectChanges();
    expect(host.control.value).toBe('Hello there');
    expect(element.querySelector('.as-textarea__count')?.textContent).toContain('11/20');
  });

  it('is disabled when the form disables it', () => {
    const { fixture, host, textarea } = render();
    host.control.disable();
    fixture.detectChanges();
    expect(textarea.disabled).toBe(true);
  });
});
