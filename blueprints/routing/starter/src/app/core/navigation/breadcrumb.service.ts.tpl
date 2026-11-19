import { Injectable, computed, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { NavigationEnd, Router } from '@angular/router';
import { filter } from 'rxjs';
import type { BreadcrumbItem, DynamicBreadcrumb } from './breadcrumb.types';
import { NAV_TREE_TOKEN } from './navigation.tokens';
import { buildBreadcrumbs } from './navigation.utils';

/**
 * Breadcrumbs of the current URL, built from the navigation tree. A detail page can add a last crumb
 * (for example the name of the record) once it has its data; the crumb is cleared on every navigation.
 */
@Injectable()
export class BreadcrumbService {
  private readonly router = inject(Router);
  private readonly tree = inject(NAV_TREE_TOKEN);
  private readonly url = signal(this.router.url);
  private readonly dynamic = signal<DynamicBreadcrumb | null>(null);

  readonly breadcrumbs = computed<BreadcrumbItem[]>(() =>
    buildBreadcrumbs(this.tree, this.url(), this.dynamic()),
  );

  constructor() {
    this.router.events
      .pipe(
        filter((event): event is NavigationEnd => event instanceof NavigationEnd),
        takeUntilDestroyed(),
      )
      .subscribe((event) => {
        this.dynamic.set(null);
        this.url.set(event.urlAfterRedirects);
      });
  }

  setDynamicLabel(label: string): void {
    this.dynamic.set({ label });
  }

  setDynamicCrumb(crumb: DynamicBreadcrumb): void {
    this.dynamic.set(crumb);
  }

  clearDynamicLabel(): void {
    this.dynamic.set(null);
  }
}
