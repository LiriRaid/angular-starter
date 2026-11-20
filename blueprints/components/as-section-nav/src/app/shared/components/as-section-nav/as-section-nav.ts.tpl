import { ChangeDetectionStrategy, Component, computed, input, model } from '@angular/core';

import { AsIcon } from '../as-icon/as-icon';

export interface AsSectionNavItem {
  readonly id: string;
  readonly icon: string;
  readonly title: string;
  /** La pista que se dibuja a la derecha del título cuando la sección está elegida. */
  readonly summary?: string;
}

let nextSectionNavId = 0;

/** Una pantalla con un panel de botones numerados a la izquierda y, a la derecha, solo la sección elegida (`[(active)]`). Quien la usa dibuja el contenido de la sección activa; `[sectionNavAction]` va junto a la descripción del panel y `[sectionNavFooter]` en el pie, bajo una línea (Descartar / Guardar). */
@Component({
  selector: 'as-section-nav',
  imports: [AsIcon],
  templateUrl: './as-section-nav.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'flex min-w-0 flex-col gap-5 md:flex-row md:gap-6' },
})
export class AsSectionNav {
  readonly title = input.required<string>();
  readonly description = input('');
  readonly items = input.required<readonly AsSectionNavItem[]>();
  readonly active = model.required<string>();

  /** La sección elegida; si `active` no coincide con ninguna cae a la primera, y sin secciones (datos que aún no llegan) no hay ninguna. */
  readonly current = computed<AsSectionNavItem | undefined>(() => this.items().find((item) => item.id === this.active()) ?? this.items()[0]);

  protected readonly titleId = `as-section-nav-title-${nextSectionNavId++}`;
}
