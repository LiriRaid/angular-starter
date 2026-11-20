import { TestBed } from '@angular/core/testing';
import { DEFAULT_PRIMARY_COLOR_KEY, PRIMARY_COLORS } from './theme-palettes';
import { ThemeService } from './theme.service';

describe('ThemeService', () => {
  const root = document.documentElement;
  let service: ThemeService;

  beforeEach(() => {
    localStorage.clear();
    root.classList.remove('dark');
    root.removeAttribute('style');
    service = TestBed.inject(ThemeService);
  });

  it('starts in light mode with the default primary color', () => {
    service.initialize();
    expect(service.mode()).toBe('light');
    expect(root.classList.contains('dark')).toBe(false);
    expect(service.primaryColorKey()).toBe(DEFAULT_PRIMARY_COLOR_KEY);
    expect(root.style.getPropertyValue('--as-primary-500')).toBe(PRIMARY_COLORS[0]?.palette['500']);
  });

  it('toggles the dark class and remembers the mode', () => {
    service.initialize();
    service.toggleMode();
    expect(service.mode()).toBe('dark');
    expect(root.classList.contains('dark')).toBe(true);

    const next = TestBed.runInInjectionContext(() => new ThemeService());
    next.initialize();
    expect(next.mode()).toBe('dark');
  });

  it('applies the primary color ramp', () => {
    service.initialize();
    service.setPrimaryColor('emerald');
    expect(service.primaryColorKey()).toBe('emerald');
    expect(root.style.getPropertyValue('--as-primary-500')).toBe('#10b981');
    expect(root.style.getPropertyValue('--as-primary-950')).toBe('#022c22');
  });

  it('applies the surface color ramp', () => {
    service.initialize();
    service.setSurfaceColor('slate');
    expect(root.style.getPropertyValue('--as-surface-900')).toBe('#0f172a');
  });

  it('falls back to the default color for an unknown key', () => {
    service.initialize();
    service.setPrimaryColor('does-not-exist');
    expect(service.primaryColorKey()).toBe(DEFAULT_PRIMARY_COLOR_KEY);
  });
});
