import { TestBed } from '@angular/core/testing';
import { provideAsIcons } from '@core/icons/icons.provider';
import { AsIcon } from './as-icon';

describe('AsIcon', () => {
  function render(inputs: Record<string, unknown>) {
    TestBed.configureTestingModule({ imports: [AsIcon], providers: [provideAsIcons()] });
    const fixture = TestBed.createComponent(AsIcon);
    for (const [key, value] of Object.entries(inputs)) fixture.componentRef.setInput(key, value);
    fixture.detectChanges();
    return fixture.nativeElement as HTMLElement;
  }

  it('draws a registered Lucide icon', () => {
    const element = render({ name: 'check' });
    expect(element.querySelector('svg')).not.toBeNull();
  });

  it('is hidden from screen readers unless it has a label', () => {
    expect(render({ name: 'check' }).getAttribute('aria-hidden')).toBe('true');
  });

  it('exposes its label as an image', () => {
    TestBed.resetTestingModule();
    const element = render({ name: 'check', label: 'Done' });
    expect(element.getAttribute('role')).toBe('img');
    expect(element.getAttribute('aria-label')).toBe('Done');
    expect(element.getAttribute('aria-hidden')).toBeNull();
  });

  it('turns a number into pixels and keeps a CSS length', () => {
    TestBed.resetTestingModule();
    expect(render({ name: 'check', size: 24 }).style.getPropertyValue('--as-icon-size')).toBe('24px');
    TestBed.resetTestingModule();
    expect(render({ name: 'check', size: '1.5rem' }).style.getPropertyValue('--as-icon-size')).toBe('1.5rem');
  });

  it('draws an SVG file as a mask when given a src', () => {
    TestBed.resetTestingModule();
    const element = render({ src: '/logo.svg' });
    const mask = element.querySelector('.as-icon__svg') as HTMLElement;
    expect(mask.style.getPropertyValue('--as-icon-url')).toBe('url(/logo.svg)');
    expect(element.querySelector('svg')).toBeNull();
  });
});
