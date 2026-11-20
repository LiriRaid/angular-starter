import { ChangeDetectionStrategy, Component, inject } from '@angular/core';

import { DesignPreferencesService } from '@core/design-preferences/design-preferences.service';
import { AsToggle } from '@shared/components';

interface ToggleItem {
  readonly id: string;
  readonly label: string;
  readonly hint: string;
  readonly value: () => boolean;
  readonly setValue: (value: boolean) => void;
}

@Component({
  selector: '__PREFIX__-other-tab',
  imports: [AsToggle],
  templateUrl: './other-tab.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OtherTab {
  private readonly designPreferences = inject(DesignPreferencesService);

  readonly toggles: readonly ToggleItem[] = [
    {
      id: 'breadcrumb',
      label: 'Mostrar breadcrumb',
      hint: 'La ruta de la página actual en el header',
      value: () => this.designPreferences.preferences().showBreadcrumb,
      setValue: (value) => this.designPreferences.set('showBreadcrumb', value),
    },
    {
      id: 'animations',
      label: 'Animaciones y transiciones',
      hint: 'Apágalas para una interfaz sin movimiento',
      value: () => this.designPreferences.preferences().animations,
      setValue: (value) => this.designPreferences.set('animations', value),
    },
  ];
}
