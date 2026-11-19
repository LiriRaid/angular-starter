import { InjectionToken } from '@angular/core';
import type { NavigationGroup } from './navigation.types';

/** The navigation tree. Provided by `provideNavigation`, so `core` never imports the tree itself. */
export const NAV_TREE_TOKEN = new InjectionToken<readonly NavigationGroup[]>('NAV_TREE_TOKEN');

/** Name appended to page titles. */
export const NAV_APP_NAME_TOKEN = new InjectionToken<string>('NAV_APP_NAME_TOKEN');
