import { asRef, inputsOf, snippet, type UiProps } from './ui-system.code';

/** Qué token de la pestaña UI cambia a un componente (ver `core/design-preferences/README.md`). */
export type UiToken = 'Tamaño de botones' | 'Radio de bordes' | 'Densidad' | 'Tamaño de fuente';

/**
 * Una forma de usar un componente: las propiedades con las que se pinta su vista previa y de las que
 * sale su código. Las variantes son solo del catálogo; no tienen nada que ver con los tokens de la
 * pestaña UI (radio, tamaño de botones, densidad, tamaño de fuente), que cambian por variables CSS.
 */
export interface UiVariant {
  readonly id: string;
  /** El nombre que lleva su chip (`xsmall`, `outlined`, `top`…). */
  readonly label: string;
  /** El grupo en el que se pinta junto a otras variantes (`Tamaños`, `Severidades`…). */
  readonly group: string;
  readonly props: UiProps;
  /** Lo que recibe el componente de la vista previa: `props` sin los enlaces escritos a mano y con las referencias resueltas. */
  readonly inputs: Readonly<Record<string, unknown>>;
  /** El texto que va dentro del componente (un separador con texto, por ejemplo). */
  readonly text?: string;
  /** Clases de la caja que envuelve la vista previa de esta variante. */
  readonly boxClass?: string;
  /** Código escrito a mano para lo que no es una etiqueta (un toast se muestra desde el código). */
  readonly code?: string;
}

/** Un interruptor del catálogo que cambia el modal o el panel que se abre (y su código). */
export interface UiOption {
  readonly id: string;
  readonly label: string;
  /** La propiedad que cambia; sin ella, el interruptor solo muestra u oculta una zona. */
  readonly prop?: string;
  /** El valor de la propiedad cuando el interruptor no está como empieza. */
  readonly on?: string | number | boolean;
  readonly off?: string | number | boolean;
  readonly startsOn?: boolean;
}

export interface UiComponentEntry {
  readonly id: string;
  readonly label: string;
  readonly selector: string;
  /** La etiqueta que sale en el código cuando no es el selector (el tooltip se escribe sobre otro componente). */
  readonly tag?: string;
  readonly description: string;
  /** Los tokens que lo cambian; vacío si no depende de ninguno. */
  readonly affects: readonly UiToken[];
  /** El uso mínimo; el código de cada variante sale de `variants`. */
  readonly code: string;
  readonly variants: readonly UiVariant[];
  /** Clases de la caja de cada vista previa, si el componente necesita un ancho. */
  readonly previewClass?: string;
  /** Propiedades que llevan todas las variantes en el código (el `[(visible)]` de un modal). */
  readonly baseProps?: UiProps;
  readonly options?: readonly UiOption[];
  /** `ts` cuando el código no es una etiqueta. */
  readonly language?: 'html' | 'ts';
  /** El contenido proyectado que sale en el código, según las zonas que están activas. */
  readonly content?: (zones: ReadonlySet<string>) => string;
}

const variant = (id: string, group: string, props: UiProps, extra: Partial<UiVariant> = {}): UiVariant => ({ id, label: id, group, props, inputs: inputsOf(props), ...extra });

/** Una variante con su nombre propio (cuando el id no se lee bien en el chip). */
const named = (id: string, label: string, group: string, props: UiProps, extra: Partial<UiVariant> = {}): UiVariant => ({ id, label, group, props, inputs: inputsOf(props), ...extra });

const PLANS = [
  { label: 'Básico', value: 'basic' },
  { label: 'Pro', value: 'pro' },
  { label: 'Empresa', value: 'enterprise' },
];

const STATUSES = [
  { label: 'Abierto', value: 'open', icon: 'CircleDot', color: '#10b981' },
  { label: 'Pendiente', value: 'pending', icon: 'Clock', color: '#f59e0b' },
  { label: 'Cerrado', value: 'closed', icon: 'CircleMinus', color: '#6b7280' },
];

