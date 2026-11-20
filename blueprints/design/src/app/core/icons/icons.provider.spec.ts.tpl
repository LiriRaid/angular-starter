import { TestBed } from '@angular/core/testing';
import { LUCIDE_ICONS } from '@lucide/angular';
import { AS_ICONS } from './icons';
import { provideAsIcons } from './icons.provider';

describe('provideAsIcons', () => {
  it('registers the icons of the starter, by name', () => {
    TestBed.configureTestingModule({ providers: [provideAsIcons()] });
    const icons = TestBed.inject(LUCIDE_ICONS);
    // Each icon is also registered under its aliases, so there are at least as many names as icons.
    expect(Object.keys(icons).length).toBeGreaterThanOrEqual(AS_ICONS.length);
    expect(icons['check']).toBeDefined();
    expect(icons['chevron-down']).toBeDefined();
  });
});
