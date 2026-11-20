import { TestBed } from '@angular/core/testing';
import { provideAsIcons } from '@core/icons/icons.provider';
import { vi } from 'vitest';
import { AsSearch } from './as-search';

describe('AsSearch', () => {
  beforeEach(() => vi.useFakeTimers());
  afterEach(() => vi.useRealTimers());

  function render(inputs: Record<string, unknown> = {}) {
    TestBed.configureTestingModule({ imports: [AsSearch], providers: [provideAsIcons()] });
    const fixture = TestBed.createComponent(AsSearch);
    for (const [key, value] of Object.entries(inputs)) fixture.componentRef.setInput(key, value);
    fixture.detectChanges();
    const element = fixture.nativeElement as HTMLElement;
    const input = element.querySelector('input') as HTMLInputElement;
    const searches: string[] = [];
    fixture.componentInstance.search.subscribe((text) => searches.push(text));
    const type = (text: string) => {
      input.value = text;
      input.dispatchEvent(new Event('input'));
      fixture.detectChanges();
    };
    return { fixture, element, input, searches, type };
  }

  it('keeps the text and waits for the user to stop typing before searching', () => {
    const { fixture, searches, type } = render({ debounce: 200 });
    type('a');
    type('ad');
    type('ada');
    expect(fixture.componentInstance.value()).toBe('ada');
    expect(searches).toEqual([]);

    vi.advanceTimersByTime(200);
    expect(searches).toEqual(['ada']);
  });

  it('searches at once with Enter', () => {
    const { input, searches, type } = render();
    type('grace');
    input.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter' }));
    expect(searches).toEqual(['grace']);
    vi.advanceTimersByTime(1000);
    expect(searches).toEqual(['grace']);
  });

  it('clears the field and searches for nothing', () => {
    const { fixture, element, searches, type } = render();
    type('ada');
    (element.querySelector('.as-field__action') as HTMLButtonElement).click();
    fixture.detectChanges();
    expect(fixture.componentInstance.value()).toBe('');
    expect(searches).toEqual(['']);
    expect(element.querySelector('.as-field__action')).toBeNull();
  });
});
