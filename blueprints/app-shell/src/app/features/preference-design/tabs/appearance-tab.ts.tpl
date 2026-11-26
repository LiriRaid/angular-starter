import { ChangeDetectionStrategy, Component, computed, inject } from '@angular/core';
import { FormControl, ReactiveFormsModule } from '@angular/forms';

import { DesignPreferencesService } from '@core/design-preferences/design-preferences.service';
import { ENABLED_LAYOUT_MODES, LAYOUT_MODES, type LayoutMode } from '@core/design-preferences/layout-modes';
import { SaSelect } from '@shared/components';

/** La pestaña Apariencia: el layout de la aplicación. Cambia en tiempo real; "Guardar cambios" lo deja para toda la plataforma. */
@Component({
  selector: '__PREFIX__-appearance-tab',
  imports: [ReactiveFormsModule, SaSelect],
  templateUrl: './appearance-tab.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AppearanceTab {
  private readonly designPreferences = inject(DesignPreferencesService);

  /** Los habilitados del proyecto y, como "En construcción", los que todavía no se construyeron. */
  readonly layoutModes: readonly LayoutMode[] = LAYOUT_MODES.filter((mode) => !mode.built || ENABLED_LAYOUT_MODES.includes(mode.id));
  readonly activeLayout = computed(() => this.designPreferences.preferences().layout);
  /** El ancho del sidebar transparente: aún en construcción, por eso el campo está deshabilitado. */
  readonly transparentWidths = [
    { label: 'Ancho', value: 'wide' },
    { label: 'Compacto', value: 'compact' },
  ];
  readonly transparentWidth = new FormControl({ value: 'wide', disabled: true });

  choose(mode: LayoutMode): void {
    if (mode.built) this.designPreferences.set('layout', mode.id);
  }
}
