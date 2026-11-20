import { EnvironmentProviders, inject, provideEnvironmentInitializer } from '@angular/core';
import { ThemeService } from './theme.service';

/** Applies the saved theme (mode and colors) when the application starts. */
export const provideThemeInitializer = (): EnvironmentProviders =>
  provideEnvironmentInitializer(() => inject(ThemeService).initialize());
