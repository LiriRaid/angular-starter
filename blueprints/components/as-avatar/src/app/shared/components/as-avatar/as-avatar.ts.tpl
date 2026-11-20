import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';

import { AsIcon } from '../as-icon/as-icon';

/** Icon drawn in the presence dot for each status; `online` has none. */
const PRESENCE_STATUS_ICONS: Readonly<Record<string, string | null>> = {
  online: null,
  away: 'Moon',
  busy: 'CircleMinus',
  invisible: 'CircleDot',
};

function presenceStatusIcon(status: string | null | undefined): string | null {
  return PRESENCE_STATUS_ICONS[status ?? ''] ?? null;
}

export type AsAvatarMode = 'avatar' | 'presence';

@Component({
  selector: 'as-avatar',
  standalone: true,
  imports: [AsIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './as-avatar.html',
  styleUrl: './as-avatar.css',
  host: {
    '[style.borderRadius]': 'radius()',
    '[style.position]': "mode() === 'presence' ? 'relative' : null",
  },
})
export class AsAvatar {
  readonly label = input<string>('');
  readonly imageUrl = input<string | null>(null);
  readonly background = input<string>('var(--app-text-subtle)');
  readonly color = input<string>('#ffffff');
  readonly size = input<number>(40);
  readonly cssSize = input<string | null>(null);
  readonly shape = input<'circle' | 'rounded'>('circle');
  readonly textClass = input<string>('text-caption-1-bold');
  readonly alt = input<string>('');

  /** 'presence' agrega el punto de estado (online/away/busy/invisible) sobre el avatar,
   *  reemplazando el <span class="presence-dot"> que antes se repetía en cada feature. */
  readonly mode = input<AsAvatarMode>('avatar');
  readonly presenceStatus = input<string | null | undefined>(undefined);
  /** Overrides manuales — si no se definen, el tamaño del punto se calcula en base a size(). */
  readonly dotSize = input<string | null>(null);
  readonly dotIconSize = input<number | null>(null);
  /** El "anillo" del punto normalmente combina con el fondo del panel — algunos contextos
   *  (sidebar, overlay de un popover, panel muted) necesitan un color distinto para no dejar un cuadro visible. */
  readonly dotBackground = input<string | null>(null);

  protected readonly sizeValue = computed(() => this.cssSize() ?? `${this.size()}px`);

  protected readonly radius = computed(() => {
    if (this.shape() === 'circle') return '9999px';
    return this.cssSize() ? '28%' : `${Math.round(this.size() * 0.28)}px`;
  });
  protected readonly initialsClass = computed(() => `as-avatar as-avatar--initials ${this.textClass()}`);

  protected readonly resolvedDotSize = computed(() => this.dotSize() ?? (this.size() <= 40 ? '0.875rem' : '1rem'));
  protected readonly resolvedDotIconSize = computed(() => this.dotIconSize() ?? (this.size() <= 40 ? 10 : 12));
  /** El punto queda muy pegado hacia arriba en avatares chicos (40px, user-menu/Teams) con
   *  el "bottom" default compartido — se baja un poco más solo para ese bucket de tamaño. */
  protected readonly resolvedDotBottom = computed(() => (this.dotSize() ? null : this.size() <= 40 ? '-2px' : null));
  protected readonly dotIcon = computed(() => presenceStatusIcon(this.presenceStatus() ?? null));
}
