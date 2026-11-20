import { Component, signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { provideAsIcons } from '@core/icons/icons.provider';
import { AsPopover, type AsPopoverItem } from './as-popover';

const ITEMS: AsPopoverItem[] = [
  { id: 'edit', label: 'Edit', icon: 'pencil' },
  { id: 'delete', label: 'Delete', icon: 'trash-2', danger: true },
  { id: 'locked', label: 'Locked', disabled: true },
];

@Component({
  imports: [AsPopover],
  template: `
    <as-popover [(open)]="menuOpen" [items]="items" (itemSelected)="selected = $event.id">
      <button asPopoverTrigger id="menu-trigger" (click)="menuOpen.set(!menuOpen())">Actions</button>
    </as-popover>
    <as-popover [(open)]="infoOpen">
      <button asPopoverTrigger id="info-trigger" (click)="infoOpen.set(!infoOpen())">Info</button>
      <p id="info">Any content</p>
    </as-popover>
    <p id="outside">outside</p>
  `,
})
class Host {
  items = ITEMS;
  menuOpen = signal(false);
  infoOpen = signal(false);
  selected = '';
}

describe('AsPopover', () => {
  function render() {
    TestBed.configureTestingModule({ imports: [Host], providers: [provideAsIcons()] });
    const fixture = TestBed.createComponent(Host);
    fixture.detectChanges();
    const element = fixture.nativeElement as HTMLElement;
    const click = (selector: string) => {
      (element.querySelector(selector) as HTMLElement).click();
      fixture.detectChanges();
    };
    return { fixture, host: fixture.componentInstance, element, click };
  }

  it('is closed until its trigger opens it', () => {
    const { element, click } = render();
    expect(element.querySelector('.as-popover__panel')).toBeNull();
    click('#menu-trigger');
    expect(element.querySelector('.as-popover__panel')).not.toBeNull();
  });

  it('shows a menu of the items and reports the one that is chosen', () => {
    const { host, element, click } = render();
    click('#menu-trigger');
    const entries = Array.from(element.querySelectorAll<HTMLElement>('[role="menuitem"]'));
    expect(entries.map((entry) => entry.textContent?.trim())).toEqual(['Edit', 'Delete', 'Locked']);

    entries[1]?.click();
    expect(host.selected).toBe('delete');
    expect(host.menuOpen()).toBe(false);
  });

  it('does not choose a disabled item', () => {
    const { host, element, click } = render();
    click('#menu-trigger');
    (element.querySelectorAll('[role="menuitem"]')[2] as HTMLButtonElement).click();
    expect(host.selected).toBe('');
  });

  it('shows its content when it has no items', () => {
    const { element, click } = render();
    click('#info-trigger');
    expect(element.querySelector('.as-popover__content #info')?.textContent).toBe('Any content');
  });

  it('closes when the user clicks outside', () => {
    const { host, click } = render();
    click('#info-trigger');
    expect(host.infoOpen()).toBe(true);
    click('#outside');
    expect(host.infoOpen()).toBe(false);
  });

  it('closes with Escape', () => {
    const { fixture, host, element, click } = render();
    click('#info-trigger');
    (element.querySelector('#info-trigger') as HTMLElement).dispatchEvent(
      new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }),
    );
    fixture.detectChanges();
    expect(host.infoOpen()).toBe(false);
  });
});
