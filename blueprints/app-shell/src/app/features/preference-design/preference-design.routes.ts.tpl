import { Routes } from '@angular/router';

export const PREFERENCE_DESIGN_ROUTES: Routes = [
  {
    path: '',
    loadComponent: () => import('./preference-design').then((m) => m.PreferenceDesign),
  },
];
