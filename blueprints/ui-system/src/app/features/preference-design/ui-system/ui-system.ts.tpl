import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';

import { AsAvatar, AsButton, AsCheckbox, AsDivider, AsDrawer, AsIcon, AsInput, AsModal, AsPopover, AsSelect, AsSkeleton, AsTabs, AsTextarea, AsToggle, AsTooltip, type AsTab } from '@shared/components';
import { AlertService } from '@shared/services';
import { UI_COMPONENTS } from './ui-system.catalog';

/**
 * El UI System (ADR-0010): el catálogo de los componentes `as-` instalados, cada uno con su vista
 * previa viva, el código para usarlo y los tokens de la pestaña UI que lo cambian. Se ve en la pestaña
 * UI de las preferencias de diseño; al mover un token, todas las vistas previas lo siguen.
 */
@Component({
  selector: '__PREFIX__-ui-system',
  imports: [AsAvatar, AsButton, AsCheckbox, AsDivider, AsDrawer, AsIcon, AsInput, AsModal, AsPopover, AsSelect, AsSkeleton, AsTabs, AsTextarea, AsToggle, AsTooltip],
  templateUrl: './ui-system.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class UiSystem {
  private readonly alertService = inject(AlertService);

  readonly components = UI_COMPONENTS;

  /** Lo que se escribe en el buscador. */
  readonly query = signal('');
  /** Los componentes cuya vista previa está oculta. */
  private readonly hidden = signal<ReadonlySet<string>>(new Set());

  readonly filtered = computed(() => {
    const text = this.query().trim().toLowerCase();
    if (!text) return this.components;
    return this.components.filter((entry) => `${entry.label} ${entry.selector} ${entry.description}`.toLowerCase().includes(text));
  });

  // Datos de las vistas previas.
  readonly modalOpen = signal(false);
  readonly drawerOpen = signal(false);
  readonly tabs: readonly AsTab[] = [
    { id: 'one', label: 'Uno' },
    { id: 'two', label: 'Dos' },
    { id: 'three', label: 'Tres' },
  ];
  readonly activeTab = signal('one');
  readonly plans = [
    { label: 'Básico', value: 'basic' },
    { label: 'Pro', value: 'pro' },
    { label: 'Empresa', value: 'enterprise' },
  ];

  isShown(id: string): boolean {
    return !this.hidden().has(id);
  }

  setShown(id: string, shown: boolean): void {
    this.hidden.update((current) => {
      const next = new Set(current);
      if (shown) next.delete(id);
      else next.add(id);
      return next;
    });
  }

  showToast(): void {
    this.alertService.showSuccess('Guardado', 'Este es un toast de ejemplo.');
  }
}
