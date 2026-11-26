/** Dónde se abre un panel flotante (popover) respecto a su ancla, medido contra el contenedor visible del ancla y no contra toda la ventana: así no se mete debajo ni encima del header ni de otros bloques. */

export type PanelSide = 'top' | 'bottom' | 'left' | 'right';

export interface IPanelBounds {
  readonly top: number;
  readonly left: number;
  readonly right: number;
  readonly bottom: number;
}

const OPPOSITE: Readonly<Record<PanelSide, PanelSide>> = { top: 'bottom', bottom: 'top', left: 'right', right: 'left' };

const isStatic = (position: string): boolean => position === '' || position === 'static';

/**
 * El área donde el ancla se ve: la ventana recortada por cada contenedor con scroll que la envuelve.
 * Un ancla `fixed` no la recorta ningún ancestro, y una `absolute` solo la recortan los ancestros desde su bloque contenedor
 * (el primero con `position` distinta de `static`) hacia arriba: los scrollers sin posición entre medias no la afectan.
 */
export function visibleBounds(anchor: Element): IPanelBounds {
  const root = anchor.ownerDocument.documentElement;
  let top = 0;
  let left = 0;
  let right = root.clientWidth;
  let bottom = root.clientHeight;

  const anchorPosition = getComputedStyle(anchor).position;
  if (anchorPosition === 'fixed') return { top, left, right, bottom };
  let escapingUntilContainingBlock = anchorPosition === 'absolute';

  for (let parent = anchor.parentElement; parent; parent = parent.parentElement) {
    const { overflowX, overflowY, position } = getComputedStyle(parent);
    if (escapingUntilContainingBlock) {
      if (isStatic(position)) continue;
      escapingUntilContainingBlock = false;
    }
    if (!/(auto|scroll|overlay)/.test(overflowX + overflowY)) continue;

    const box = parent.getBoundingClientRect();
    top = Math.max(top, box.top);
    left = Math.max(left, box.left);
    right = Math.min(right, box.right);
    bottom = Math.min(bottom, box.bottom);
  }

  return { top, left, right, bottom };
}

/** El ancla ya no se ve dentro de su contenedor (salió por arriba, abajo o un costado). */
export function isOutOfBounds(anchor: IPanelBounds, bounds: IPanelBounds): boolean {
  return anchor.bottom <= bounds.top || anchor.top >= bounds.bottom || anchor.right <= bounds.left || anchor.left >= bounds.right;
}

/**
 * El scroll de un contenedor puede sacar el ancla de vista: el panel (que es `fixed`) no se queda flotando sin ancla ni pegado a la ventana, se cierra.
 * Un ancla sin tamaño (oculta o desmontada) no se mide: sigue el comportamiento de siempre en vez de cerrarse al abrir.
 */
export function isAnchorOutOfView(anchor: Element, bounds: IPanelBounds = visibleBounds(anchor)): boolean {
  const rect = anchor.getBoundingClientRect();
  if (rect.width <= 0 && rect.height <= 0) return false;
  return isOutOfBounds(rect, bounds);
}

function freeSpace(side: PanelSide, anchor: IPanelBounds, bounds: IPanelBounds, gap: number, margin: number): number {
  switch (side) {
    case 'top':
      return anchor.top - bounds.top - gap - margin;
    case 'bottom':
      return bounds.bottom - anchor.bottom - gap - margin;
    case 'left':
      return anchor.left - bounds.left - gap - margin;
    case 'right':
      return bounds.right - anchor.right - gap - margin;
  }
}

/**
 * El lado donde cabe el panel: el pedido, luego el contrario y luego los demás permitidos. Solo cuenta lo que se ve del contenedor.
 * Si no cabe en ninguno, el permitido con más espacio libre.
 */
export function resolveSide(params: { preferred: PanelSide; allowed: readonly PanelSide[]; trigger: IPanelBounds; size: { width: number; height: number }; bounds: IPanelBounds; gap?: number; margin?: number }): PanelSide {
  const { preferred, allowed, trigger, size, bounds, gap = 8, margin = 12 } = params;
  const order = [preferred, OPPOSITE[preferred], ...(preferred === 'top' || preferred === 'bottom' ? (['right', 'left'] as const) : (['bottom', 'top'] as const))].filter((side, index, all) => allowed.includes(side) && all.indexOf(side) === index);
  const candidates = order.length > 0 ? order : [...allowed];
  const needed = (side: PanelSide): number => (side === 'top' || side === 'bottom' ? size.height : size.width);

  const fitting = candidates.find((side) => freeSpace(side, trigger, bounds, gap, margin) >= needed(side));
  if (fitting) return fitting;

  return candidates.reduce((best, side) => (freeSpace(side, trigger, bounds, gap, margin) > freeSpace(best, trigger, bounds, gap, margin) ? side : best), candidates[0]);
}
