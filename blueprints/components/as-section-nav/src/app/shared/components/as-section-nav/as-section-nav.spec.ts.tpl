import { Component, signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { provideAsIcons } from '@core/icons/icons.provider';
import { AsSectionNav, type AsSectionNavItem } from './as-section-nav';

const ITEMS: AsSectionNavItem[] = [
  { id: 'profile', label: 'Profile', icon: 'user', description: 'Your account' },
  { id: 'team', label: 'Team', icon: 'users' },
  { id: 'billing', label: 'Billing', disabled: true },
];

@Component({
  imports: [AsSectionNav],
  template: `<as-section-nav title="Settings" description="Account and team" [items]="items" [(selected)]="section" />`,
})
class Host {
  items = ITEMS;
  section = signal('profile');
}

describe('AsSectionNav', () => {
  function render() {
    TestBed.configureTestingModule({ imports: [Host], providers: [provideAsIcons()] });
    const fixture = TestBed.createComponent(Host);
    fixture.detectChanges();
    const element = fixture.nativeElement as HTMLElement;
    const buttons = () => Array.from(element.querySelectorAll<HTMLButtonElement>('.as-section-nav__item'));
    return { fixture, host: fixture.componentInstance, element, buttons };
  }

  it('shows its title, description and the sections', () => {
    const { element, buttons } = render();
    expect(element.querySelector('h2')?.textContent).toBe('Settings');
    expect(element.textContent).toContain('Account and team');
    expect(buttons().map((button) => button.querySelector('.as-section-nav__label')?.textContent)).toEqual([
      'Profile',
      'Team',
      'Billing',
    ]);
  });

  it('marks the current section for assistive technology', () => {
    const { buttons } = render();
    expect(buttons()[0]?.getAttribute('aria-current')).toBe('page');
    expect(buttons()[1]?.getAttribute('aria-current')).toBeNull();
  });

  it('selects the section that is clicked, updating the two-way binding', () => {
    const { fixture, host, buttons } = render();
    buttons()[1]?.click();
    fixture.detectChanges();
    expect(host.section()).toBe('team');
  });

  it('does not select a disabled section', () => {
    const { host, buttons } = render();
    expect(buttons()[2]?.disabled).toBe(true);
    buttons()[2]?.click();
    expect(host.section()).toBe('profile');
  });
});
