import { TestBed } from '@angular/core/testing';
import { AsSkeleton } from './as-skeleton';

describe('AsSkeleton', () => {
  function render(inputs: Record<string, unknown> = {}) {
    TestBed.configureTestingModule({ imports: [AsSkeleton] });
    const fixture = TestBed.createComponent(AsSkeleton);
    for (const [key, value] of Object.entries(inputs)) fixture.componentRef.setInput(key, value);
    fixture.detectChanges();
    return fixture.nativeElement as HTMLElement;
  }

  it('tells assistive technology that content is loading', () => {
    const element = render();
    expect(element.getAttribute('role')).toBe('status');
    expect(element.getAttribute('aria-busy')).toBe('true');
  });

  it('draws one block by default', () => {
    expect(render().querySelectorAll('.as-skeleton__block')).toHaveLength(1);
  });

  it('draws the lines of a text skeleton, the last one shorter', () => {
    const element = render({ shape: 'text', lines: 3 });
    const blocks = element.querySelectorAll('.as-skeleton__block');
    expect(blocks).toHaveLength(3);
    expect(blocks[2]?.classList).toContain('as-skeleton__block--short');
    expect(blocks[0]?.classList).not.toContain('as-skeleton__block--short');
  });

  it('takes its size from the inputs', () => {
    const element = render({ width: '12rem', height: '2rem' });
    expect(element.style.getPropertyValue('--as-skeleton-width')).toBe('12rem');
    expect(element.style.getPropertyValue('--as-skeleton-height')).toBe('2rem');
  });
});
