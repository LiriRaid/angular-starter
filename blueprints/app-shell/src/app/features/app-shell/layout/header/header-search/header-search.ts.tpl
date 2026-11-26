import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { FormControl } from '@angular/forms';
import { Router } from '@angular/router';
import { startWith } from 'rxjs';

import { SaIcon, SaSearch } from '@shared/components';
import { LayoutService } from '../../../services/layout.service';
import { flattenNavigation, searchNavigation, type NavigationEntry } from '../../sidebar/sidebar-navigation.utils';

const MAX_RESULTS = 8;

/**
 * El buscador del header de los layouts compactos, que lo muestran en lugar del breadcrumb: busca entre las páginas de
 * la navegación (por su título o por el de la carpeta que las contiene) y lleva a la que se elige.
 */
@Component({
  selector: '__PREFIX__-header-search',
  imports: [SaIcon, SaSearch],
  templateUrl: './header-search.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class HeaderSearch {
  private readonly layoutService = inject(LayoutService);
  private readonly router = inject(Router);

  readonly control = new FormControl<string>('');
  private readonly term = toSignal(this.control.valueChanges.pipe(startWith('')), { initialValue: '' });

  protected readonly open = signal(false);
  protected readonly activeIndex = signal(0);

  protected readonly results = computed<readonly NavigationEntry[]>(() => {
    const entries = flattenNavigation(this.layoutService.getNavigationGroups(), (item) => !!item.hidden?.(item));
    return searchNavigation(entries, this.term() ?? '').slice(0, MAX_RESULTS);
  });

  protected readonly showPanel = computed(() => this.open() && (this.term() ?? '').trim().length > 0);

  constructor() {
    // A new search starts from the first result.
    this.control.valueChanges.subscribe(() => this.activeIndex.set(0));
  }

  protected go(entry: NavigationEntry): void {
    void this.router.navigateByUrl(entry.link);
    this.close();
  }

  protected close(): void {
    this.control.setValue('');
    this.open.set(false);
  }

  protected onFocusOut(event: FocusEvent): void {
    const host = event.currentTarget as HTMLElement;
    if (!host.contains(event.relatedTarget as Node | null)) this.open.set(false);
  }

  protected onKeydown(event: KeyboardEvent): void {
    const count = this.results().length;
    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault();
        this.activeIndex.update((index) => Math.min(index + 1, Math.max(count - 1, 0)));
        break;
      case 'ArrowUp':
        event.preventDefault();
        this.activeIndex.update((index) => Math.max(index - 1, 0));
        break;
      case 'Enter': {
        const entry = this.showPanel() ? this.results()[this.activeIndex()] : undefined;
        if (entry) this.go(entry);
        break;
      }
      case 'Escape':
        this.close();
        break;
    }
  }
}
