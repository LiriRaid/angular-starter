import { EnvironmentProviders, inject, makeEnvironmentProviders, provideAppInitializer } from '@angular/core';
import { DESIGN_CHANGE_NOTIFIER, type DesignChangeNotifier } from './design-change-notifier';
import { DesignPreferencesService } from './design-preferences.service';
import { DESIGN_PREFERENCES_STORE, type DesignPreferencesStore } from './design-preferences.store';

export interface DesignPreferencesOptions {
  /** Where the design of the platform lives. It runs in an injection context, so it can `inject(HttpClient)`. Default: in memory. */
  readonly store?: () => DesignPreferencesStore;
  /** How the users who are online are told that the design changed. Default: nobody, they see it on the next reload. */
  readonly notifier?: () => DesignChangeNotifier;
}

/** Loads the design of the platform before the first render and applies it (ADR-0029). */
export const provideDesignPreferences = (options: DesignPreferencesOptions = {}): EnvironmentProviders =>
  makeEnvironmentProviders([
    ...(options.store ? [{ provide: DESIGN_PREFERENCES_STORE, useFactory: options.store }] : []),
    ...(options.notifier ? [{ provide: DESIGN_CHANGE_NOTIFIER, useFactory: options.notifier }] : []),
    provideAppInitializer(() => inject(DesignPreferencesService).initialize()),
  ]);
