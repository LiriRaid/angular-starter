import { Routes } from '@angular/router';
import { DOC_PAGES } from './docs.data';

/** One route per page of the documentation; `/docs` opens the first one. */
export const DOCS_ROUTES: Routes = [
  { path: '', redirectTo: DOC_PAGES[0].id, pathMatch: 'full' },
  ...DOC_PAGES.map((page) => ({
    path: page.id,
    data: { page: page.id },
    loadComponent: () => import('./docs').then((m) => m.Docs),
  })),
];
