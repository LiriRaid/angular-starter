import { resolveSide, type IPanelBounds } from '@shared/utils/panel-placement';
import type { SaPopoverPosition, PopoverPanelLayout, SubPanelAnchor } from './sa-popover.entity';

type PopoverPositionConfig = {
  viewportMargin: number;
  panelGap: number;
  arrowMinOffset: number;
  arrowOffsetX: number;
  offsetX: number;
  offsetY: number;
};

type PopoverPositionParams = {
  placement: SaPopoverPosition;
  triggerRect: DOMRect;
  panelWidth: number;
  panelHeight: number;
  viewportWidth: number;
  viewportHeight: number;
};

/**
 * Con `bounds` (el área donde el ancla se ve: la ventana recortada por sus contenedores con scroll) el espacio se mide contra ese
 * área y no contra toda la ventana, así el panel no se mete bajo un header ni fuera de una lista con scroll. Sigue eligiendo solo
 * entre el lado pedido y su opuesto; si ninguno cabe, el que tiene más espacio libre. Sin `bounds` se mide contra la ventana.
 */
export function resolvePopoverPlacement(preferred: SaPopoverPosition, triggerRect: DOMRect, panelWidth: number, panelHeight: number, viewportWidth: number, viewportHeight: number, config: Pick<PopoverPositionConfig, 'viewportMargin' | 'panelGap'>, bounds?: IPanelBounds): SaPopoverPosition {
  const opposite = getOppositePopoverPosition(preferred);

  if (bounds) {
    return resolveSide({ preferred, allowed: [preferred, opposite], trigger: triggerRect, size: { width: panelWidth, height: panelHeight }, bounds, gap: config.panelGap, margin: config.viewportMargin });
  }

  if (hasPopoverSpace(preferred, triggerRect, panelWidth, panelHeight, viewportWidth, viewportHeight, config)) {
    return preferred;
  }

  return hasPopoverSpace(opposite, triggerRect, panelWidth, panelHeight, viewportWidth, viewportHeight, config) ? opposite : preferred;
}

export function getPopoverPanelLayout(params: PopoverPositionParams, config: PopoverPositionConfig): PopoverPanelLayout {
  const triggerCenterX = params.triggerRect.left + params.triggerRect.width / 2;
  const triggerCenterY = params.triggerRect.top + params.triggerRect.height / 2;

  switch (params.placement) {
    case 'bottom':
      return getVerticalPanelLayout(params, config, triggerCenterX, 'bottom');
    case 'left':
      return getHorizontalPanelLayout(params, config, triggerCenterY, 'left');
    case 'right':
      return getHorizontalPanelLayout(params, config, triggerCenterY, 'right');
    case 'top':
    default:
      return getVerticalPanelLayout(params, config, triggerCenterX, 'top');
  }
}

export function getPopoverSubPanelAnchor(position: SaPopoverPosition, panelRect: DOMRect, anchorRect: DOMRect, viewportWidth: number, viewportHeight: number, gap: number): SubPanelAnchor {
  const bottom = viewportHeight - panelRect.bottom;
  const direction = resolveSubPanelDirection(position, panelRect, viewportWidth);

  return direction === 'left' ? { bottom, right: viewportWidth - anchorRect.left + gap } : { bottom, left: anchorRect.right + gap };
}

function getVerticalPanelLayout(params: PopoverPositionParams, config: PopoverPositionConfig, triggerCenterX: number, placement: 'top' | 'bottom'): PopoverPanelLayout {
  const topBase = placement === 'bottom' ? params.triggerRect.bottom + config.panelGap + config.offsetY : params.triggerRect.top - params.panelHeight - config.panelGap + config.offsetY;
  const left = clamp(triggerCenterX - params.panelWidth / 2 + config.offsetX, config.viewportMargin, params.viewportWidth - params.panelWidth - config.viewportMargin);
  const top = clamp(topBase, config.viewportMargin, params.viewportHeight - params.panelHeight - config.viewportMargin);

  return {
    top,
    left,
    bottom: placement === 'top' ? params.viewportHeight - (top + params.panelHeight) : null,
    arrowPosition: placement === 'bottom' ? 'top' : 'bottom',
    arrowX: clamp(triggerCenterX - left + config.arrowOffsetX, config.arrowMinOffset, params.panelWidth - config.arrowMinOffset),
    arrowY: null,
  };
}

function getHorizontalPanelLayout(params: PopoverPositionParams, config: PopoverPositionConfig, triggerCenterY: number, placement: 'left' | 'right'): PopoverPanelLayout {
  const leftBase = placement === 'left' ? params.triggerRect.left - params.panelWidth - config.panelGap + config.offsetX : params.triggerRect.right + config.panelGap + config.offsetX;
  const left = clamp(leftBase, config.viewportMargin, params.viewportWidth - params.panelWidth - config.viewportMargin);
  const top = clamp(triggerCenterY - params.panelHeight / 2 + config.offsetY, config.viewportMargin, params.viewportHeight - params.panelHeight - config.viewportMargin);

  return {
    top,
    left,
    bottom: null,
    arrowPosition: placement === 'left' ? 'right' : 'left',
    arrowX: null,
    arrowY: clamp(triggerCenterY - top, config.arrowMinOffset, params.panelHeight - config.arrowMinOffset),
  };
}

function hasPopoverSpace(position: SaPopoverPosition, triggerRect: DOMRect, panelWidth: number, panelHeight: number, viewportWidth: number, viewportHeight: number, config: Pick<PopoverPositionConfig, 'viewportMargin' | 'panelGap'>): boolean {
  switch (position) {
    case 'top':
      return triggerRect.top - panelHeight - config.panelGap >= config.viewportMargin;
    case 'bottom':
      return triggerRect.bottom + panelHeight + config.panelGap <= viewportHeight - config.viewportMargin;
    case 'left':
      return triggerRect.left - panelWidth - config.panelGap >= config.viewportMargin;
    case 'right':
      return triggerRect.right + panelWidth + config.panelGap <= viewportWidth - config.viewportMargin;
    default:
      return false;
  }
}

export function getOppositePopoverPosition(position: SaPopoverPosition): SaPopoverPosition {
  switch (position) {
    case 'top':
      return 'bottom';
    case 'bottom':
      return 'top';
    case 'left':
      return 'right';
    case 'right':
      return 'left';
  }
}

function resolveSubPanelDirection(position: SaPopoverPosition, panelRect: DOMRect, viewportWidth: number): 'left' | 'right' {
  switch (position) {
    case 'left':
      return 'left';
    case 'right':
      return 'right';
    case 'top':
    case 'bottom':
    default:
      return panelRect.left >= viewportWidth - panelRect.right ? 'left' : 'right';
  }
}

export function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max);
}
