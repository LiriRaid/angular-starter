import { TestBed } from '@angular/core/testing';
import { ThemeService } from '@core/theme/theme.service';
import { DEFAULT_DESIGN_PREFERENCES, DesignPreferencesService } from './design-preferences.service';

const STORAGE_KEY = '__PROJECT_NAME__:design-preferences';

class ThemeServiceMock {
  readonly setMode = vi.fn();
  readonly applyColor = vi.fn();
  readonly applySurface = vi.fn();
}

describe('DesignPreferencesService', () => {
  let service: DesignPreferencesService;
  let theme: ThemeServiceMock;

  const create = (): void => {
    theme = new ThemeServiceMock();
    TestBed.configureTestingModule({ providers: [{ provide: ThemeService, useValue: theme }] });
    service = TestBed.inject(DesignPreferencesService);
  };

  beforeEach(() => {
    localStorage.removeItem(STORAGE_KEY);
    document.documentElement.removeAttribute('style');
    document.documentElement.removeAttribute('data-animations');
  });

  it('starts with the defaults and no pending changes', () => {
    create();
    service.initialize();
    expect(service.preferences()).toEqual(DEFAULT_DESIGN_PREFERENCES);
    expect(service.hasChanges()).toBe(false);
  });

  it('applies a change in real time to the variables of the document', () => {
    create();
    service.initialize();
    service.set('radius', 'sharp');
    service.set('density', 'compact');
    service.set('fontSize', 'large');
    service.set('buttonSize', 'small');
    const style = document.documentElement.style;
    expect(style.getPropertyValue('--sa-ui-radius-scale')).toBe('0.25');
    expect(style.getPropertyValue('--sa-ui-density-scale')).toBe('0.875');
    expect(style.getPropertyValue('--sa-ui-font-scale')).toBe('1.125');
    expect(style.getPropertyValue('--sa-ui-button-scale')).toBe('0.9');
    expect(service.hasChanges()).toBe(true);
  });

  it('turns the animations off and on through an attribute of the document', () => {
    create();
    service.initialize();
    service.set('animations', false);
    expect(document.documentElement.getAttribute('data-animations')).toBe('off');
    service.set('animations', true);
    expect(document.documentElement.getAttribute('data-animations')).toBe('on');
  });

  it('keeps a change only in memory until it is saved', () => {
    create();
    service.initialize();
    service.set('radius', 'rounded');
    expect(localStorage.getItem(STORAGE_KEY)).toBeNull();
    service.save();
    expect(JSON.parse(localStorage.getItem(STORAGE_KEY) ?? '{}').radius).toBe('rounded');
    expect(service.hasChanges()).toBe(false);
  });

  it('brings back what was saved when the application starts again', () => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify({ ...DEFAULT_DESIGN_PREFERENCES, density: 'wide', showBreadcrumb: false }));
    create();
    service.initialize();
    expect(service.preferences().density).toBe('wide');
    expect(service.preferences().showBreadcrumb).toBe(false);
    expect(document.documentElement.style.getPropertyValue('--sa-ui-density-scale')).toBe('1.125');
  });

  it('ignores a saved entry that is not valid', () => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify({ radius: 'huge', animations: 'yes' }));
    create();
    service.initialize();
    expect(service.preferences()).toEqual(DEFAULT_DESIGN_PREFERENCES);
    localStorage.setItem(STORAGE_KEY, '{not json');
    service.initialize();
    expect(service.preferences()).toEqual(DEFAULT_DESIGN_PREFERENCES);
  });

  it('ignores the keys of Object.prototype as values', () => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify({ radius: 'constructor', density: 'toString' }));
    create();
    service.initialize();
    expect(service.preferences()).toEqual(DEFAULT_DESIGN_PREFERENCES);
  });

  it('resets to the defaults, clears what was saved and restores the theme', () => {
    create();
    service.initialize();
    service.set('radius', 'sharp');
    service.save();
    service.reset();
    expect(service.preferences()).toEqual(DEFAULT_DESIGN_PREFERENCES);
    expect(localStorage.getItem(STORAGE_KEY)).toBeNull();
    expect(service.hasChanges()).toBe(false);
    expect(theme.setMode).toHaveBeenCalledWith('light');
    expect(theme.applyColor).toHaveBeenCalled();
    expect(theme.applySurface).toHaveBeenCalled();
    expect(document.documentElement.style.getPropertyValue('--sa-ui-radius-scale')).toBe('1');
  });
});
