import { Routes } from '@angular/router';

export const SETTINGS_ROUTES: Routes = [
  {
    path: '',
    loadComponent: () => import('./settings').then((m) => m.Settings),
    children: [
      { path: '', pathMatch: 'full', redirectTo: 'general' },
      {
        path: 'general',
        loadComponent: () => import('./general/settings-general').then((m) => m.SettingsGeneral),
      },
      {
        path: 'notifications',
        loadComponent: () => import('./notifications/settings-notifications').then((m) => m.SettingsNotifications),
      },
    ],
  },
];
