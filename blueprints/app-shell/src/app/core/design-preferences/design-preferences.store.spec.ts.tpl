import { TestBed } from '@angular/core/testing';
import { DEFAULT_DESIGN_PREFERENCES } from './design-preferences.service';
import { DESIGN_PREFERENCES_STORE, MemoryDesignPreferencesStore } from './design-preferences.store';

describe('MemoryDesignPreferencesStore', () => {
  it('is the store a project has until it connects its own', () => {
    expect(TestBed.inject(DESIGN_PREFERENCES_STORE)).toBeInstanceOf(MemoryDesignPreferencesStore);
  });

  it('has nothing to load before something is saved', async () => {
    expect(await new MemoryDesignPreferencesStore().load()).toBeNull();
  });

  it('keeps what is saved, with a new version each time, only in memory', async () => {
    const store = new MemoryDesignPreferencesStore();
    const first = await store.save({ ...DEFAULT_DESIGN_PREFERENCES, radius: 'sharp' });
    const second = await store.save({ ...DEFAULT_DESIGN_PREFERENCES, radius: 'rounded' });
    expect(second.version).not.toBe(first.version);
    expect(await store.load()).toEqual(second);
    expect((await store.load())?.preferences).toMatchObject({ radius: 'rounded' });
  });

  it('lets everybody save', () => {
    expect(new MemoryDesignPreferencesStore().canSave()).toBe(true);
  });

  it('does not use the storage of the browser', async () => {
    const setItem = vi.spyOn(Storage.prototype, 'setItem');
    await new MemoryDesignPreferencesStore().save(DEFAULT_DESIGN_PREFERENCES);
    expect(setItem).not.toHaveBeenCalled();
    setItem.mockRestore();
  });
});
