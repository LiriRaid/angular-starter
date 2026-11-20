import { TestBed } from '@angular/core/testing';
import { AsDivider } from './as-divider';

describe('AsDivider', () => {
  function render(inputs: Record<string, unknown> = {}) {
    TestBed.configureTestingModule({ imports: [AsDivider] });
    const fixture = TestBed.createComponent(AsDivider);
    for (const [key, value] of Object.entries(inputs)) fixture.componentRef.setInput(key, value);
    fixture.detectChanges();
    return fixture.nativeElement as HTMLElement;
  }

  it('is a separator for assistive technology', () => {
    const element = render();
    expect(element.getAttribute('role')).toBe('separator');
    expect(element.getAttribute('aria-orientation')).toBe('horizontal');
  });

  it('shows its label and where it sits', () => {
    const element = render({ label: 'or', align: 'start' });
    expect(element.textContent).toContain('or');
    expect(element.getAttribute('data-align')).toBe('start');
  });

  it('has no label element without a label', () => {
    const element = render();
    expect(element.querySelector('.as-divider__label')).toBeNull();
    expect(element.hasAttribute('data-align')).toBe(false);
  });

  it('can be vertical or dashed', () => {
    const element = render({ orientation: 'vertical', style: 'dashed' });
    expect(element.getAttribute('aria-orientation')).toBe('vertical');
    expect(element.classList).toContain('as-divider--vertical');
    expect(element.classList).toContain('as-divider--dashed');
  });
});
