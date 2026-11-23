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
  /** El nombre que lleva su chip (`xsmall`, `outlined`, `required variant="on"`…). */
  readonly label: string;
  /** El grupo en el que se pinta junto a otras variantes (`Tamaños`, `Severidades`…). */
  readonly group: string;
  readonly props: UiProps;
  /** Lo que recibe el componente de la vista previa: `props` sin los enlaces escritos a mano y con las referencias resueltas. */
  readonly inputs: Readonly<Record<string, unknown>>;
  /** El texto que va dentro del componente (un separador con texto, o el texto de un botón que lleva el tooltip). */
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
  /** Las entradas del componente que el catálogo no muestra a propósito (plantillas, clases, nombres accesibles). */
  readonly notShown?: readonly string[];
  /** `ts` cuando el código no es una etiqueta. */
  readonly language?: 'html' | 'ts';
  /** El contenido proyectado que sale en el código, según las zonas que están activas. */
  readonly content?: (zones: ReadonlySet<string>) => string;
}

const variant = (id: string, group: string, props: UiProps, extra: Partial<UiVariant> = {}): UiVariant => ({ id, label: id, group, props, inputs: inputsOf(props), ...extra });

/** Una variante con su nombre propio (cuando el id no se lee bien en el chip). */
const named = (id: string, label: string, group: string, props: UiProps, extra: Partial<UiVariant> = {}): UiVariant => ({ id, label, group, props, inputs: inputsOf(props), ...extra });

const MODES = ['on', 'in', 'over'] as const;

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

const AGENTS = [
  { label: 'Ana Pérez', value: 'ana', initials: 'AP', presence: 'online' },
  { label: 'Luis Gómez', value: 'luis', initials: 'LG', presence: 'busy' },
  { label: 'Marta Ruiz', value: 'marta', initials: 'MR', presence: 'away' },
];

const ACTIONS = [
  { id: 'edit', label: 'Editar', icon: 'Edit' },
  { id: 'copy', label: 'Copiar', icon: 'Copy' },
  { id: 'remove', label: 'Eliminar', icon: 'X' },
];

/** Una imagen cualquiera para el avatar: un SVG en línea, sin pedir nada a la red. */
const AVATAR_IMAGE = `data:image/svg+xml;utf8,${encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 40 40"><rect width="40" height="40" fill="#6366f1"/><circle cx="20" cy="16" r="7" fill="#fff"/><path d="M6 40c2-10 9-14 14-14s12 4 14 14z" fill="#fff"/></svg>')}`;

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

/** El código de la contraseña con su ojo: el estado lo lleva quien usa el campo, igual que el login de la aplicación de referencia. */
function passwordCode(mode: string): string {
  return `<as-input
  label="Contraseña"
  variant="${mode}"
  [type]="visible() ? 'text' : 'password'"
  [lucideIcon]="visible() ? 'EyeOff' : 'Eye'"
  iconPosition="right"
  [iconClickable]="true"
  (iconClick)="visible.set(!visible())"
/>`;
}

/** Lo que un campo de texto hace en cada uno de sus tres modos. */
const inputModes = (): UiVariant[] =>
  MODES.flatMap((mode) => {
    const group = `Modo variant="${mode}"`;
    const base = { label: 'Nombre', variant: mode };
    return [
      named(`required-${mode}`, `required variant="${mode}"`, group, { ...base, required: true }),
      named(`readonly-${mode}`, `readonlyInput variant="${mode}"`, group, { ...base, value: 'Solo lectura', readonlyInput: true }),
      named(`icon-left-${mode}`, `icono a la izquierda variant="${mode}"`, group, { label: 'Buscar', variant: mode, lucideIcon: 'Search' }),
      named(`icon-right-${mode}`, `icono a la derecha variant="${mode}"`, group, { label: 'Buscar', variant: mode, lucideIcon: 'Search', iconPosition: 'right' }),
      named(`stepper-${mode}`, `showStepper variant="${mode}"`, group, { label: 'Cantidad', variant: mode, type: 'number', showStepper: true, min: 0, max: 10 }),
      named(`price-${mode}`, `price variant="${mode}"`, group, { label: 'Precio', variant: mode, type: 'price' }),
      named(`tags-${mode}`, `isTagInput variant="${mode}"`, group, { label: 'Etiquetas', variant: mode, isTagInput: true }),
      named(`phone-picker-${mode}`, `phoneCountryPicker variant="${mode}"`, group, { label: 'Teléfono', variant: mode, type: 'tel', phoneCountryPicker: true }),
      named(`password-${mode}`, `password variant="${mode}"`, group, { label: 'Contraseña', variant: mode, type: 'password', lucideIcon: 'Eye', iconPosition: 'right', iconClickable: true }, { code: passwordCode(mode) }),
    ];
  });

