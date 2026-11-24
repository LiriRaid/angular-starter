import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';

import { DesignPreferencesService } from '@core/design-preferences/design-preferences.service';
import { SaButton, SaTabs, type SaTab } from '@shared/components';
import { AppearanceTab } from './tabs/appearance-tab';
import { OtherTab } from './tabs/other-tab';
import { ThemeTab } from './tabs/theme-tab';
import { UiTab } from './tabs/ui-tab';

/**
 * Preferencias de diseño (ADR-0010): una página, no un drawer. Cada pestaña cambia el diseño en
 * tiempo real; "Guardar cambios" lo conserva al recargar y "Restablecer" vuelve a los valores de fábrica.
 */
@Component({
  selector: '__PREFIX__-preference-design',
  imports: [SaButton, SaTabs, AppearanceTab, ThemeTab, UiTab, OtherTab],
  templateUrl: './preference-design.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class PreferenceDesign {
  readonly designPreferences = inject(DesignPreferencesService);

  readonly tabs: readonly SaTab[] = [
    { id: 'appearance', label: 'Apariencia' },
    { id: 'theme', label: 'Tema' },
    { id: 'ui', label: 'UI' },
    { id: 'other', label: 'Otros' },
  ];

  readonly activeTab = signal('appearance');

  save(): void {
    this.designPreferences.save();
  }

  reset(): void {
    this.designPreferences.reset();
  }
}
