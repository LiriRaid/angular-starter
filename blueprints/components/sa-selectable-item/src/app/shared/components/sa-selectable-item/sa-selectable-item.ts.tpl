import { ChangeDetectionStrategy, Component, input, output } from '@angular/core';

import { AsIcon } from '../as-icon/as-icon';

/** Tarjeta de una sola línea (título + subtítulo + check si está elegida) para elegir un elemento de una lista, por ejemplo una conexión o un número. Extraída porque el mismo patrón se repetía igual en distintos modales. */
@Component({
  selector: 'as-selectable-item',
  imports: [AsIcon],
  templateUrl: './as-selectable-item.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AsSelectableItem {
  readonly title = input.required<string>();
  readonly subtitle = input<string>('');
  readonly selected = input<boolean>(false);
  /** Baja la opacidad (ej. un elemento que no aplica al contexto actual) sin impedir que se elija. */
  readonly dimmed = input<boolean>(false);
  /** Color del borde y del check cuando está elegida (ej. el verde de una plataforma). */
  readonly accentColor = input<string>('var(--as-primary-color)');

  readonly itemClick = output<void>();
}
