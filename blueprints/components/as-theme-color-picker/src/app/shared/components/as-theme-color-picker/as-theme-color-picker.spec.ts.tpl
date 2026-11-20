import { TestBed } from '@angular/core/testing';
import { provideAsIcons } from '@core/icons/icons.provider';
import { ThemeService } from '@core/theme/theme.service';
import { AsThemeColorPicker } from './as-theme-color-picker';

describe('AsThemeColorPicker', () => {
  function render() {
    localStorage.clear();
    document.documentElement.classList.remove('dark');
    TestBed.configureTestingModule({ imports: [AsThemeColorPicker], providers: [provideAsIcons()] });
    const theme = TestBed.inject(ThemeService);
    theme.initialize();
    const fixture = TestBed.createComponent(AsThemeColorPicker);
    fixture.detectChanges();
    const element = fixture.nativeElement as HTMLElement;
    const open = () => {
      (element.querySelector('.as-theme-picker__trigger') as HTMLButtonElement).click();
      fixture.detectChanges();
    };
    return { fixture, theme, element, open };
  }

  it('is closed until its button is pressed', () => {
    const { element, open } = render();
    expect(element.querySelector('.as-theme-picker')).toBeNull();
    open();
    expect(element.querySelector('.as-theme-picker')).not.toBeNull();
  });

  it('switches between light and dark mode', () => {
    const { fixture, theme, element, open } = render();
    open();
    const modes = element.querySelectorAll<HTMLButtonElement>('.as-theme-picker__mode');
    modes[1]?.click();
    fixture.detectChanges();
    expect(theme.mode()).toBe('dark');
    expect(modes[1]?.getAttribute('aria-pressed')).toBe('true');

    modes[0]?.click();
    expect(theme.mode()).toBe('light');
  });

  it('applies the accent and surface colors that are picked', () => {
    const { fixture, theme, element, open } = render();
    open();
    const [accent, surface] = Array.from(element.querySelectorAll('.as-theme-picker__swatches')) as HTMLElement[];
    (accent?.querySelector('[aria-label="Emerald"]') as HTMLButtonElement).click();
    (surface?.querySelector('[aria-label="Slate"]') as HTMLButtonElement).click();
    fixture.detectChanges();
    expect(theme.primaryColorKey()).toBe('emerald');
    expect(theme.surfaceColorKey()).toBe('slate');
    expect(accent?.querySelector('[aria-label="Emerald"]')?.getAttribute('aria-pressed')).toBe('true');
  });
});
