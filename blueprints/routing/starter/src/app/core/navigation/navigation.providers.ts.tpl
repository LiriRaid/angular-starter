import { EnvironmentProviders, makeEnvironmentProviders } from '@angular/core';
import { TitleStrategy } from '@angular/router';
import { BreadcrumbService } from './breadcrumb.service';
import { NavigationTitleStrategy } from './navigation-title.strategy';
import { NAV_APP_NAME_TOKEN, NAV_TREE_TOKEN } from './navigation.tokens';
import type { NavigationGroup } from './navigation.types';

/** Registers the navigation tree, the page title strategy and the breadcrumb service. */
export function provideNavigation(
  tree: readonly NavigationGroup[],
  options: { appName: string },
): EnvironmentProviders {
  return makeEnvironmentProviders([
    { provide: NAV_TREE_TOKEN, useValue: tree },
    { provide: NAV_APP_NAME_TOKEN, useValue: options.appName },
    { provide: TitleStrategy, useClass: NavigationTitleStrategy },
    BreadcrumbService,
  ]);
}
