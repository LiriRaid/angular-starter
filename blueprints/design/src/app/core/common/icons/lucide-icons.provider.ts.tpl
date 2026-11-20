import { InjectionToken } from '@angular/core';
import { LucideIcons } from './lucide-icons';

/**
 * Token de inyección para el mapeo de iconos Lucide de As.
 */
export const AS_LUCIDE_ICONS = new InjectionToken<typeof LucideIcons>('AS_LUCIDE_ICONS', {
  providedIn: 'root',
  factory: () => LucideIcons,
});
