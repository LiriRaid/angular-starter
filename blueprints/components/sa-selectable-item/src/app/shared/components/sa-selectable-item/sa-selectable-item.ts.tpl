import { ChangeDetectionStrategy, Component, input, output } from '@angular/core';

import { SaIcon } from '../sa-icon/sa-icon';

/** Tarjeta de una sola línea (título + subtítulo + check si está elegida) para elegir un elemento de una lista, por ejemplo una conexión o un número. Extraída porque el mismo patrón se repetía igual en distintos modales. */
@Component({
  selector: 'sa-selectable-item',
  imports: [SaIcon],
  templateUrl: './sa-selectable-item.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SaSelectableItem {
  readonly title = input.required<string>();
  readonly subtitle = input<string>('');
  readonly selected = input<boolean>(false);
  /** Baja la opacidad (ej. un elemento que no aplica al contexto actual) sin impedir que se elija. */
  readonly dimmed = input<boolean>(false);
  /** Color del borde y del check cuando está elegida (ej. el verde de una plataforma). */
  readonly accentColor = input<string>('var(--sa-primary-color)');

  readonly itemClick = output<void>();
}
