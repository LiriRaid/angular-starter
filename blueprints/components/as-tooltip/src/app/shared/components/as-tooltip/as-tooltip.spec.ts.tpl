import { Component } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { AsTooltip } from './as-tooltip';

@Component({
  imports: [AsTooltip],
  template: `<button asTooltip="Save changes" asTooltipPosition="bottom">Save</button>`,
})
class Host {}

describe('AsTooltip', () => {
  function render() {
    TestBed.configureTestingModule({ imports: [Host] });
    const fixture = TestBed.createComponent(Host);
    fixture.detectChanges();
    return fixture.nativeElement.querySelector('button') as HTMLButtonElement;
  }

  const tooltip = () => document.querySelector('[role="tooltip"]');

  afterEach(() => tooltip()?.remove());

  it('appears on hover with its text and goes away', () => {
    const button = render();
    expect(tooltip()).toBeNull();

    button.dispatchEvent(new Event('mouseenter'));
    expect(tooltip()?.textContent).toBe('Save changes');

    button.dispatchEvent(new Event('mouseleave'));
    expect(tooltip()).toBeNull();
  });

  it('appears on keyboard focus too', () => {
    const button = render();
    button.dispatchEvent(new Event('focusin'));
    expect(tooltip()).not.toBeNull();
    button.dispatchEvent(new Event('focusout'));
    expect(tooltip()).toBeNull();
  });

  it('describes the element for assistive technology', () => {
    const button = render();
    button.dispatchEvent(new Event('mouseenter'));
    expect(button.getAttribute('aria-describedby')).toBe(tooltip()?.id);
  });

  it('is removed with the element', () => {
    TestBed.configureTestingModule({ imports: [Host] });
    const fixture = TestBed.createComponent(Host);
    fixture.detectChanges();
    (fixture.nativeElement.querySelector('button') as HTMLElement).dispatchEvent(
      new Event('mouseenter'),
    );
    expect(tooltip()).not.toBeNull();
    fixture.destroy();
    expect(tooltip()).toBeNull();
  });
});
