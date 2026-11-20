import { TestBed } from '@angular/core/testing';
import { provideAsIcons } from '@core/icons/icons.provider';
import { vi } from 'vitest';
import { AsPreview } from './as-preview';

describe('AsPreview', () => {
  beforeEach(() => {
    URL.createObjectURL = vi.fn(() => 'blob:preview');
    URL.revokeObjectURL = vi.fn();
  });

  function render(inputs: Record<string, unknown> = {}) {
    TestBed.configureTestingModule({ imports: [AsPreview], providers: [provideAsIcons()] });
    const fixture = TestBed.createComponent(AsPreview);
    for (const [key, value] of Object.entries(inputs)) fixture.componentRef.setInput(key, value);
    fixture.detectChanges();
    const element = fixture.nativeElement as HTMLElement;
    const choose = (file: File) => {
      const input = element.querySelector('input[type="file"]') as HTMLInputElement;
      Object.defineProperty(input, 'files', { value: [file], configurable: true });
      input.dispatchEvent(new Event('change'));
      fixture.detectChanges();
    };
    return { fixture, element, choose };
  }

  it('shows a placeholder until there is an image', () => {
    const { element } = render({ label: 'logo' });
    expect(element.querySelector('img')).toBeNull();
    expect(element.querySelector('.as-preview__frame')?.getAttribute('aria-label')).toBe('Choose logo');
  });

  it('shows the image it is given and offers to remove it', () => {
    const { fixture, element } = render({ imageUrl: '/logo.png', label: 'logo' });
    expect(element.querySelector('img')?.getAttribute('src')).toBe('/logo.png');

    let removed = 0;
    fixture.componentInstance.removed.subscribe(() => removed++);
    (element.querySelector('.as-preview__remove') as HTMLButtonElement).click();
    expect(removed).toBe(1);
  });

  it('shows the file the user picks at once and reports it', () => {
    const { fixture, element, choose } = render();
    const files: File[] = [];
    fixture.componentInstance.fileSelected.subscribe((file) => files.push(file));
    const file = new File(['x'], 'photo.png', { type: 'image/png' });
    choose(file);
    expect(files).toEqual([file]);
    expect(element.querySelector('img')?.getAttribute('src')).toBe('blob:preview');
  });

  it('cannot be changed while it is disabled', () => {
    const { element } = render({ disabled: true, imageUrl: '/logo.png' });
    expect((element.querySelector('.as-preview__frame') as HTMLButtonElement).disabled).toBe(true);
    expect(element.querySelector('.as-preview__remove')).toBeNull();
  });
});
