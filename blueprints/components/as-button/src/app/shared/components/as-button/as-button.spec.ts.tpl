import { TestBed } from '@angular/core/testing';
import { provideAsIcons } from '@core/icons/icons.provider';
import { AsButton } from './as-button';

describe('AsButton', () => {
  function render(inputs: Record<string, unknown> = {}) {
    TestBed.configureTestingModule({ imports: [AsButton], providers: [provideAsIcons()] });
    const fixture = TestBed.createComponent(AsButton);
    for (const [key, value] of Object.entries(inputs)) fixture.componentRef.setInput(key, value);
    fixture.detectChanges();
    const element = fixture.nativeElement as HTMLElement;
    return { fixture, element, control: element.querySelector('.as-btn') as HTMLElement };
  }

  it('shows its label inside a button that does not submit by default', () => {
    const { control } = render({ label: 'Save' });
    expect(control.tagName).toBe('BUTTON');
    expect(control.textContent).toContain('Save');
    expect(control.getAttribute('type')).toBe('button');
  });

  it('applies the severity, variant and size as classes', () => {
    const { control } = render({ label: 'x', severity: 'danger', variant: 'outlined', size: 'lg' });
    expect(control.classList).toContain('as-btn--danger');
    expect(control.classList).toContain('as-btn--outlined');
    expect(control.classList).toContain('as-btn--lg');
  });

  it('emits the click', () => {
    const { fixture, control } = render({ label: 'Go' });
    let clicks = 0;
    fixture.componentInstance.clicked.subscribe(() => clicks++);
    control.click();
    expect(clicks).toBe(1);
  });

  it('does not emit while it is disabled or loading', () => {
    const disabled = render({ label: 'Go', disabled: true });
    let clicks = 0;
    disabled.fixture.componentInstance.clicked.subscribe(() => clicks++);
    disabled.control.click();
    expect(clicks).toBe(0);
    expect(disabled.control.hasAttribute('disabled')).toBe(true);
  });

  it('shows a spinner and announces that it is busy while loading', () => {
    const { control } = render({ label: 'Go', loading: true });
    expect(control.getAttribute('aria-busy')).toBe('true');
    expect(control.hasAttribute('disabled')).toBe(true);
    expect(control.querySelector('as-icon')).not.toBeNull();
  });

  it('becomes a link with an href', () => {
    const { control } = render({ label: 'Docs', href: 'https://angular.dev', target: '_blank' });
    expect(control.tagName).toBe('A');
    expect(control.getAttribute('href')).toBe('https://angular.dev');
    expect(control.getAttribute('rel')).toBe('noopener noreferrer');
  });

  it('is an icon button when it has an icon and no label', () => {
    const { control } = render({ icon: 'plus', ariaLabel: 'Add' });
    expect(control.classList).toContain('as-btn--icon-only');
    expect(control.getAttribute('aria-label')).toBe('Add');
  });
});
