import { Component, signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { provideAsIcons } from '@core/icons/icons.provider';
import { AsDrawer } from './as-drawer';

@Component({
  imports: [AsDrawer],
  template: `
    <as-drawer [(open)]="visible" title="Filters" position="left" width="20rem">
      <p id="body">Filter content</p>
      <button asDrawerFooter id="apply">Apply</button>
    </as-drawer>
  `,
})
class Host {
  visible = signal(false);
}

describe('AsDrawer', () => {
  function render() {
    TestBed.configureTestingModule({ imports: [Host], providers: [provideAsIcons()] });
    const fixture = TestBed.createComponent(Host);
    fixture.detectChanges();
    const element = fixture.nativeElement as HTMLElement;
    const dialog = () => element.querySelector('[role="dialog"]') as HTMLElement | null;
    const show = async () => {
      fixture.componentInstance.visible.set(true);
      fixture.detectChanges();
      await fixture.whenStable();
    };
    return { fixture, host: fixture.componentInstance, element, dialog, show };
  }

  it('draws nothing while it is closed', () => {
    expect(render().dialog()).toBeNull();
  });

  it('opens on the side asked for, with its title, content and footer', async () => {
    const { dialog, show, element } = render();
    await show();
    expect(dialog()?.classList).toContain('as-drawer__panel--left');
    expect(dialog()?.style.width).toBe('20rem');
    expect(dialog()?.getAttribute('aria-modal')).toBe('true');
    expect(element.querySelector('h2')?.textContent).toContain('Filters');
    expect(element.querySelector('#body')).not.toBeNull();
    expect(element.querySelector('.as-drawer__footer #apply')).not.toBeNull();
  });

  it('closes with the button, Escape and the backdrop', async () => {
    const { fixture, host, dialog, show, element } = render();

    await show();
    (element.querySelector('.as-drawer__close') as HTMLButtonElement).click();
    fixture.detectChanges();
    expect(host.visible()).toBe(false);

    await show();
    dialog()?.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }));
    fixture.detectChanges();
    expect(host.visible()).toBe(false);

    await show();
    (element.querySelector('.as-drawer__backdrop') as HTMLElement).click();
    fixture.detectChanges();
    expect(host.visible()).toBe(false);
  });
});
