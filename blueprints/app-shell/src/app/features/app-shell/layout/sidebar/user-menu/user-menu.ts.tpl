import { ChangeDetectionStrategy, Component, ViewEncapsulation, computed, inject, input, signal, viewChild } from '@angular/core';
import { Router } from '@angular/router';

import { SaAvatar, SaButton, SaIcon, SaPopover } from '@shared/components';
import { NAV_APP_NAME_TOKEN } from '@core/navigation/navigation.tokens';

@Component({
  selector: '__PREFIX__-user-menu',
  standalone: true,
  imports: [SaAvatar, SaButton, SaIcon, SaPopover],
  templateUrl: './user-menu.html',
  styleUrl: './user-menu.css',
  encapsulation: ViewEncapsulation.None,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class UserMenu {
  readonly expanded = input(true);

  private readonly router = inject(Router);

  private readonly popoverRef = viewChild(SaPopover);

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

  /** Las preferencias de diseño son una página (ADR-0010), no un drawer. */
  openPreferences(): void {
    this.popoverRef()?.hide();
    void this.router.navigateByUrl('/preference-design');
  }
}
