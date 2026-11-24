import { ChangeDetectionStrategy, Component, inject } from '@angular/core';

import { DesignPreferencesService, type UiButtonSize, type UiDensity, type UiFontSize, type UiRadius } from '@core/design-preferences/design-preferences.service';
import { SaButton, SaToggle } from '@shared/components';

export interface OptionGroup {
  readonly id: string;
  readonly label: string;
  readonly hint: string;
  readonly options: readonly { readonly value: string; readonly label: string }[];
  readonly current: () => string;
  readonly choose: (value: string) => void;
}

/**
 * Los tokens de UI de los componentes, en tiempo real. Es la base del UI System: cada grupo cambia una
 * variable de `design-preferences-styles.css` y la vista previa de abajo (y toda la aplicación) la sigue.
 */
@Component({
  selector: '__PREFIX__-ui-tab',
  imports: [SaButton, SaToggle],
  templateUrl: './ui-tab.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class UiTab {
  private readonly designPreferences = inject(DesignPreferencesService);

  readonly groups: readonly OptionGroup[] = [
    {
      id: 'buttonSize',
      label: 'Tamaño de botones',
      hint: 'Alto de los botones sa-button',
      options: [
        { value: 'small', label: 'Pequeño' },
        { value: 'medium', label: 'Mediano' },
        { value: 'large', label: 'Grande' },
      ],
      current: () => this.designPreferences.preferences().buttonSize,
      choose: (value) => this.designPreferences.set('buttonSize', value as UiButtonSize),
    },
    {
      id: 'radius',
      label: 'Radio de bordes',
      hint: 'Todos los rounded-* de Tailwind CSS',
      options: [
        { value: 'sharp', label: 'Recto' },
        { value: 'soft', label: 'Suave' },
        { value: 'default', label: 'Redondeado' },
        { value: 'rounded', label: 'Muy redondeado' },
      ],
      current: () => this.designPreferences.preferences().radius,
      choose: (value) => this.designPreferences.set('radius', value as UiRadius),
    },
    {
      id: 'density',
      label: 'Densidad',
      hint: 'Espaciados y tamaños de la interfaz',
      options: [
        { value: 'compact', label: 'Compacta' },
        { value: 'normal', label: 'Normal' },
        { value: 'wide', label: 'Amplia' },
      ],
      current: () => this.designPreferences.preferences().density,
      choose: (value) => this.designPreferences.set('density', value as UiDensity),
    },
    {
      id: 'fontSize',
      label: 'Tamaño de fuente',
      hint: 'Todo lo que se mide en rem',
      options: [
        { value: 'small', label: 'Pequeña' },
        { value: 'normal', label: 'Normal' },
        { value: 'large', label: 'Grande' },
      ],
      current: () => this.designPreferences.preferences().fontSize,
      choose: (value) => this.designPreferences.set('fontSize', value as UiFontSize),
    },
  ];
}
