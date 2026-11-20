export type AsPopoverButtonVariant = 'outlined' | 'text' | undefined;
export type AsPopoverPosition = 'top' | 'right' | 'left' | 'bottom';

export type AsPopoverActionItem = {
  readonly id: string;
  readonly label: string;
  readonly icon: string;
  readonly iconSize?: string | number;
  readonly disabled?: boolean;
  readonly variant?: AsPopoverButtonVariant;
  readonly styleClass?: string;
};

export type PopoverArrowPlacement = 'top' | 'right' | 'left' | 'bottom';

export type PopoverPanelLayout = {
  top: number;
  left: number;
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
