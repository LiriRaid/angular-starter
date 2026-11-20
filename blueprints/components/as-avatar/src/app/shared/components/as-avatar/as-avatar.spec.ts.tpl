import { TestBed } from '@angular/core/testing';
import { AsAvatar } from './as-avatar';

describe('AsAvatar', () => {
  function render(inputs: Record<string, unknown>) {
    TestBed.configureTestingModule({ imports: [AsAvatar] });
    const fixture = TestBed.createComponent(AsAvatar);
    for (const [key, value] of Object.entries(inputs)) fixture.componentRef.setInput(key, value);
    fixture.detectChanges();
    return { fixture, element: fixture.nativeElement as HTMLElement };
  }

  it('shows the initials of the name when there is no picture', () => {
    const { element } = render({ name: 'Ada Lovelace' });
    expect(element.querySelector('.as-avatar__initials')?.textContent).toBe('AL');
    expect(element.querySelector('img')).toBeNull();
  });

  it('shows the picture when it has one', () => {
    const { element } = render({ name: 'Ada Lovelace', src: '/ada.png' });
    expect(element.querySelector('img')?.getAttribute('src')).toBe('/ada.png');
  });

  it('falls back to the initials when the picture fails to load', () => {
    const { fixture, element } = render({ name: 'Ada Lovelace', src: '/broken.png' });
    element.querySelector('img')?.dispatchEvent(new Event('error'));
    fixture.detectChanges();
    expect(element.querySelector('img')).toBeNull();
    expect(element.querySelector('.as-avatar__initials')?.textContent).toBe('AL');
  });

  it('is an image with the name as its accessible name', () => {
    const { element } = render({ name: 'Ada Lovelace' });
    expect(element.getAttribute('role')).toBe('img');
    expect(element.getAttribute('aria-label')).toBe('Ada Lovelace');
  });

  it('gives the same name the same color', () => {
    const first = render({ name: 'Ada' }).element.style.getPropertyValue('--as-avatar-hue');
    TestBed.resetTestingModule();
    const second = render({ name: 'Ada' }).element.style.getPropertyValue('--as-avatar-hue');
    expect(first).toBe(second);
  });

  it('shows a status dot', () => {
    const { element } = render({ name: 'Ada', status: 'online' });
    expect(element.querySelector('.as-avatar__status')?.getAttribute('data-status')).toBe('online');
  });
});
