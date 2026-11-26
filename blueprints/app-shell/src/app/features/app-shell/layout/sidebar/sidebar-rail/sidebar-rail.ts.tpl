import { ChangeDetectionStrategy, Component, DestroyRef, ElementRef, computed, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { NavigationEnd, Router } from '@angular/router';
import { filter } from 'rxjs';

import { NAV_APP_NAME_TOKEN } from '@core/navigation/navigation.tokens';
import { NavigationItem } from '@core/navigation/navigation.types';
import { SaIcon } from '@shared/components';
import { LayoutService } from '../../../services/layout.service';
import { isNavigationItemActive, normalizeSidebarUrl } from '../sidebar-navigation.utils';

interface SubnavEntry {
  readonly id: string;
  readonly title: string;
  readonly link?: string;
  readonly depth: number;
}

/**
 * El sidebar de los layouts compactos: solo el logo y cada página con el icono encima del texto. El menú de usuario
 * está en el header.
 * Una carpeta abre al lado una navegación pequeña con lo que contiene.
 */
@Component({
  selector: '__PREFIX__-sidebar-rail',
  imports: [SaIcon],
  templateUrl: './sidebar-rail.html',
  styleUrl: './sidebar-rail.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    '(document:click)': 'onDocumentClick($event)',
    '(document:keydown.escape)': 'closeSubnav()',
  },
})
export class SidebarRail {
  readonly brandInitial = (Array.from(inject(NAV_APP_NAME_TOKEN).trim())[0] ?? '').toUpperCase();

  private readonly layoutService = inject(LayoutService);
  private readonly router = inject(Router);
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);

  readonly currentUrl = signal(normalizeSidebarUrl(this.router.url));

  /** Las páginas y carpetas del primer nivel, sin los títulos de los grupos: no caben en el rail. */
  readonly items = computed<readonly NavigationItem[]>(() => this.layoutService.getNavigationGroups().flatMap((group) => group.items.filter((item) => !this.isHidden(item))));

  protected readonly openItemId = signal<string | null>(null);
  protected readonly subnavTop = signal(0);
  protected readonly subnavLeft = signal(0);

  protected readonly openItem = computed(() => this.items().find((item) => item.id === this.openItemId()) ?? null);

  protected readonly subnavEntries = computed<readonly SubnavEntry[]>(() => {
    const entries: SubnavEntry[] = [];
    const visit = (items: readonly NavigationItem[], depth: number): void => {
      for (const item of items) {
        if (this.isHidden(item)) continue;
        entries.push({ id: item.id, title: item.title, link: item.link, depth });
        visit(item.children ?? [], depth + 1);
      }
    };
    visit(this.openItem()?.children ?? [], 0);
    return entries;
  });

  constructor() {
    this.router.events
      .pipe(
        filter((event): event is NavigationEnd => event instanceof NavigationEnd),
        takeUntilDestroyed(inject(DestroyRef)),
      )
      .subscribe((event) => {
        this.currentUrl.set(normalizeSidebarUrl(event.urlAfterRedirects));
        this.closeSubnav();
      });
  }

  protected isActive(item: NavigationItem): boolean {
    return isNavigationItemActive(item, this.currentUrl());
  }

  protected isFolder(item: NavigationItem): boolean {
    return !!item.children?.length;
  }

  protected select(item: NavigationItem, event: Event): void {
    if (this.isFolder(item)) {
      if (this.openItemId() === item.id) {
        this.closeSubnav();
        return;
      }
      const rail = this.host.nativeElement.getBoundingClientRect();
      const button = (event.currentTarget as HTMLElement).getBoundingClientRect();
      this.subnavLeft.set(rail.right);
      this.subnavTop.set(button.top);
      this.openItemId.set(item.id);
      return;
    }
    if (item.link) void this.router.navigateByUrl(item.link);
    this.closeSubnav();
  }

  protected goTo(link: string): void {
    void this.router.navigateByUrl(link);
    this.closeSubnav();
  }

  protected closeSubnav(): void {
    this.openItemId.set(null);
  }

  protected onDocumentClick(event: MouseEvent): void {
    if (this.openItemId() !== null && !this.host.nativeElement.contains(event.target as Node)) this.closeSubnav();
  }

  private isHidden(item: NavigationItem): boolean {
    return !!item.hidden?.(item);
  }
}