const previewContent = (zones: ReadonlySet<string>): string => (zones.has('long') ? 'Contenido largo que se desplaza…' : 'Contenido');

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
      named('extra-class', 'extraClass', 'Animado', { name: 'Bell', size: 24, extraClass: 'opacity-40' }),
      ...['Check', 'Search', 'User', 'Bell'].map((name) => named(`name-${name.toLowerCase()}`, name, 'Nombres', { name, size: 24 })),
    ],
  },
  {
    id: 'button',
    label: 'Botón',
    selector: 'as-button',
    description: 'Acción principal, secundaria o de contorno, con icono, tamaños y estados.',
    affects: ['Tamaño de botones', 'Radio de bordes', 'Tamaño de fuente'],
    // `outlined` y `text` son la forma corta de `variant`; el resto son clases, nombres accesibles o atributos del enlace.
    notShown: ['outlined', 'text', 'type', 'target', 'rel', 'ariaControls', 'ariaExpanded', 'ariaPressed', 'styleClass', 'labelClass', 'badgeClass', 'iconExtraClass', 'trailingIconExtraClass', 'loadingIcon'],
    code: `<as-button label="Guardar" icon="Check" size="medium" (onClick)="save()" />
<as-button label="Cancelar" variant="outlined" />`,
    variants: [
      ...BUTTON_SIZES.map((size) => named(`size-${size}`, size, 'Tamaños', { label: size, size })),
      ...BUTTON_SEVERITIES.map((severity) => named(`severity-${severity}`, severity, 'Severidades', { label: severity, severity })),
      variant('outlined', 'Variantes', { label: 'Contorno', variant: 'outlined' }),
      variant('text', 'Variantes', { label: 'Texto', variant: 'text' }),
      variant('dashed', 'Variantes', { label: 'Punteado', variant: 'dashed' }),
      variant('raised', 'Variantes', { label: 'Elevado', raised: true }),
      ...BUTTON_SEVERITIES.map((severity) => named(`outlined-${severity}`, `outlined ${severity}`, 'Contorno por severidad', { label: severity, severity, variant: 'outlined' })),
      ...BUTTON_SEVERITIES.map((severity) => named(`text-${severity}`, `text ${severity}`, 'Texto por severidad', { label: severity, severity, variant: 'text' })),
      named('icon-left', 'icono a la izquierda', 'Iconos', { label: 'Guardar', icon: 'Check' }),
      named('icon-right', 'icono a la derecha', 'Iconos', { label: 'Siguiente', icon: 'ChevronRight', iconPos: 'right' }),
      named('icon-top', 'icono arriba', 'Iconos', { label: 'Inicio', icon: 'Home', iconPos: 'top' }),
      named('icon-bottom', 'icono abajo', 'Iconos', { label: 'Inicio', icon: 'Home', iconPos: 'bottom' }),
      named('icon-both', 'trailingIcon', 'Iconos', { label: 'Opciones', icon: 'Settings', trailingIcon: 'ChevronDown', trailingIconSize: 16, trailingIconColor: 'currentColor' }),
      named('icon-color', 'iconColor e iconSize', 'Iconos', { label: 'Favorito', icon: 'Star', iconSize: 20, iconColor: '#f59e0b', variant: 'outlined' }),
      named('icon-only', 'solo icono', 'Iconos', { icon: 'Plus', ariaLabel: 'Agregar' }),
      named('badge', 'con contador', 'Iconos', { label: 'Mensajes', badge: 3 }),
      ...BUTTON_SIZES.map((size) => named(`icon-only-${size}`, `solo icono ${size}`, 'Solo icono por tamaño', { icon: 'Plus', ariaLabel: 'Agregar', size })),
      variant('loading', 'Estados', { label: 'Guardando', loading: true }),
      variant('disabled', 'Estados', { label: 'Deshabilitado', disabled: true }),
      variant('selected', 'Estados', { label: 'Seleccionado', variant: 'text', selected: true }),
      named('link', 'href', 'Estados', { label: 'Como enlace', href: 'https://angular.dev', variant: 'outlined' }),
      named('rounded-lg', 'rounded="lg"', 'Forma', { label: 'Redondeado', rounded: 'lg' }),
      named('rounded-full', 'rounded="full"', 'Forma', { label: 'Píldora', rounded: 'full' }),
    ],
  },
  {
    id: 'input',
    label: 'Campo de texto',
    selector: 'as-input',
    description: 'Un campo con etiqueta flotante, validación y tipos (texto, número, teléfono con banderas, precio, contraseña con ojo, etiquetas), en sus tres modos.',
    affects: ['Densidad', 'Tamaño de fuente'],
    // `showErrorMessage` solo cambia con un control inválido; el `id` lo pone quien lo usa.
    notShown: ['inputId', 'showErrorMessage'],
    code: `<as-input label="Nombre" placeholder="Escribe aquí" [formControl]="name" />`,
    previewClass: 'w-64',
    variants: [
      ...MODES.map((mode) => named(`mode-${mode}`, `variant="${mode}"`, 'Modos', { label: 'Nombre', variant: mode })),
      named('type-text', 'text', 'Tipos', { label: 'Texto', type: 'text' }),
      named('type-email', 'email', 'Tipos', { label: 'Correo', type: 'email' }),
      named('type-password', 'password', 'Tipos', { label: 'Contraseña', type: 'password', lucideIcon: 'Eye', iconPosition: 'right', iconClickable: true }, { code: passwordCode('on') }),
      named('type-number', 'number', 'Tipos', { label: 'Cantidad', type: 'number' }),
      named('type-tel', 'tel', 'Tipos', { label: 'Teléfono', type: 'tel' }),
      named('type-price', 'price', 'Tipos', { label: 'Precio', type: 'price' }),
      named('type-url', 'url', 'Tipos', { label: 'Sitio web', type: 'url' }),
      named('type-tags', 'isTagInput', 'Tipos', { label: 'Etiquetas', isTagInput: true }),
      ...inputModes(),
      named('placeholder', 'placeholder', 'Otras propiedades', { label: 'Nombre', placeholder: 'Escribe tu nombre' }),
      named('value', 'value', 'Otras propiedades', { label: 'Nombre', value: 'Ana Pérez' }),
      named('autocomplete', 'autocomplete', 'Otras propiedades', { label: 'Correo', type: 'email', autocomplete: 'email' }),
      named('currency', 'currencySymbol', 'Otras propiedades', { label: 'Precio', type: 'price', currencySymbol: '€' }),
      named('step', 'step, min y max', 'Otras propiedades', { label: 'Cantidad', type: 'number', showStepper: true, step: 5, min: 0, max: 50 }),
      named('tag-placeholder', 'tagPlaceholder', 'Otras propiedades', { label: 'Etiquetas', isTagInput: true, tagPlaceholder: 'Agrega una etiqueta' }),
      named('icon-size', 'iconSize', 'Otras propiedades', { label: 'Buscar', lucideIcon: 'Search', iconSize: 22 }),
      named('phone-country', 'defaultCountryIso2', 'Otras propiedades', { label: 'Teléfono', type: 'tel', phoneCountryPicker: true, defaultCountryIso2: 'HN' }),
      named('input-class', 'inputClass', 'Otras propiedades', { label: 'Código', inputClass: 'text-center tracking-widest' }),
    ],
  },
  {
    id: 'textarea',
    label: 'Área de texto',
    selector: 'as-textarea',
    description: 'Un campo de varias líneas que crece con el contenido, en sus tres modos.',
    affects: ['Densidad', 'Tamaño de fuente'],
    notShown: ['inputId', 'showErrorMessage'],
    code: `<as-textarea label="Comentario" [rows]="2" [formControl]="comment" />`,
    previewClass: 'w-64',
    variants: [
      ...MODES.map((mode) => named(`mode-${mode}`, `variant="${mode}"`, 'Modos', { label: 'Comentario', variant: mode, rows: 2 })),
      ...MODES.flatMap((mode) => {
        const group = `Modo variant="${mode}"`;
        const base = { label: 'Comentario', variant: mode, rows: 2 };
        return [
          named(`required-${mode}`, `required variant="${mode}"`, group, { ...base, required: true }),
          named(`readonly-${mode}`, `readonlyInput variant="${mode}"`, group, { ...base, value: 'Solo lectura', readonlyInput: true }),
          named(`icon-${mode}`, `icono a la izquierda variant="${mode}"`, group, { ...base, lucideIcon: 'Edit' }),
          named(`icon-right-${mode}`, `icono a la derecha variant="${mode}"`, group, { ...base, lucideIcon: 'Edit', iconPosition: 'right' }),
          named(`rows-${mode}`, `rows 4 variant="${mode}"`, group, { label: 'Comentario', variant: mode, rows: 4 }),
        ];
      }),
      named('fixed', 'autoResize apagado', 'Otras propiedades', { label: 'Comentario', rows: 3, autoResize: false }),
      named('placeholder', 'placeholder', 'Otras propiedades', { label: 'Comentario', rows: 2, placeholder: 'Escribe un comentario' }),
      named('value', 'value', 'Otras propiedades', { label: 'Comentario', rows: 2, value: 'Un texto ya escrito' }),
      named('autocomplete', 'autocomplete', 'Otras propiedades', { label: 'Dirección', rows: 2, autocomplete: 'street-address' }),
      named('icon-size', 'iconSize', 'Otras propiedades', { label: 'Comentario', rows: 2, lucideIcon: 'Edit', iconSize: 22 }),
    ],
  },
  {
    id: 'checkbox',
    label: 'Casilla',
    selector: 'as-checkbox',
    description: 'Una casilla de verificación que funciona con formularios.',
    affects: ['Tamaño de fuente'],
    // El `id` y la etiqueta externa dependen de quien la usa.
    notShown: ['inputId', 'ariaLabelledBy'],
    code: `<as-checkbox ariaLabel="Acepto los términos" [formControl]="accepted" />`,
    variants: [
      variant('unchecked', 'Estados', { ariaLabel: 'Sin marcar' }, { code: `<as-checkbox ariaLabel="Sin marcar" [formControl]="accepted" />` }),
      variant('checked', 'Estados', { ariaLabel: 'Marcada', checked: true }, { code: `accepted = new FormControl(true);\n\n<as-checkbox ariaLabel="Marcada" [formControl]="accepted" />` }),
      variant('indeterminate', 'Estados', { ariaLabel: 'Indeterminada', indeterminate: true }, { code: `<as-checkbox ariaLabel="Indeterminada" [indeterminate]="true" [formControl]="accepted" />` }),
      variant('disabled', 'Estados', { ariaLabel: 'Deshabilitada', disabled: true }, { code: `accepted = new FormControl({ value: false, disabled: true });\n\n<as-checkbox ariaLabel="Deshabilitada" [formControl]="accepted" />` }),
      variant('disabled-checked', 'Estados', { ariaLabel: 'Deshabilitada y marcada', checked: true, disabled: true }, { code: `accepted = new FormControl({ value: true, disabled: true });\n\n<as-checkbox ariaLabel="Deshabilitada y marcada" [formControl]="accepted" />` }),
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
    description: 'Una lista desplegable con búsqueda, selección múltiple y opciones con icono, color o avatar, en sus tres modos.',
    affects: ['Radio de bordes', 'Densidad', 'Tamaño de fuente'],
    // El `id`, el mensaje de error y la clase del panel dependen de quien lo usa.
    notShown: ['inputId', 'showErrorMessage', 'panelStyleClass'],
    code: `<as-select label="Plan" [options]="plans" optionLabel="label" optionValue="value" [formControl]="plan" />`,
    previewClass: 'w-64',
    variants: (() => {
      const plans = { options: asRef('plans', PLANS), optionLabel: 'label', optionValue: 'value' };
      const statuses = { options: asRef('statuses', STATUSES), optionLabel: 'label', optionValue: 'value', optionIcon: 'icon', optionColor: 'color', searchable: false };
      const agents = { options: asRef('agents', AGENTS), optionLabel: 'label', optionValue: 'value', optionAvatar: 'initials', optionAvatarLabel: 'initials', optionPresence: 'presence' };
      return [
        ...MODES.map((mode) => named(`mode-${mode}`, `variant="${mode}"`, 'Modos', { label: 'Plan', variant: mode, ...plans })),
        ...MODES.flatMap((mode) => {
          const group = `Modo variant="${mode}"`;
          const base = { label: 'Plan', variant: mode, ...plans };
          return [
            named(`required-${mode}`, `required variant="${mode}"`, group, { ...base, required: true }),
            named(`clearable-${mode}`, `showClear variant="${mode}"`, group, { ...base, showClear: true }),
            named(`multiple-${mode}`, `multiselect variant="${mode}"`, group, { ...base, multiselect: true }),
            named(`plain-${mode}`, `searchable apagado variant="${mode}"`, group, { ...base, searchable: false }),
            named(`icon-${mode}`, `icono a la izquierda variant="${mode}"`, group, { ...base, lucideIcon: 'Search' }),
            named(`icon-right-${mode}`, `icono a la derecha variant="${mode}"`, group, { ...base, lucideIcon: 'Search', iconPosition: 'right' }),
            // El valor lo lleva el control (`[formControl]`), como en un formulario real: sin él un selector de solo lectura se vería vacío.
            named(`readonly-${mode}`, `readonlyInput variant="${mode}"`, group, { ...base, readonlyInput: true, '[formControl]': 'plan' }),
          ];
        }),
        named('placeholder', 'placeholder', 'Otras propiedades', { placeholder: 'Elige un plan', ...plans }),
        named('interaction-disabled', 'interactionDisabled', 'Otras propiedades', { label: 'Plan', interactionDisabled: true, ...plans }),
        named('shape-dot', 'optionShape="dot"', 'Opciones con color', { label: 'Estado', optionShape: 'dot', ...statuses }),
        named('shape-chip', 'optionShape="chip"', 'Opciones con color', { label: 'Estado', optionShape: 'chip', ...statuses }),
        named('shape-bar', 'optionShape="bar"', 'Opciones con color', { label: 'Estado', optionShape: 'bar', ...statuses }),
        named('shape-box', 'optionShape="box"', 'Opciones con color', { label: 'Estado', optionShape: 'box', ...statuses }),
        named('icon-only', 'hideOptionLabel', 'Opciones con color', { label: 'Estado', hideOptionLabel: true, optionIconSize: 18, accentColor: '#6366f1', ...statuses }),
        named('avatar', 'optionAvatar', 'Opciones con avatar', { label: 'Agente', ...agents }),
        named('avatar-rounded', 'optionAvatarShape="rounded"', 'Opciones con avatar', { label: 'Agente', optionAvatarShape: 'rounded', ...agents }),
      ];
    })(),
  },
  {
    id: 'avatar',
    label: 'Avatar',
    selector: 'as-avatar',
    description: 'Una imagen o las iniciales de una persona, circular o con esquinas redondeadas, con su estado de presencia.',
    affects: [],
    // El texto alternativo y el icono y el fondo del punto de presencia salen del estado.
    notShown: ['alt', 'dotIconSize', 'dotBackground'],
    code: `<as-avatar label="AB" [size]="40" />`,
    variants: [
      named('shape-circle', 'shape="circle"', 'Forma', { label: 'AB', size: 40 }),
      named('shape-rounded', 'shape="rounded"', 'Forma', { label: 'AB', size: 40, shape: 'rounded' }),
      named('image', 'imageUrl', 'Forma', { label: 'AB', size: 40, imageUrl: AVATAR_IMAGE }),
      named('image-rounded', 'imageUrl rounded', 'Forma', { label: 'AB', size: 40, imageUrl: AVATAR_IMAGE, shape: 'rounded' }),
      ...[24, 32, 40, 56].map((size) => named(`size-${size}`, `${size}`, 'Tamaños', { label: 'AB', size })),
      named('css-size', 'cssSize', 'Tamaños', { label: 'AB', cssSize: '3.5rem' }),
      named('color', 'background', 'Colores', { label: 'CD', size: 40, background: '#6366f1' }),
      named('text-color', 'color y textClass', 'Colores', { label: 'CD', size: 40, background: '#fde68a', color: '#78350f', textClass: 'text-caption-2-bold' }),
      ...['online', 'away', 'busy', 'invisible'].map((status) => named(`presence-${status}`, status, 'Presencia', { label: 'EF', size: 40, mode: 'presence', presenceStatus: status })),
      ...['online', 'busy'].map((status) => named(`presence-rounded-${status}`, `${status} rounded`, 'Presencia', { label: 'EF', size: 40, shape: 'rounded', mode: 'presence', presenceStatus: status })),
      named('presence-dot-size', 'dotSize', 'Presencia', { label: 'EF', size: 56, mode: 'presence', presenceStatus: 'online', dotSize: '1rem' }),
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
      ...(['solid', 'dashed', 'dotted'] as const).flatMap((type) =>
        (['left', 'center', 'right'] as const).map((align) => named(type === 'solid' ? `text-${align}` : `${type}-text-${align}`, `${type} texto ${align}`, 'Con texto', { layout: 'horizontal', type, align }, { text: 'Texto', boxClass: 'w-48' })),
      ),
      ...(['solid', 'dashed', 'dotted'] as const).map((type) => named(`vertical-${type}`, `${type}`, 'Vertical', { layout: 'vertical', type }, { boxClass: 'h-12' })),
      ...(['top', 'center', 'bottom'] as const).map((align) => named(`vertical-text-${align}`, `texto ${align}`, 'Vertical con texto', { layout: 'vertical', type: 'solid', align }, { text: 'Texto', boxClass: 'h-24' })),
    ],
  },
  {
    id: 'skeleton',
    label: 'Esqueleto',
    selector: 'as-skeleton',
    description: 'El marcador de un contenido que todavía se está cargando.',
    affects: [],
    // Las clases de texto de cada zona y el interruptor `loading` (con él apagado se ve el contenido) no tienen vista propia.
    notShown: ['valueClass', 'metaClass', 'titleClass', 'subtitleClass', 'loading'],
    code: `<as-skeleton layout="line" [lines]="2" />`,
    variants: [
      named('layout-line', 'layout="line"', 'Estructuras', { layout: 'line', lines: 3 }, { boxClass: 'w-56' }),
      named('layout-stat', 'layout="stat"', 'Estructuras', { layout: 'stat' }, { boxClass: 'w-40' }),
      named('layout-row', 'layout="row"', 'Estructuras', { layout: 'row' }, { boxClass: 'w-80' }),
      named('layout-circles', 'layout="circles"', 'Estructuras', { layout: 'circles' }, { boxClass: 'w-40' }),
      named('line-single', 'una línea', 'Líneas', { layout: 'line', lines: 1, width: '80%' }, { boxClass: 'w-56' }),
      named('line-gap', 'lineGap y lastLineWidth', 'Líneas', { layout: 'line', lines: 4, lineGap: '0.5rem', lastLineWidth: '30%' }, { boxClass: 'w-56' }),
      named('line-center', 'align="center"', 'Líneas', { layout: 'line', width: '50%', align: 'center' }, { boxClass: 'w-56' }),
      named('line-right', 'align="right"', 'Líneas', { layout: 'line', width: '50%', align: 'right' }, { boxClass: 'w-56' }),
      named('line-fill', 'fill, height y radius', 'Líneas', { layout: 'line', fill: true, height: '2rem', radius: '1rem' }, { boxClass: 'w-56 h-12' }),
      named('line-text', 'textClass', 'Líneas', { layout: 'line', textClass: 'text-body-1-bold', width: '70%' }, { boxClass: 'w-56' }),
      named('shape-circle', 'shape="circle"', 'Formas', { shape: 'circle', size: '3rem' }, { boxClass: 'w-16' }),
      named('shape-rectangle', 'shape="rectangle"', 'Formas', { shape: 'rectangle', height: '2rem', width: '10rem' }, { boxClass: 'w-44' }),
      named('row-circle', 'avatarShape="circle"', 'Fila', { layout: 'row', avatarShape: 'circle' }, { boxClass: 'w-80' }),
      named('row-none', 'avatarShape="none"', 'Fila', { layout: 'row', avatarShape: 'none' }, { boxClass: 'w-80' }),
      named('row-sizes', 'avatarSize y avatarRadius', 'Fila', { layout: 'row', avatarSize: '4rem', avatarRadius: '1.5rem' }, { boxClass: 'w-96' }),
      named('row-widths', 'titleWidth y subtitleWidth', 'Fila', { layout: 'row', titleWidth: '6rem', subtitleWidth: '9rem', rowGap: '1.5rem', textGap: '0.75rem' }, { boxClass: 'w-80' }),
      named('stat-widths', 'valueWidth y metaWidth', 'Fila', { layout: 'stat', valueWidth: '5rem', metaWidth: '10rem' }, { boxClass: 'w-48' }),
      named('circles-count', 'count e itemGap', 'Círculos', { layout: 'circles', count: 5, itemGap: '0.75rem' }, { boxClass: 'w-56' }),
      named('circles-size', 'itemSize e itemRadius', 'Círculos', { layout: 'circles', itemSize: '2.5rem', itemRadius: '0.5rem' }, { boxClass: 'w-56' }),
      ...(['input', 'select', 'button', 'button-sm', 'chip'] as const).map((kind) => named(`variant-${kind}`, `variant="${kind}"`, 'Como otro componente', { variant: kind }, { boxClass: 'w-56' })),
    ],
  },
  {
    id: 'tooltip',
    label: 'Tooltip',
    selector: '[asTooltip]',
    tag: 'as-button',
    description: 'Un texto flotante que aparece al pasar el cursor por cualquier elemento: sobre todo el botón (host) o solo sobre su texto.',
    affects: ['Radio de bordes', 'Tamaño de fuente'],
    code: `<as-button label="Ayuda" asTooltip="Texto de ayuda" tooltipPosition="top" />`,
    variants: [...(['host', 'text'] as const).flatMap((anchor) =>
      (['top', 'bottom', 'left', 'right'] as const).map((position) =>
        anchor === 'host'
          ? named(`host-${position}`, `host · ${position}`, 'En todo el botón (host)', { label: 'Ayuda', variant: 'outlined', asTooltip: 'Texto de ayuda', tooltipPosition: position })
          : named(`text-${position}`, `texto · ${position}`, 'Solo en el texto del botón', { variant: 'outlined', tooltipPosition: position }, { text: 'Ayuda', code: `<as-button variant="outlined">\n  <span asTooltip="Texto de ayuda" tooltipPosition="${position}">Ayuda</span>\n</as-button>` }),
      ),
    ),
      named('host-delay', 'showDelay 300', 'Con retraso', { label: 'Ayuda', variant: 'outlined', asTooltip: 'Texto de ayuda', tooltipPosition: 'top', showDelay: 300 }),
    ],
  },
  {
    id: 'modal',
    label: 'Modal',
    selector: 'as-modal',
    description: 'Un diálogo sobre toda la página, con título, pie y cierre con Escape o al hacer clic fuera. El contenido pone su propio relleno, así la barra de desplazamiento queda en el borde.',
    affects: ['Densidad', 'Tamaño de fuente'],
    // La clase del consumidor.
    notShown: ['styleClass'],
    code: `<as-modal [(visible)]="open" title="Título" flush>\n  <div class="p-5">Contenido</div>\n</as-modal>`,
    baseProps: { '[(visible)]': 'open', title: 'Título', flush: true },
    variants: [
      named('width-24', 'width="24rem"', 'Tamaño', { width: '24rem' }),
      named('width-34', 'width="34rem"', 'Tamaño', { width: '34rem' }),
      named('width-48', 'width="48rem"', 'Tamaño', { width: '48rem' }),
      named('preview', 'variant="preview"', 'Forma', { variant: 'preview' }),
    ],
    options: [
      { id: 'footer', label: 'Con pie', prop: 'showFooter', on: true },
      { id: 'long', label: 'Contenido largo' },
      { id: 'closable', label: 'Botón de cerrar', prop: 'closable', on: true, off: false, startsOn: true },
      { id: 'dismissableMask', label: 'Cierra al hacer clic fuera', prop: 'dismissableMask', on: true, off: false, startsOn: true },
      { id: 'draggable', label: 'Se puede mover', prop: 'draggable', on: true, off: false, startsOn: true },
      { id: 'icon', label: 'Icono en el título', prop: 'titleIcon', on: 'User' },
      { id: 'dot', label: 'Punto de color en el título', prop: 'titleDotColor', on: '#10b981' },
    ],
    content: (zones) => [`<div class="p-5">${previewContent(zones)}</div>`, ...(zones.has('footer') ? ['<div modal-footer>…</div>'] : [])].join('\n'),
  },
  {
    id: 'drawer',
    label: 'Panel lateral',
    selector: 'as-drawer',
    description: 'Un panel que entra por un lado y se pinta sobre toda la página, con cabecera, contenido y pie. El contenido pone su propio relleno, así la barra de desplazamiento queda en el borde.',
    affects: ['Tamaño de fuente'],
    // Las plantillas de la cabecera y del ícono de cierre, y la clase del consumidor.
    notShown: ['headerTemplate', 'closeIconTemplate', 'styleClass'],
    code: `<as-drawer [(visible)]="open" position="right" flush>\n  <div class="p-5">Contenido</div>\n</as-drawer>`,
    baseProps: { '[(visible)]': 'open', ariaLabel: 'Panel de ejemplo', flush: true },
    variants: [
      ...(['left', 'right', 'top', 'bottom', 'full'] as const).map((position) => named(position, position, 'Posición', { position })),
      named('width-30', 'width="30rem"', 'Ancho', { position: 'right', width: '30rem' }),
      named('width-45', 'width="45rem"', 'Ancho', { position: 'right', width: '45rem' }),
    ],
    options: [
      { id: 'footer', label: 'Con pie' },
      { id: 'long', label: 'Contenido largo' },
      { id: 'closable', label: 'Botón de cerrar', prop: 'closable', on: true, off: false, startsOn: true },
      { id: 'dismissible', label: 'Cierra al hacer clic fuera', prop: 'dismissible', on: true, off: false, startsOn: true },
      { id: 'closeOnEscape', label: 'Cierra con Escape', prop: 'closeOnEscape', on: true, off: false, startsOn: true },
      { id: 'compact', label: 'Densidad compacta', prop: 'density', on: 'compact' },
      { id: 'closeIcon', label: 'Icono de cierre propio', prop: 'closeIcon', on: 'ChevronRight' },
      { id: 'closeLabel', label: 'Nombre del cierre propio', prop: 'closeLabel', on: 'Volver' },
    ],
    content: (zones) => ['<h3 drawer-header>Título</h3>', `<div class="p-5">${previewContent(zones)}</div>`, ...(zones.has('footer') ? ['<as-button drawer-footer label="Guardar" />'] : [])].join('\n'),
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
      ...(['top-left', 'top-center', 'top-right', 'bottom-left', 'bottom-center', 'bottom-right', 'center'] as const).map((position) => toastVariant(`position-${position}`, 'Posición', 'showInfo', position)),
    ],
  },
  {
    id: 'tabs',
    label: 'Pestañas',
    selector: 'as-tabs',
    description: 'Pestañas con desplazamiento y flechas cuando no caben, en dos estilos y dos tamaños, con iconos y contadores.',
    affects: ['Tamaño de fuente'],
    // El nombre accesible y la clase del texto de cada pestaña.
    notShown: ['ariaLabel', 'tabLabelClass'],
    code: `<as-tabs [tabs]="tabs" [(active)]="active" ariaLabel="Secciones" />`,
    // Cada ejemplo lleva su propia pestaña activa (ver `ownActive` en `ui-system.ts`): elegir una no cambia las demás.
    variants: [
      named('default', 'variant="default"', 'Estilos', { variant: 'default', '[tabs]': 'tabs', '[(active)]': 'active' }, { boxClass: 'w-72' }),
      named('pills', 'variant="pills"', 'Estilos', { variant: 'pills', '[tabs]': 'tabs', '[(active)]': 'active' }, { boxClass: 'w-72' }),
      named('default-icons', 'default con iconos', 'Estilos', { variant: 'default', '[tabs]': 'iconTabs', '[(active)]': 'active' }, { boxClass: 'w-72' }),
      named('pills-icons', 'pills con iconos', 'Estilos', { variant: 'pills', '[tabs]': 'iconTabs', '[(active)]': 'active' }, { boxClass: 'w-72' }),
      named('compact', 'size="compact"', 'Tamaños', { size: 'compact', '[tabs]': 'tabs', '[(active)]': 'active' }, { boxClass: 'w-72' }),
      named('pills-compact', 'pills + compact', 'Tamaños', { variant: 'pills', size: 'compact', '[tabs]': 'tabs', '[(active)]': 'active' }, { boxClass: 'w-72' }),
      named('compact-icons', 'compact con iconos', 'Tamaños', { size: 'compact', '[tabs]': 'iconTabs', '[(active)]': 'active' }, { boxClass: 'w-72' }),
      named('pills-compact-icons', 'pills + compact con iconos', 'Tamaños', { variant: 'pills', size: 'compact', '[tabs]': 'iconTabs', '[(active)]': 'active' }, { boxClass: 'w-72' }),
      named('overflow-icons', 'no caben · con iconos (flechas)', 'Contenido', { '[tabs]': 'manyIconTabs', '[(active)]': 'active' }, { boxClass: 'w-72' }),
      named('overflow-counts', 'no caben · con contador (flechas)', 'Contenido', { '[tabs]': 'manyCountTabs', '[(active)]': 'active' }, { boxClass: 'w-72' }),
      named('fit-icons', 'caben · con iconos (a lo ancho)', 'Contenido', { '[tabs]': 'iconTabs', '[(active)]': 'active' }, { boxClass: 'w-[26rem] max-w-full' }),
      named('fit-counts', 'caben · con contador (a lo ancho)', 'Contenido', { '[tabs]': 'countTabs', '[(active)]': 'active' }, { boxClass: 'w-[26rem] max-w-full' }),
    ],
  },
  {
    id: 'popover',
    label: 'Popover',
    selector: 'as-popover',
    description: 'Un panel anclado a un botón, en cada posición, tamaño y estilo, que se cierra al hacer clic fuera.',
    affects: ['Radio de bordes', 'Tamaño de fuente'],
    // Las clases del consumidor y el nombre accesible del botón.
    notShown: ['triggerStyleClass', 'triggerActiveClass', 'triggerAriaLabel', 'optionStyleClass', 'triggerTooltipStyleClass', 'popoverStyleClass'],
    code: `<as-popover triggerIcon="Ellipsis">Contenido del popover</as-popover>`,
    variants: [
      ...(['top', 'bottom', 'left', 'right'] as const).map((position) => named(position, position, 'Posición', { position, triggerIcon: 'Ellipsis' }, { text: 'Contenido del popover' })),
      ...(['small', 'medium', 'high'] as const).map((size) => named(`size-${size}`, `triggerSize="${size}"`, 'Disparador', { triggerSize: size, triggerIcon: 'Ellipsis' }, { text: 'Contenido del popover' })),
      named('trigger-text', 'triggerVariant="text"', 'Disparador', { triggerIcon: 'Ellipsis', triggerVariant: 'text' }, { text: 'Contenido del popover' }),
      named('trigger-icon', 'triggerIcon e iconSize', 'Disparador', { triggerIcon: 'Settings', triggerIconSize: 20 }, { text: 'Contenido del popover' }),
      named('trigger-tooltip', 'triggerTooltip', 'Disparador', { triggerIcon: 'Ellipsis', triggerTooltip: 'Más opciones', triggerTooltipPosition: 'top', triggerTooltipDelay: 300 }, { text: 'Contenido del popover' }),
      named('offset', 'offsetX y offsetY', 'Panel', { triggerIcon: 'Ellipsis', offsetX: 16, offsetY: 8 }, { text: 'Contenido del popover' }),
      named('match-width', 'matchTriggerWidth', 'Panel', { triggerIcon: 'Ellipsis', matchTriggerWidth: true }, { text: 'Contenido del popover' }),
      named('actions', 'actions', 'Acciones', { actions: true, items: asRef('items', ACTIONS), triggerIcon: 'Ellipsis' }),
      named('actions-text', 'optionVariant="text"', 'Acciones', { actions: true, items: asRef('items', ACTIONS), optionVariant: 'text', triggerIcon: 'Ellipsis' }),
      named('actions-keep', 'closeOnSelect apagado', 'Acciones', { actions: true, items: asRef('items', ACTIONS), closeOnSelect: false, triggerIcon: 'Ellipsis' }),
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

export { PLANS, STATUSES, AGENTS, ACTIONS };
