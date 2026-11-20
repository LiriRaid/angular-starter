import type { Provider } from '@angular/core';
import { provideLucideIcons, type LucideIcon, type LucideIconData } from '@lucide/angular';
import { AS_ICONS } from './icons';

/**
 * Registers the icons that `as-icon` and the starter components can show. Pass more icons (Lucide
 * components or your own icon data) to add yours without touching the list.
 */
export function provideAsIcons(...extra: Array<LucideIcon | LucideIconData>): Provider {
  return provideLucideIcons(...AS_ICONS, ...extra);
}
