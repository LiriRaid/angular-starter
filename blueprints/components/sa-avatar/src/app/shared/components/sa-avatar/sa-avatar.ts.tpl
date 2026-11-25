import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';

import { SaIcon } from '../sa-icon/sa-icon';

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

export type SaAvatarMode = 'avatar' | 'presence';

/**
 * The Tailwind size of the initials for each size of avatar, as a share of it: about a third, so the larger
 * the circle the larger the letters. Each class is written out so that Tailwind finds it; below 12px there is
 * no named size, so the smallest avatars take an arbitrary one.
 */
const INITIALS_SIZES: ReadonlyArray<readonly [maxSize: number, tailwindClass: string]> = [
  [20, 'text-[8px]'],
  [24, 'text-[9px]'],
  [28, 'text-[11px]'],
  [32, 'text-xs'],
  [40, 'text-sm'],
  [48, 'text-base'],
  [56, 'text-xl'],
  [64, 'text-2xl'],
  [80, 'text-3xl'],
  [96, 'text-4xl'],
];
const LARGEST_INITIALS = 'text-5xl';

/** Share of an avatar sized in CSS (`cssSize`) that its initials take: no Tailwind class can know that size. */
const INITIALS_RATIO = 0.38;

/** A class of the consumer that already sets the size of the text (`text-sm`, `text-[9px]`, `text-caption-2-bold`). */
/** A class of the consumer that already sets the weight (`font-medium`, `text-caption-2-bold`). */
const OWN_TEXT_WEIGHT = /(^|\s)(\w+:)*(font-(thin|extralight|light|normal|medium|semibold|bold|extrabold|black)|text-[\w-]*-(bold|semibold|medium|regular))/;

/** A class of the consumer that already sets the size of the text (`text-sm`, `text-[9px]`, `text-caption-2-bold`). */
const OWN_TEXT_SIZE = /(^|\s)(\w+:)*text-(xs|sm|base|lg|[2-9]?xl|\[[\d.]+(px|rem|em)\]|caption-|body-|title-|heading-|display-)/;

@Component({
  selector: 'sa-avatar',
  standalone: true,
  imports: [SaIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './sa-avatar.html',
  styleUrl: './sa-avatar.css',
  host: {
    '[style.borderRadius]': 'radius()',
    '[style.position]': "mode() === 'presence' ? 'relative' : null",
  },
})
export class SaAvatar {
  readonly label = input<string>('');
  readonly imageUrl = input<string | null>(null);
  readonly background = input<string>('var(--app-text-subtle)');
  readonly color = input<string>('#ffffff');
  readonly size = input<number>(40);
  readonly cssSize = input<string | null>(null);
  readonly shape = input<'circle' | 'rounded'>('circle');
  /** Extra classes for the initials (a weight, a spacing). Their size comes from `size` unless a class here sets one. */
  readonly textClass = input<string>('');
  readonly alt = input<string>('');

  /** 'presence' agrega el punto de estado (online/away/busy/invisible) sobre el avatar,
   *  reemplazando el <span class="presence-dot"> que antes se repetía en cada feature. */
  readonly mode = input<SaAvatarMode>('avatar');
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
  /** The Tailwind size of the initials, by the size of the avatar; none when the consumer chose one or the size is in CSS. */
  private readonly initialsSizeClass = computed(() => {
    if (this.cssSize() || OWN_TEXT_SIZE.test(this.textClass())) return '';
    const size = this.size();
    return INITIALS_SIZES.find(([max]) => size <= max)?.[1] ?? LARGEST_INITIALS;
  });
  protected readonly initialsClass = computed(() => ['sa-avatar sa-avatar--initials', OWN_TEXT_WEIGHT.test(this.textClass()) ? '' : 'font-bold', this.initialsSizeClass(), this.textClass()].filter(Boolean).join(' '));
  /** An avatar sized in CSS has no class for its letters, so they take a share of that same size. */
  protected readonly initialsFontSize = computed(() => (this.cssSize() && !OWN_TEXT_SIZE.test(this.textClass()) ? `calc(${this.cssSize()} * ${INITIALS_RATIO})` : null));

  protected readonly resolvedDotSize = computed(() => this.dotSize() ?? (this.size() <= 40 ? '0.875rem' : '1rem'));
  protected readonly resolvedDotIconSize = computed(() => this.dotIconSize() ?? (this.size() <= 40 ? 10 : 12));
  /** El punto queda muy pegado hacia arriba en avatares chicos (40px, user-menu/Teams) con
   *  el "bottom" default compartido — se baja un poco más solo para ese bucket de tamaño. */
  protected readonly resolvedDotBottom = computed(() => (this.dotSize() ? null : this.size() <= 40 ? '-2px' : null));
  protected readonly dotIcon = computed(() => presenceStatusIcon(this.presenceStatus() ?? null));
}
