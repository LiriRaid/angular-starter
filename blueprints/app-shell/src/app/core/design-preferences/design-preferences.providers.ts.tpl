import { EnvironmentProviders, inject, provideEnvironmentInitializer } from '@angular/core';
import { DesignPreferencesService } from './design-preferences.service';

/** Aplica las preferencias de diseño guardadas al arrancar, antes del primer render. */
export const provideDesignPreferences = (): EnvironmentProviders => provideEnvironmentInitializer(() => inject(DesignPreferencesService).initialize());
