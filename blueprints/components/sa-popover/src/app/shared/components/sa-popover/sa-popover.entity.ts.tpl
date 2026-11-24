export type SaPopoverButtonVariant = 'outlined' | 'text' | undefined;
export type SaPopoverPosition = 'top' | 'right' | 'left' | 'bottom';

export type SaPopoverActionItem = {
  readonly id: string;
  readonly label: string;
  readonly icon: string;
  readonly iconSize?: string | number;
  readonly disabled?: boolean;
  readonly variant?: SaPopoverButtonVariant;
  readonly styleClass?: string;
};

export type PopoverArrowPlacement = 'top' | 'right' | 'left' | 'bottom';

export type PopoverPanelLayout = {
  top: number;
  left: number;
  /** Distancia al borde de abajo de la ventana cuando el panel se abre hacia arriba: se ancla por ahí para que, si cambia de alto (p. ej. al filtrar una lista), crezca hacia arriba y no se despegue del botón. `null` en el resto. */
  bottom: number | null;
  arrowPosition: PopoverArrowPlacement;
  arrowX: number | null;
  arrowY: number | null;
};

export type SubPanelAnchor = {
  top?: number;
  bottom?: number;
  left?: number;
  right?: number;
};
