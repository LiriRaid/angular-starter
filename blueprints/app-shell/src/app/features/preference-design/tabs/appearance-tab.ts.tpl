import { ChangeDetectionStrategy, Component } from '@angular/core';
import { FormControl, ReactiveFormsModule } from '@angular/forms';

import { SaSelect } from '@shared/components';

export interface LayoutMode {
  readonly id: string;
  readonly label: string;
  readonly description: string;
  /** Solo el modo flotante ancho está construido; los demás se muestran "En construcción" (ADR-0010). */
  readonly built: boolean;
  readonly compact: boolean;
  readonly floating: boolean;
  readonly transparent: boolean;
}

/** Los modos de diseño del sidebar. Se construyen uno por uno: el que tiene `built` es el que usa la aplicación. */
export const LAYOUT_MODES: readonly LayoutMode[] = [
  { id: 'wide-joined', label: 'Sidebar ancho (unido)', description: 'Icono + texto en fila', built: false, compact: false, floating: false, transparent: false },
  { id: 'compact-joined', label: 'Sidebar compacto (unido)', description: 'Icono encima del texto', built: false, compact: true, floating: false, transparent: false },
  { id: 'floating-wide', label: 'Flotante (ancho)', description: 'Sidebar, header y contenido flotantes', built: true, compact: false, floating: true, transparent: false },
  { id: 'floating-compact', label: 'Flotante (compacto)', description: 'Compacto + paneles flotantes', built: false, compact: true, floating: true, transparent: false },
  { id: 'transparent-joined', label: 'Transparente (unido)', description: 'Sin fondo en el sidebar', built: false, compact: false, floating: false, transparent: true },
  { id: 'transparent-floating', label: 'Transparente (flotante)', description: 'Sin fondo y paneles flotantes', built: false, compact: false, floating: true, transparent: true },
];

@Component({
  selector: '__PREFIX__-appearance-tab',
  imports: [ReactiveFormsModule, SaSelect],
  templateUrl: './appearance-tab.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AppearanceTab {
  readonly layoutModes = LAYOUT_MODES;
  readonly activeLayout = LAYOUT_MODES.find((mode) => mode.built)?.id ?? '';
  /** El ancho del sidebar transparente: aún en construcción, por eso el campo está deshabilitado. */
  readonly transparentWidths = [
    { label: 'Ancho', value: 'wide' },
    { label: 'Compacto', value: 'compact' },
  ];
  readonly transparentWidth = new FormControl({ value: 'wide', disabled: true });
}
