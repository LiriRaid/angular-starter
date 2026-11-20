import { ChangeDetectionStrategy, Component, inject, signal, ViewEncapsulation } from '@angular/core';

import { AsDrawer, AsIcon, AsTabs, AsToggle, type AsTab } from '@shared/components';
import { NAV_APP_NAME_TOKEN } from '@core/navigation/navigation.tokens';

type UserInfoItem = {
  readonly label: string;
  readonly value: string;
};

type UserPreferenceItem = {
  readonly id: string;
  readonly icon: string;
  readonly label: string;
  readonly value: () => boolean;
  readonly setValue: (value: boolean) => void;
};

type UserPreferenceSection = {
  readonly id: string;
  readonly label: string;
  readonly items: readonly UserPreferenceItem[];
};

@Component({
  selector: '__PREFIX__-user-preferences',
  standalone: true,
  imports: [AsIcon, AsTabs, AsToggle, AsDrawer],
  templateUrl: './user-preferences.html',
  styleUrl: './user-preferences.css',
  encapsulation: ViewEncapsulation.None,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class UserPreferences {
  readonly visible = signal(false);

  open(): void {
    this.visible.set(true);
  }

  close(): void {
    this.visible.set(false);
  }

  readonly tabs: readonly AsTab[] = [
    { id: 'info', label: 'Información' },
    { id: 'prefs', label: 'Preferencias' },
    { id: 'activity', label: 'Actividad' },
  ];

  readonly activeTab = signal('info');

  readonly prefNotifications = signal(true);
  readonly prefSound = signal(true);
  readonly prefDownloads = signal(false);
  readonly prefNewsletter = signal(false);

  // Datos de ejemplo: reemplázalos por los del usuario de la sesión cuando el proyecto tenga autenticación.
  readonly infoItems: readonly UserInfoItem[] = [
    { label: 'Nombre', value: 'Usuario' },
    { label: 'Correo', value: 'usuario@ejemplo.com' },
    { label: 'Rol', value: 'Administrador' },
    { label: 'Organización', value: inject(NAV_APP_NAME_TOKEN) },
  ];

  readonly preferenceSections: readonly UserPreferenceSection[] = [
    {
      id: 'notifications',
      label: 'Notificaciones',
      items: [
        {
          id: 'pref-notifications',
          icon: 'Bell',
          label: 'Notificaciones en tiempo real',
          value: () => this.prefNotifications(),
          setValue: (value) => this.prefNotifications.set(value),
        },
        {
          id: 'pref-sound',
          icon: 'Volume2',
          label: 'Sonidos de la aplicación',
          value: () => this.prefSound(),
          setValue: (value) => this.prefSound.set(value),
        },
      ],
    },
    {
      id: 'general',
      label: 'General',
      items: [
        {
          id: 'pref-downloads',
          icon: 'Download',
          label: 'Guardar descargas automáticamente',
          value: () => this.prefDownloads(),
          setValue: (value) => this.prefDownloads.set(value),
        },
        {
          id: 'pref-newsletter',
          icon: 'Email',
          label: 'Resumen semanal por correo',
          value: () => this.prefNewsletter(),
          setValue: (value) => this.prefNewsletter.set(value),
        },
      ],
    },
  ];
}
