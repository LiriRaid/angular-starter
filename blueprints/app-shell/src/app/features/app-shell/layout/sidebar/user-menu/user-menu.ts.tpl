import { ChangeDetectionStrategy, Component, ViewEncapsulation, computed, inject, input, output, signal, viewChild } from '@angular/core';

import { AsAvatar, AsButton, AsIcon, AsPopover } from '@shared/components';
import { NAV_APP_NAME_TOKEN } from '@core/navigation/navigation.tokens';

@Component({
  selector: '__PREFIX__-user-menu',
  standalone: true,
  imports: [AsAvatar, AsButton, AsIcon, AsPopover],
  templateUrl: './user-menu.html',
  styleUrl: './user-menu.css',
  encapsulation: ViewEncapsulation.None,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class UserMenu {
  readonly expanded = input(true);

  readonly preferencesClick = output<void>();

  private readonly popoverRef = viewChild(AsPopover);

  readonly appName = inject(NAV_APP_NAME_TOKEN);

  readonly popoverOpen = computed(() => this.popoverRef()?.isOpen() ?? false);

  // Identidad de ejemplo: reemplázala por el usuario de la sesión cuando el proyecto tenga autenticación.
  readonly userName = signal('Usuario');
  readonly userRole = signal('Administrador');
  readonly userUsername = signal('usuario');
  readonly userInitials = computed(() => {
    const parts = this.userName().trim().split(/\s+/).filter(Boolean);
    if (parts.length === 0) return '?';
    if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  });

  openPreferences(): void {
    this.popoverRef()?.hide();
    this.preferencesClick.emit();
  }
}