const ACTIONS = [
  { id: 'edit', label: 'Editar', icon: 'Edit' },
  { id: 'copy', label: 'Copiar', icon: 'Copy' },
  { id: 'remove', label: 'Eliminar', icon: 'X' },
];

const TOAST_TEXTS: Readonly<Record<string, readonly [string, string]>> = {
  showSuccess: ['Guardado', 'Los cambios se guardaron.'],
  showInfo: ['Novedad', 'Hay una versión nueva disponible.'],
  showWarning: ['Atención', 'La sesión está por vencer.'],
  showError: ['No se pudo guardar', 'Inténtalo de nuevo en un momento.'],
  showSecondary: ['Recordatorio', 'Tienes una tarea pendiente.'],
  showContrast: ['Aviso', 'Este mensaje usa el estilo de contraste.'],
  showLoading: ['Procesando', 'Esto puede tardar unos segundos.'],
};

const toastVariant = (id: string, group: string, method: string, position?: string): UiVariant => {
  const [title, message] = TOAST_TEXTS[method];
  const call = `this.alerts.${method}('${title}', '${message}'${position ? `, undefined, undefined, '${position}'` : ''});`;
  return { id, label: id, group, props: { method, title, message, ...(position ? { position } : {}) }, inputs: {}, code: call };
};

const BUTTON_SIZES = ['xsmall', 'small', 'medium', 'high', 'large'] as const;
const BUTTON_SEVERITIES = ['primary', 'secondary', 'success', 'info', 'warn', 'help', 'danger', 'contrast'] as const;

/**
 * Los componentes de la colección esencial, con lo que hace falta para usarlos: el selector, qué
 * tokens los afectan y todas sus variantes, cada una con su vista previa y su código. La vista previa
 * está en `ui-system.html`. Al agregar un componente a la colección, agrégalo aquí y su `@case` allá.
 */
