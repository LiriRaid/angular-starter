export type LayoutModeId = 'wide-joined' | 'compact-joined' | 'floating-wide' | 'floating-compact' | 'transparent-joined' | 'transparent-floating';

/** What a mode changes in the shell. The stylesheets read these as `html[data-layout-traits~='floating']`. */
export interface LayoutTraits {
  /** The sidebar shows the icon above the text, and the header shows a search instead of the breadcrumb. */
  readonly compact: boolean;
  /** The sidebar, the header and the content float over the background with a gap between them. */
  readonly floating: boolean;
  /** The sidebar has no background of its own. */
  readonly transparent: boolean;
}

export interface LayoutMode extends LayoutTraits {
  readonly id: LayoutModeId;
  readonly label: string;
  readonly description: string;
  /** Modes that are not built yet are shown "En construcción" and cannot be chosen. */
  readonly built: boolean;
}

/** Every layout of the shell. Each one is a combination of the three traits: one set of components, no files per mode. */
export const LAYOUT_MODES: readonly LayoutMode[] = [
  { id: 'wide-joined', label: 'Sidebar ancho (unido)', description: 'Icono + texto en fila', built: false, compact: false, floating: false, transparent: false },
  { id: 'compact-joined', label: 'Sidebar compacto (unido)', description: 'Icono encima del texto', built: false, compact: true, floating: false, transparent: false },
  { id: 'floating-wide', label: 'Flotante (ancho)', description: 'Sidebar, header y contenido flotantes', built: true, compact: false, floating: true, transparent: false },
  { id: 'floating-compact', label: 'Flotante (compacto)', description: 'Compacto + paneles flotantes', built: false, compact: true, floating: true, transparent: false },
  { id: 'transparent-joined', label: 'Transparente (unido)', description: 'Sin fondo en el sidebar', built: false, compact: false, floating: false, transparent: true },
  { id: 'transparent-floating', label: 'Transparente (flotante)', description: 'Sin fondo y paneles flotantes', built: false, compact: false, floating: true, transparent: true },
];

/** The layouts the design preferences page lets the administrator choose. Edit it to offer more or fewer; `sa add layout` adds to it. */
export const ENABLED_LAYOUT_MODES: readonly LayoutModeId[] = ['floating-wide'];

/** The layout shown when nobody has saved another one. It has to be in `ENABLED_LAYOUT_MODES`. */
export const DEFAULT_LAYOUT_MODE: LayoutModeId = 'floating-wide';

export const isEnabledLayoutMode = (value: unknown): value is LayoutModeId => typeof value === 'string' && (ENABLED_LAYOUT_MODES as readonly string[]).includes(value);

export const layoutTraits = (id: LayoutModeId): LayoutTraits => {
  const mode = LAYOUT_MODES.find((candidate) => candidate.id === id) ?? LAYOUT_MODES.find((candidate) => candidate.id === DEFAULT_LAYOUT_MODE);
  return { compact: mode?.compact ?? false, floating: mode?.floating ?? false, transparent: mode?.transparent ?? false };
};
