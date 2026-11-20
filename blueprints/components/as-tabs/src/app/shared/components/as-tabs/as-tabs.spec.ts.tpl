import { Component, signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { provideAsIcons } from '@core/icons/icons.provider';
import { AsTabs, type AsTab } from './as-tabs';

const TABS: AsTab[] = [
  { id: 'profile', label: 'Profile', icon: 'user' },
  { id: 'billing', label: 'Billing', badge: 3 },
  { id: 'locked', label: 'Locked', disabled: true },
  { id: 'team', label: 'Team' },
];

@Component({
  imports: [AsTabs],
  template: `<as-tabs [tabs]="tabs" [(selected)]="current" />`,
})
class Host {
  tabs = TABS;
  current = signal('profile');
}

describe('AsTabs', () => {
  function render() {
    TestBed.configureTestingModule({ imports: [Host], providers: [provideAsIcons()] });
    const fixture = TestBed.createComponent(Host);
    fixture.detectChanges();
    const element = fixture.nativeElement as HTMLElement;
    const buttons = () => Array.from(element.querySelectorAll<HTMLButtonElement>('[role="tab"]'));
    return { fixture, host: fixture.componentInstance, element, buttons };
  }

  it('shows the tabs and marks the selected one', () => {
    const { buttons } = render();
    expect(buttons().map((button) => button.textContent?.trim())).toEqual(['Profile', 'Billing3', 'Locked', 'Team']);
    expect(buttons()[0]?.getAttribute('aria-selected')).toBe('true');
    expect(buttons()[1]?.getAttribute('aria-selected')).toBe('false');
  });

  it('selects the tab that is clicked, updating the two-way binding', () => {
    const { fixture, host, buttons } = render();
    buttons()[1]?.click();
    fixture.detectChanges();
    expect(host.current()).toBe('billing');
    expect(buttons()[1]?.getAttribute('aria-selected')).toBe('true');
  });

  it('does not select a disabled tab', () => {
    const { host, buttons } = render();
    expect(buttons()[2]?.disabled).toBe(true);
    buttons()[2]?.click();
    expect(host.current()).toBe('profile');
  });

  it('moves with the arrow keys, skipping disabled tabs', () => {
    const { fixture, host, element } = render();
    const strip = element.querySelector('[role="tablist"]') as HTMLElement;
    const press = (key: string) => {
      strip.dispatchEvent(new KeyboardEvent('keydown', { key, bubbles: true }));
      fixture.detectChanges();
    };
    press('ArrowRight');
    expect(host.current()).toBe('billing');
    press('ArrowRight');
    expect(host.current()).toBe('team');
    press('ArrowRight');
    expect(host.current()).toBe('profile');
    press('End');
    expect(host.current()).toBe('team');
    press('Home');
    expect(host.current()).toBe('profile');
  });

  it('only lets the selected tab be reached with the Tab key', () => {
    const { buttons } = render();
    expect(buttons().map((button) => button.getAttribute('tabindex'))).toEqual(['0', '-1', '-1', '-1']);
  });
});