export const UI_COMPONENTS: readonly UiComponentEntry[] = [
  {
    id: 'icon',
    label: 'Icono',
    selector: 'as-icon',
    description: 'Un icono de Lucide por su nombre; hereda el color del texto.',
    affects: ['Tamaño de fuente'],
    code: `<as-icon name="Palette" size="24" />`,
    variants: [
      ...[16, 24, 32, 48].map((size) => named(`size-${size}`, `${size}`, 'Tamaños', { name: 'Palette', size })),
      ...[
        ['color-red', '#ef4444'],
        ['color-green', '#10b981'],
        ['color-indigo', '#6366f1'],
      ].map(([id, color]) => variant(id, 'Colores', { name: 'Star', size: 24, color })),
      variant('spin', 'Animado', { name: 'Loader', size: 24, spin: true }),
      ...['Check', 'Search', 'User', 'Bell'].map((name) => named(`name-${name.toLowerCase()}`, name, 'Nombres', { name, size: 24 })),
    ],
  },
  {
    id: 'button',
    label: 'Botón',
    selector: 'as-button',
    description: 'Acción principal, secundaria o de contorno, con icono, tamaños y estados.',
    affects: ['Tamaño de botones', 'Radio de bordes', 'Tamaño de fuente'],
    code: `<as-button label="Guardar" icon="Check" size="medium" (onClick)="save()" />
<as-button label="Cancelar" variant="outlined" />`,
    variants: [
      ...BUTTON_SIZES.map((size) => named(`size-${size}`, size, 'Tamaños', { label: size, size })),
      ...BUTTON_SEVERITIES.map((severity) => named(`severity-${severity}`, severity, 'Severidades', { label: severity, severity })),
      variant('outlined', 'Variantes', { label: 'Contorno', variant: 'outlined' }),
      variant('text', 'Variantes', { label: 'Texto', variant: 'text' }),
      variant('dashed', 'Variantes', { label: 'Punteado', variant: 'dashed' }),
      variant('raised', 'Variantes', { label: 'Elevado', raised: true }),
      named('icon-left', 'icono a la izquierda', 'Iconos', { label: 'Guardar', icon: 'Check' }),
      named('icon-right', 'icono a la derecha', 'Iconos', { label: 'Siguiente', icon: 'ChevronRight', iconPos: 'right' }),
      named('icon-only', 'solo icono', 'Iconos', { icon: 'Plus', ariaLabel: 'Agregar' }),
      named('badge', 'con contador', 'Iconos', { label: 'Mensajes', badge: 3 }),
      variant('loading', 'Estados', { label: 'Guardando', loading: true }),
      variant('disabled', 'Estados', { label: 'Deshabilitado', disabled: true }),
      variant('selected', 'Estados', { label: 'Seleccionado', variant: 'text', selected: true }),
      named('rounded-lg', 'rounded="lg"', 'Forma', { label: 'Redondeado', rounded: 'lg' }),
      named('rounded-full', 'rounded="full"', 'Forma', { label: 'Píldora', rounded: 'full' }),
    ],
  },
  {
    id: 'input',
    label: 'Campo de texto',
    selector: 'as-input',
    description: 'Un campo con etiqueta flotante, validación y tipos (texto, número, teléfono, precio, etiquetas).',
    affects: ['Densidad', 'Tamaño de fuente'],
    code: `<as-input label="Nombre" placeholder="Escribe aquí" [formControl]="name" />`,
    previewClass: 'w-64',
    variants: [
      named('mode-on', 'variant="on"', 'Modos', { label: 'Nombre', variant: 'on' }),
      named('mode-in', 'variant="in"', 'Modos', { label: 'Nombre', variant: 'in' }),
      named('mode-over', 'variant="over"', 'Modos', { label: 'Nombre', variant: 'over' }),
      named('type-text', 'text', 'Tipos', { label: 'Texto', type: 'text' }),
      named('type-email', 'email', 'Tipos', { label: 'Correo', type: 'email' }),
      named('type-password', 'password', 'Tipos', { label: 'Contraseña', type: 'password' }),
      named('type-number', 'number', 'Tipos', { label: 'Cantidad', type: 'number' }),
      named('type-tel', 'tel', 'Tipos', { label: 'Teléfono', type: 'tel' }),
      named('type-price', 'price', 'Tipos', { label: 'Precio', type: 'price' }),
      named('type-url', 'url', 'Tipos', { label: 'Sitio web', type: 'url' }),
      named('type-tags', 'isTagInput', 'Tipos', { label: 'Etiquetas', isTagInput: true }),
      named('icon-left', 'icono a la izquierda', 'Opciones', { label: 'Buscar', lucideIcon: 'Search' }),
      named('icon-right', 'icono a la derecha', 'Opciones', { label: 'Buscar', lucideIcon: 'Search', iconPosition: 'right' }),
      named('stepper', 'showStepper', 'Opciones', { label: 'Cantidad', type: 'number', showStepper: true, min: 0, max: 10 }),
      named('phone-picker', 'phoneCountryPicker', 'Opciones', { label: 'Teléfono', type: 'tel', phoneCountryPicker: true }),
      named('required', 'required', 'Opciones', { label: 'Nombre', required: true }),
      named('readonly', 'readonlyInput', 'Opciones', { label: 'Nombre', value: 'Solo lectura', readonlyInput: true }),
    ],
  },
  {
    id: 'textarea',
    label: 'Área de texto',
    selector: 'as-textarea',
    description: 'Un campo de varias líneas que crece con el contenido.',
    affects: ['Densidad', 'Tamaño de fuente'],
    code: `<as-textarea label="Comentario" [rows]="2" [formControl]="comment" />`,
    previewClass: 'w-64',
    variants: [
      named('mode-on', 'variant="on"', 'Modos', { label: 'Comentario', variant: 'on', rows: 2 }),
      named('mode-in', 'variant="in"', 'Modos', { label: 'Comentario', variant: 'in', rows: 2 }),
      named('mode-over', 'variant="over"', 'Modos', { label: 'Comentario', variant: 'over', rows: 2 }),
      named('rows-4', 'rows 4', 'Opciones', { label: 'Comentario', rows: 4 }),
      named('fixed', 'autoResize apagado', 'Opciones', { label: 'Comentario', rows: 3, autoResize: false }),
      named('icon', 'con icono', 'Opciones', { label: 'Comentario', rows: 2, lucideIcon: 'Edit' }),
      named('required', 'required', 'Opciones', { label: 'Comentario', rows: 2, required: true }),
      named('readonly', 'readonlyInput', 'Opciones', { label: 'Comentario', rows: 2, value: 'Solo lectura', readonlyInput: true }),
    ],
  },
  {
    id: 'checkbox',
    label: 'Casilla',
    selector: 'as-checkbox',
    description: 'Una casilla de verificación que funciona con formularios.',
    affects: ['Tamaño de fuente'],
    code: `<as-checkbox ariaLabel="Acepto los términos" [formControl]="accepted" />`,
    variants: [
      variant('unchecked', 'Estados', { ariaLabel: 'Sin marcar' }, { code: `<as-checkbox ariaLabel="Sin marcar" [formControl]="accepted" />` }),
      variant('checked', 'Estados', { ariaLabel: 'Marcada', checked: true }, { code: `accepted = new FormControl(true);

<as-checkbox ariaLabel="Marcada" [formControl]="accepted" />` }),
      variant('indeterminate', 'Estados', { ariaLabel: 'Indeterminada', indeterminate: true }, { code: `<as-checkbox ariaLabel="Indeterminada" [indeterminate]="true" [formControl]="accepted" />` }),
      variant('disabled', 'Estados', { ariaLabel: 'Deshabilitada', disabled: true }, { code: `accepted = new FormControl({ value: false, disabled: true });

<as-checkbox ariaLabel="Deshabilitada" [formControl]="accepted" />` }),
      variant('disabled-checked', 'Estados', { ariaLabel: 'Deshabilitada y marcada', checked: true, disabled: true }, { code: `accepted = new FormControl({ value: true, disabled: true });

<as-checkbox ariaLabel="Deshabilitada y marcada" [formControl]="accepted" />` }),
    ],
  },
  {
    id: 'toggle',
    label: 'Interruptor',
    selector: 'as-toggle',
    description: 'Un interruptor de encendido y apagado.',
    affects: ['Tamaño de fuente'],
    code: `<as-toggle [checked]="enabled()" (changed)="enabled.set($event)" ariaLabel="Activar" />`,
    variants: [
      variant('off', 'Estados', { checked: false, ariaLabel: 'Apagado' }),
      variant('on', 'Estados', { checked: true, ariaLabel: 'Encendido' }),
      variant('disabled-off', 'Estados', { checked: false, disabled: true, ariaLabel: 'Apagado y deshabilitado' }),
      variant('disabled-on', 'Estados', { checked: true, disabled: true, ariaLabel: 'Encendido y deshabilitado' }),
    ],
  },
  {
    id: 'select',
    label: 'Selector',
    selector: 'as-select',
    description: 'Una lista desplegable con búsqueda, selección múltiple y opciones con icono o color.',
    affects: ['Radio de bordes', 'Densidad', 'Tamaño de fuente'],
    code: `<as-select label="Plan" [options]="plans" optionLabel="label" optionValue="value" [formControl]="plan" />`,
    previewClass: 'w-64',
    variants: (() => {
      const plans = { options: asRef('plans', PLANS), optionLabel: 'label', optionValue: 'value' };
      const statuses = { options: asRef('statuses', STATUSES), optionLabel: 'label', optionValue: 'value', optionIcon: 'icon', optionColor: 'color', searchable: false };
      return [
        named('mode-on', 'variant="on"', 'Modos', { label: 'Plan', variant: 'on', ...plans }),
        named('mode-in', 'variant="in"', 'Modos', { label: 'Plan', variant: 'in', ...plans }),
        named('mode-over', 'variant="over"', 'Modos', { label: 'Plan', variant: 'over', ...plans }),
        named('plain', 'searchable apagado', 'Opciones', { label: 'Plan', searchable: false, ...plans }),
        named('multiple', 'multiselect', 'Opciones', { label: 'Planes', multiselect: true, ...plans }),
        named('clearable', 'showClear', 'Opciones', { label: 'Plan', showClear: true, ...plans }),
        named('icon', 'con icono', 'Opciones', { label: 'Plan', lucideIcon: 'Search', ...plans }),
        named('required', 'required', 'Opciones', { label: 'Plan', required: true, ...plans }),
        named('shape-dot', 'optionShape="dot"', 'Opciones con color', { label: 'Estado', optionShape: 'dot', ...statuses }),
        named('shape-chip', 'optionShape="chip"', 'Opciones con color', { label: 'Estado', optionShape: 'chip', ...statuses }),
        named('shape-bar', 'optionShape="bar"', 'Opciones con color', { label: 'Estado', optionShape: 'bar', ...statuses }),
        named('shape-box', 'optionShape="box"', 'Opciones con color', { label: 'Estado', optionShape: 'box', ...statuses }),
        named('icon-only', 'hideOptionLabel', 'Opciones con color', { label: 'Estado', hideOptionLabel: true, optionIconSize: 18, accentColor: '#6366f1', ...statuses }),
      ];
    })(),
  },
  {
    id: 'avatar',
    label: 'Avatar',
    selector: 'as-avatar',
    description: 'Una imagen o las iniciales de una persona, circular o con esquinas redondeadas, con su estado de presencia.',
    affects: [],
    code: `<as-avatar label="AB" [size]="40" />`,
    variants: [
      named('shape-circle', 'shape="circle"', 'Forma', { label: 'AB', size: 40 }),
      named('shape-rounded', 'shape="rounded"', 'Forma', { label: 'AB', size: 40, shape: 'rounded' }),
      ...[24, 32, 40, 56].map((size) => named(`size-${size}`, `${size}`, 'Tamaños', { label: 'AB', size })),
      named('color', 'background', 'Colores', { label: 'CD', size: 40, background: '#6366f1' }),
      ...['online', 'away', 'busy', 'invisible'].map((status) => named(`presence-${status}`, status, 'Presencia', { label: 'EF', size: 40, mode: 'presence', presenceStatus: status })),
    ],
  },
  {
    id: 'divider',
    label: 'Separador',
    selector: 'as-divider',
    description: 'Una línea horizontal o vertical, sólida, punteada o de puntos, con texto opcional.',
    affects: [],
    code: `<as-divider />`,
    variants: [
      ...(['solid', 'dashed', 'dotted'] as const).map((type) => named(`horizontal-${type}`, `${type}`, 'Horizontal', { layout: 'horizontal', type }, { boxClass: 'w-48' })),
      ...(['left', 'center', 'right'] as const).map((align) => named(`text-${align}`, `texto ${align}`, 'Con texto', { layout: 'horizontal', align }, { text: 'Texto', boxClass: 'w-48' })),
      ...(['solid', 'dashed', 'dotted'] as const).map((type) => named(`vertical-${type}`, `${type}`, 'Vertical', { layout: 'vertical', type }, { boxClass: 'h-12' })),
    ],
  },
  {
    id: 'skeleton',
    label: 'Esqueleto',
    selector: 'as-skeleton',
    description: 'El marcador de un contenido que todavía se está cargando.',
    affects: [],
    code: `<as-skeleton layout="line" [lines]="2" />`,
    previewClass: 'w-56',
    variants: [
      named('layout-line', 'layout="line"', 'Estructuras', { layout: 'line', lines: 3 }),
      named('layout-stat', 'layout="stat"', 'Estructuras', { layout: 'stat' }),
      named('layout-row', 'layout="row"', 'Estructuras', { layout: 'row' }),
      named('layout-circles', 'layout="circles"', 'Estructuras', { layout: 'circles' }),
      named('shape-circle', 'shape="circle"', 'Formas', { shape: 'circle', size: '3rem' }),
      named('shape-rectangle', 'shape="rectangle"', 'Formas', { shape: 'rectangle', height: '2rem' }),
      ...(['input', 'select', 'button', 'button-sm', 'chip'] as const).map((kind) => named(`variant-${kind}`, `variant="${kind}"`, 'Como otro componente', { variant: kind })),
    ],
  },
  {
    id: 'tooltip',
    label: 'Tooltip',
    selector: '[asTooltip]',
    tag: 'as-button',
    description: 'Un texto flotante que aparece al pasar el cursor por cualquier elemento.',
    affects: ['Radio de bordes', 'Tamaño de fuente'],
    code: `<as-button label="Ayuda" asTooltip="Texto de ayuda" tooltipPosition="top" />`,
    variants: (['top', 'bottom', 'left', 'right'] as const).map((position) => named(position, position, 'Posición', { label: 'Ayuda', variant: 'outlined', asTooltip: 'Texto de ayuda', tooltipPosition: position })),
  },
  {
    id: 'modal',
    label: 'Modal',
    selector: 'as-modal',
    description: 'Un diálogo sobre toda la página, con título, pie y cierre con Escape o al hacer clic fuera.',
    affects: ['Densidad', 'Tamaño de fuente'],
    code: `<as-modal [(visible)]="open" title="Título">Contenido</as-modal>`,
    baseProps: { '[(visible)]': 'open', title: 'Título' },
    variants: [
      named('width-24', 'width="24rem"', 'Tamaño', { width: '24rem' }),
      named('width-34', 'width="34rem"', 'Tamaño', { width: '34rem' }),
      named('width-48', 'width="48rem"', 'Tamaño', { width: '48rem' }),
      named('preview', 'variant="preview"', 'Forma', { variant: 'preview' }),
    ],
    options: [
      { id: 'footer', label: 'Con pie', prop: 'showFooter', on: true },
      { id: 'closable', label: 'Botón de cerrar', prop: 'closable', on: true, off: false, startsOn: true },
      { id: 'dismissableMask', label: 'Cierra al hacer clic fuera', prop: 'dismissableMask', on: true, off: false, startsOn: true },
      { id: 'icon', label: 'Icono en el título', prop: 'titleIcon', on: 'User' },
      { id: 'dot', label: 'Punto de color en el título', prop: 'titleDotColor', on: '#10b981' },
    ],
    content: (zones) => (zones.has('footer') ? 'Contenido <div modal-footer>…</div>' : 'Contenido'),
  },
  {
    id: 'drawer',
    label: 'Panel lateral',
    selector: 'as-drawer',
    description: 'Un panel que entra por un lado y se pinta sobre toda la página, con cabecera, contenido y pie.',
    affects: ['Tamaño de fuente'],
    code: `<as-drawer [(visible)]="open" position="right">Contenido</as-drawer>`,
    baseProps: { '[(visible)]': 'open' },
    variants: [
      ...(['left', 'right', 'top', 'bottom', 'full'] as const).map((position) => named(position, position, 'Posición', { position })),
      named('width-30', 'width="30rem"', 'Ancho', { position: 'right', width: '30rem' }),
      named('width-45', 'width="45rem"', 'Ancho', { position: 'right', width: '45rem' }),
    ],
    options: [
      { id: 'footer', label: 'Con pie' },
      { id: 'closable', label: 'Botón de cerrar', prop: 'closable', on: true, off: false, startsOn: true },
      { id: 'dismissible', label: 'Cierra al hacer clic fuera', prop: 'dismissible', on: true, off: false, startsOn: true },
      { id: 'closeOnEscape', label: 'Cierra con Escape', prop: 'closeOnEscape', on: true, off: false, startsOn: true },
      { id: 'compact', label: 'Densidad compacta', prop: 'density', on: 'compact' },
      { id: 'flush', label: 'Sin relleno (flush)', prop: 'flush', on: true },
    ],
    content: (zones) => ['<h3 drawer-header>Título</h3>', 'Contenido', ...(zones.has('footer') ? ['<as-button drawer-footer label="Guardar" />'] : [])].join('\n'),
  },
  {
    id: 'toast',
    label: 'Toast',
    selector: 'as-toast',
    description: 'Avisos breves de cada tipo y en cada posición; se muestran con AlertService y se alojan en el layout.',
    affects: ['Tamaño de fuente'],
    language: 'ts',
    code: `private readonly alerts = inject(AlertService);

this.alerts.showSuccess('Guardado', 'Los cambios se guardaron.');`,
    variants: [
      toastVariant('success', 'Tipos', 'showSuccess'),
      toastVariant('info', 'Tipos', 'showInfo'),
      toastVariant('warning', 'Tipos', 'showWarning'),
      toastVariant('error', 'Tipos', 'showError'),
      toastVariant('secondary', 'Tipos', 'showSecondary'),
      toastVariant('contrast', 'Tipos', 'showContrast'),
      toastVariant('loading', 'Tipos', 'showLoading'),
      ...(['top-left', 'top-right', 'bottom-left', 'bottom-center', 'bottom-right', 'center'] as const).map((position) => toastVariant(`position-${position}`, 'Posición', 'showInfo', position)),
    ],
  },
  {
    id: 'tabs',
    label: 'Pestañas',
    selector: 'as-tabs',
    description: 'Pestañas con desplazamiento y flechas cuando no caben, en dos estilos y dos tamaños.',
    affects: ['Tamaño de fuente'],
    code: `<as-tabs [tabs]="tabs" [(active)]="active" ariaLabel="Secciones" />`,
    previewClass: 'w-72',
    variants: [
      named('default', 'variant="default"', 'Estilos', { variant: 'default', '[tabs]': 'tabs', '[(active)]': 'active' }),
      named('pills', 'variant="pills"', 'Estilos', { variant: 'pills', '[tabs]': 'tabs', '[(active)]': 'active' }),
      named('compact', 'size="compact"', 'Tamaños', { size: 'compact', '[tabs]': 'tabs', '[(active)]': 'active' }),
      named('pills-compact', 'pills + compact', 'Tamaños', { variant: 'pills', size: 'compact', '[tabs]': 'tabs', '[(active)]': 'active' }),
      named('with-icons', 'con iconos', 'Contenido', { '[tabs]': 'iconTabs', '[(active)]': 'active' }),
      named('with-counts', 'con contador', 'Contenido', { '[tabs]': 'countTabs', '[(active)]': 'active' }),
    ],
  },
  {
    id: 'popover',
    label: 'Popover',
    selector: 'as-popover',
    description: 'Un panel anclado a un botón, en cada posición, que se cierra al hacer clic fuera.',
    affects: ['Radio de bordes', 'Tamaño de fuente'],
    code: `<as-popover triggerIcon="Ellipsis">Contenido del popover</as-popover>`,
    variants: [
      ...(['top', 'bottom', 'left', 'right'] as const).map((position) => named(position, position, 'Posición', { position, triggerIcon: 'Ellipsis' }, { text: 'Contenido del popover' })),
      named('trigger-text', 'triggerVariant="text"', 'Disparador', { triggerIcon: 'Ellipsis', triggerVariant: 'text' }, { text: 'Contenido del popover' }),
      named('actions', 'actions', 'Contenido', { actions: true, '[items]': 'items', triggerIcon: 'Ellipsis' }),
    ],
  },
];

/** Las variantes de una tarjeta, juntas por grupo y en el orden en que aparecen. */
export function groupsOf(entry: UiComponentEntry): readonly { readonly name: string; readonly variants: readonly UiVariant[] }[] {
  const groups = new Map<string, UiVariant[]>();
  for (const item of entry.variants) groups.set(item.group, [...(groups.get(item.group) ?? []), item]);
  return Array.from(groups, ([name, variants]) => ({ name, variants }));
}

/** El código de una variante: el escrito a mano o la etiqueta que sale de sus propiedades. */
export function codeOfVariant(entry: UiComponentEntry, item: UiVariant, extra: UiProps = {}, zones: ReadonlySet<string> = new Set()): string {
  if (item.code) return item.code;
  const content = entry.content ? entry.content(zones) : (item.text ?? '');
  return snippet(entry.tag ?? entry.selector, { ...entry.baseProps, ...item.props, ...extra }, content);
}

export { PLANS, STATUSES, ACTIONS };
