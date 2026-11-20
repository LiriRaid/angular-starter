import { TestBed } from '@angular/core/testing';
import { AsSelectableItem } from './as-selectable-item';

describe('AsSelectableItem', () => {
  function render(inputs: Record<string, unknown> = {}) {
    TestBed.configureTestingModule({ imports: [AsSelectableItem] });
    const fixture = TestBed.createComponent(AsSelectableItem);
    fixture.componentRef.setInput('title', 'Ada Lovelace');
    for (const [key, value] of Object.entries(inputs)) fixture.componentRef.setInput(key, value);
    fixture.detectChanges();
    const element = fixture.nativeElement as HTMLElement;
    return { fixture, element, button: element.querySelector('button') as HTMLButtonElement };
  }

  it('shows its title and subtitle', () => {
    const { element } = render({ subtitle: 'ada@example.com' });
    expect(element.textContent).toContain('Ada Lovelace');
    expect(element.textContent).toContain('ada@example.com');
  });

  it('says whether it is selected', () => {
    expect(render({ selected: true }).button.getAttribute('aria-pressed')).toBe('true');
    TestBed.resetTestingModule();
    expect(render().button.getAttribute('aria-pressed')).toBe('false');
  });

  it('emits when it is clicked', () => {
    const { fixture, button } = render();
    let clicks = 0;
    fixture.componentInstance.itemClick.subscribe(() => clicks++);
    button.click();
    expect(clicks).toBe(1);
  });

  it('does not emit when it is disabled', () => {
    const { fixture, button } = render({ disabled: true });
    let clicks = 0;
    fixture.componentInstance.itemClick.subscribe(() => clicks++);
    button.click();
    expect(clicks).toBe(0);
  });
});
