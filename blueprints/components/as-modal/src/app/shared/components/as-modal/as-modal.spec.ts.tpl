import { Component, signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { provideAsIcons } from '@core/icons/icons.provider';
import { AsModal } from './as-modal';

@Component({
  imports: [AsModal],
  template: `
    <button id="opener" (click)="visible.set(true)">Open</button>
    <as-modal [(open)]="visible" title="Delete customer">
      <p id="body">This cannot be undone.</p>
      <button asModalFooter id="confirm">Delete</button>
    </as-modal>
  `,
})
class Host {
  visible = signal(false);
}

describe('AsModal', () => {
  async function render() {
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

  it('draws nothing while it is closed', async () => {
    const { dialog } = await render();
    expect(dialog()).toBeNull();
  });

  it('shows an accessible dialog with its title, content and footer when it opens', async () => {
    const { dialog, show, element } = await render();
    await show();
    expect(dialog()?.getAttribute('aria-modal')).toBe('true');
    expect(dialog()?.getAttribute('aria-labelledby')).toBe(element.querySelector('h2')?.id);
    expect(element.querySelector('h2')?.textContent).toContain('Delete customer');
    expect(element.querySelector('#body')).not.toBeNull();
    expect(element.querySelector('.as-modal__footer #confirm')).not.toBeNull();
  });

  it('closes with the close button, updating the two-way binding', async () => {
    const { fixture, host, dialog, show, element } = await render();
    await show();
    (element.querySelector('.as-modal__close') as HTMLButtonElement).click();
    fixture.detectChanges();
    expect(host.visible()).toBe(false);
    expect(dialog()).toBeNull();
  });

  it('closes with Escape', async () => {
    const { fixture, host, dialog, show } = await render();
    await show();
    dialog()?.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }));
    fixture.detectChanges();
    expect(host.visible()).toBe(false);
  });

  it('closes when the backdrop is clicked but not when the dialog is', async () => {
    const { fixture, host, dialog, show, element } = await render();
    await show();
    dialog()?.click();
    fixture.detectChanges();
    expect(host.visible()).toBe(true);

    (element.querySelector('.as-modal__backdrop') as HTMLElement).click();
    fixture.detectChanges();
    expect(host.visible()).toBe(false);
  });

  it('locks the scroll of the page while it is open', async () => {
    const { fixture, show } = await render();
    await show();
    expect(document.body.style.overflow).toBe('hidden');
    fixture.componentInstance.visible.set(false);
    fixture.detectChanges();
    await fixture.whenStable();
    expect(document.body.style.overflow).toBe('');
  });
});
