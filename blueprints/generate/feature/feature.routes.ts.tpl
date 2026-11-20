import { Routes } from '@angular/router';

export const __ROUTES_CONST__: Routes = [
  {
    path: '',
    loadComponent: () => import('./__NAME__').then((m) => m.__CLASS__),
  },
];
