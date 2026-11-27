import { signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { ThemeService } from '@core/theme/theme.service';
import { DESIGN_CHANGE_NOTIFIER, type DesignChange, type DesignChangeNotifier } from './design-change-notifier';
import { DEFAULT_DESIGN_PREFERENCES, DesignPreferencesService, LOAD_TIMEOUT_MS, type DesignPreferences } from './design-preferences.service';
import { DESIGN_PREFERENCES_STORE, type DesignPreferencesDocument, type DesignPreferencesStore } from './design-preferences.store';
import { DEFAULT_LAYOUT_MODE, ENABLED_LAYOUT_MODES, layoutTraits } from './layout-modes';

class ThemeServiceMock {
  readonly setMode = vi.fn();
  readonly applyColor = vi.fn();
  readonly applySurface = vi.fn();
}

/** A store the tests control: what it loads, what it saves and when a save finishes. */
class FakeStore implements DesignPreferencesStore {
  readonly canSave = signal(true);
  document: DesignPreferencesDocument | null = null;
  failLoad = false;
  held: (() => void) | null = null;
  holdSaves = false;
  readonly saves: DesignPreferences[] = [];
  private version = 0;

  load = vi.fn(async (): Promise<DesignPreferencesDocument | null> => {
    if (this.failLoad) throw new Error('offline');
    return this.document;
  });

  save = vi.fn(async (preferences: DesignPreferences): Promise<DesignPreferencesDocument> => {
    this.saves.push(preferences);
    const document = { version: `v${++this.version}`, preferences };
    if (this.holdSaves) await new Promise<void>((resolve) => (this.held = resolve));
    this.document = document;
    return document;
  });
}

class FakeNotifier implements DesignChangeNotifier {
  listener: ((change: DesignChange) => void) | null = null;
  connect = vi.fn((listener: (change: DesignChange) => void) => (this.listener = listener));
  disconnect = vi.fn();
  emit(version: string): void {
    this.listener?.({ version });
  }
}

describe('DesignPreferencesService', () => {
  let service: DesignPreferencesService;
  let theme: ThemeServiceMock;
  let store: FakeStore;
  let notifier: FakeNotifier;

  const create = (): void => {
    TestBed.resetTestingModule();
    theme = new ThemeServiceMock();
    store = new FakeStore();
    notifier = new FakeNotifier();
    TestBed.configureTestingModule({
      providers: [
        { provide: ThemeService, useValue: theme },
        { provide: DESIGN_PREFERENCES_STORE, useValue: store },
        { provide: DESIGN_CHANGE_NOTIFIER, useValue: notifier },
      ],
    });
    service = TestBed.inject(DesignPreferencesService);
  };

  const start = async (document: DesignPreferencesDocument | null = null): Promise<void> => {
    create();
    store.document = document;
    await service.initialize();
  };

  beforeEach(() => {
    document.documentElement.removeAttribute('style');
    document.documentElement.removeAttribute('data-animations');
    document.documentElement.removeAttribute('data-layout');
    document.documentElement.removeAttribute('data-layout-traits');
  });

  it('starts with the defaults and no pending changes', async () => {
    await start();
    expect(service.preferences()).toEqual(DEFAULT_DESIGN_PREFERENCES);
    expect(service.hasChanges()).toBe(false);
    expect(service.updateAvailable()).toBe(false);
  });

  it('applies a change in real time to the variables of the document', async () => {
    await start();
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

  it('turns the animations off and on through an attribute of the document', async () => {
    await start();
    service.set('animations', false);
    expect(document.documentElement.getAttribute('data-animations')).toBe('off');
    service.set('animations', true);
    expect(document.documentElement.getAttribute('data-animations')).toBe('on');
  });

  it('keeps a change only in memory until it is saved, and saves it through the store', async () => {
    await start();
    service.set('radius', 'rounded');
    expect(store.save).not.toHaveBeenCalled();
    await service.save();
    expect(store.saves[0].radius).toBe('rounded');
    expect(service.hasChanges()).toBe(false);
  });

  it('never touches the storage of the browser', async () => {
    const setItem = vi.spyOn(Storage.prototype, 'setItem');
    const getItem = vi.spyOn(Storage.prototype, 'getItem');
    await start();
    service.set('radius', 'rounded');
    await service.save();
    for (const spy of [setItem, getItem]) {
      expect(spy.mock.calls.filter(([key]) => String(key).includes('design-preferences'))).toEqual([]);
      spy.mockRestore();
    }
  });

  it('brings back what the store has when the application starts', async () => {
    await start({ version: 'v7', preferences: { ...DEFAULT_DESIGN_PREFERENCES, density: 'wide', showBreadcrumb: false } });
    expect(service.preferences().density).toBe('wide');
    expect(service.preferences().showBreadcrumb).toBe(false);
    expect(service.hasChanges()).toBe(false);
    expect(document.documentElement.style.getPropertyValue('--sa-ui-density-scale')).toBe('1.125');
  });

  it('ignores a document that is not valid', async () => {
    await start({ version: 'v1', preferences: { radius: 'huge', animations: 'yes', layout: 'not-a-layout' } });
    expect(service.preferences()).toEqual(DEFAULT_DESIGN_PREFERENCES);
    await start({ version: 'v1', preferences: 'not an object' });
    expect(service.preferences()).toEqual(DEFAULT_DESIGN_PREFERENCES);
  });

  it('ignores the keys of Object.prototype as values', async () => {
    await start({ version: 'v1', preferences: { radius: 'constructor', density: 'toString', layout: 'hasOwnProperty' } });
    expect(service.preferences()).toEqual(DEFAULT_DESIGN_PREFERENCES);
  });

  it('starts with the defaults when the store cannot be reached', async () => {
    create();
    store.failLoad = true;
    await service.initialize();
    expect(service.preferences()).toEqual(DEFAULT_DESIGN_PREFERENCES);
  });

  it('does not hold the application for a store that never answers', async () => {
    vi.useFakeTimers();
    try {
      create();
      store.load.mockImplementation(() => new Promise<DesignPreferencesDocument | null>(() => undefined));
      const starting = service.initialize();
      await vi.advanceTimersByTimeAsync(LOAD_TIMEOUT_MS);
      await starting;
      expect(service.preferences()).toEqual(DEFAULT_DESIGN_PREFERENCES);
    } finally {
      vi.useRealTimers();
    }
  });

  describe('layout', () => {
    it('starts in the default mode, with its traits on the document', async () => {
      await start();
      expect(service.preferences().layout).toBe(DEFAULT_LAYOUT_MODE);
      expect(service.layoutTraits()).toEqual(layoutTraits(DEFAULT_LAYOUT_MODE));
      expect(document.documentElement.getAttribute('data-layout')).toBe(DEFAULT_LAYOUT_MODE);
      expect(document.documentElement.getAttribute('data-layout-traits')).toBe('floating');
    });

    it('brings back every enabled mode from the store', async () => {
      for (const layout of ENABLED_LAYOUT_MODES) {
        await start({ version: 'v1', preferences: { ...DEFAULT_DESIGN_PREFERENCES, layout } });
        expect(service.preferences().layout).toBe(layout);
        expect(document.documentElement.getAttribute('data-layout')).toBe(layout);
      }
    });

    it('switches the traits and the document when the mode changes, with no reload', async () => {
      await start();
      for (const layout of ENABLED_LAYOUT_MODES) {
        service.set('layout', layout);
        expect(service.layoutTraits()).toEqual(layoutTraits(layout));
        const traits = Object.entries(layoutTraits(layout))
          .filter(([, on]) => on)
          .map(([name]) => name)
          .join(' ');
        expect(document.documentElement.getAttribute('data-layout')).toBe(layout);
        expect(document.documentElement.getAttribute('data-layout-traits')).toBe(traits);
      }
    });
  });

  describe('save and reset', () => {
    it('lets the store decide who saves', async () => {
      await start();
      expect(service.canSave()).toBe(true);
      store.canSave.set(false);
      expect(service.canSave()).toBe(false);
    });

    it('does not save when the store does not allow it', async () => {
      await start();
      store.canSave.set(false);
      service.set('radius', 'sharp');
      await service.save();
      expect(store.save).not.toHaveBeenCalled();
      expect(service.hasChanges()).toBe(true);
    });

    it('keeps the changes and says why when the store fails to save', async () => {
      await start();
      store.save.mockRejectedValueOnce(new Error('403'));
      service.set('radius', 'sharp');
      await service.save();
      expect(service.hasChanges()).toBe(true);
      expect(service.saveFailed()).toBe(true);
      await service.save();
      expect(service.saveFailed()).toBe(false);
    });

    it('resets to the defaults, saves them when allowed and restores the theme', async () => {
      await start();
      service.set('radius', 'sharp');
      await service.save();
      await service.reset();
      expect(service.preferences()).toEqual(DEFAULT_DESIGN_PREFERENCES);
      expect(store.saves.at(-1)).toEqual(DEFAULT_DESIGN_PREFERENCES);
      expect(service.hasChanges()).toBe(false);
      expect(theme.setMode).toHaveBeenCalledWith('light');
      expect(theme.applyColor).toHaveBeenCalled();
      expect(theme.applySurface).toHaveBeenCalled();
      expect(document.documentElement.style.getPropertyValue('--sa-ui-radius-scale')).toBe('1');
    });

    it('resets only what is on screen when the store does not allow saving', async () => {
      await start();
      store.canSave.set(false);
      service.set('radius', 'sharp');
      await service.reset();
      expect(service.preferences()).toEqual(DEFAULT_DESIGN_PREFERENCES);
      expect(store.save).not.toHaveBeenCalled();
    });
  });

  describe('a change made by someone else', () => {
    it('connects the notifier once the document is loaded', async () => {
      await start();
      expect(notifier.connect).toHaveBeenCalledTimes(1);
    });

    it('tells the user when the platform has another version of the design', async () => {
      await start({ version: 'v1', preferences: DEFAULT_DESIGN_PREFERENCES });
      notifier.emit('v1');
      expect(service.updateAvailable()).toBe(false);
      notifier.emit('v2');
      await Promise.resolve();
      expect(service.updateAvailable()).toBe(true);
    });

    it('does not announce the own save to whoever made it', async () => {
      await start();
      service.set('radius', 'sharp');
      await service.save();
      notifier.emit('v1');
      await Promise.resolve();
      expect(service.updateAvailable()).toBe(false);
    });

    it('waits for a save that is still running before comparing versions', async () => {
      await start();
      store.holdSaves = true;
      service.set('radius', 'sharp');
      const saving = service.save();
      notifier.emit('v1');
      store.held?.();
      await saving;
      await Promise.resolve();
      expect(service.updateAvailable()).toBe(false);
    });

    it('never applies the new design by itself', async () => {
      await start({ version: 'v1', preferences: DEFAULT_DESIGN_PREFERENCES });
      service.set('radius', 'sharp');
      notifier.emit('v2');
      await Promise.resolve();
      expect(service.preferences().radius).toBe('sharp');
    });

    it('disconnects the notifier when the service is destroyed', async () => {
      await start();
      TestBed.resetTestingModule();
      expect(notifier.disconnect).toHaveBeenCalled();
    });
  });
});
