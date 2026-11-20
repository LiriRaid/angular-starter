/** Qué token de la pestaña UI cambia a un componente (ver `core/design-preferences/README.md`). */
export type UiToken = 'Tamaño de botones' | 'Radio de bordes' | 'Densidad' | 'Tamaño de fuente';

export interface UiComponentEntry {
  readonly id: string;
  readonly label: string;
  readonly selector: string;
  readonly description: string;
  /** Los tokens que lo cambian; vacío si no depende de ninguno. */
  readonly affects: readonly UiToken[];
  readonly code: string;
}

/**
 * Los componentes de la colección esencial, con lo que hace falta para usarlos: el selector, qué
 * tokens los afectan y un ejemplo de código. La vista previa de cada uno está en `ui-system.html`.
 * Al agregar un componente a la colección, agrégalo aquí y su `@case` allá.
 */
export const UI_COMPONENTS: readonly UiComponentEntry[] = [
  {
    id: 'icon',
    label: 'Icono',
    selector: 'as-icon',
    description: 'Un icono de Lucide por su nombre; hereda el color del texto.',
    affects: ['Tamaño de fuente'],
    code: `<as-icon name="Palette" size="24" />`,
  },
  {
    id: 'button',
    label: 'Botón',
    selector: 'as-button',
    description: 'Acción principal, secundaria o de contorno, con icono y tamaños.',
    affects: ['Tamaño de botones', 'Radio de bordes', 'Tamaño de fuente'],
    code: `<as-button label="Guardar" icon="Check" size="medium" (onClick)="save()" />
<as-button label="Cancelar" variant="outlined" />`,
  },
  {
    id: 'input',
    label: 'Campo de texto',
    selector: 'as-input',
    description: 'Un campo con etiqueta flotante, validación y tipos (texto, número, teléfono).',
    affects: ['Densidad', 'Tamaño de fuente'],
    code: `<as-input label="Nombre" placeholder="Escribe aquí" [formControl]="name" />`,
  },
  {
    id: 'textarea',
    label: 'Área de texto',
    selector: 'as-textarea',
    description: 'Un campo de varias líneas que crece con el contenido.',
    affects: ['Densidad', 'Tamaño de fuente'],
    code: `<as-textarea label="Comentario" [rows]="2" [formControl]="comment" />`,
  },
  {
    id: 'checkbox',
    label: 'Casilla',
    selector: 'as-checkbox',
    description: 'Una casilla de verificación que funciona con formularios.',
    affects: ['Tamaño de fuente'],
    code: `<as-checkbox ariaLabel="Acepto los términos" [formControl]="accepted" />`,
  },
  {
    id: 'toggle',
    label: 'Interruptor',
    selector: 'as-toggle',
    description: 'Un interruptor de encendido y apagado.',
    affects: ['Tamaño de fuente'],
    code: `<as-toggle [checked]="enabled()" (changed)="enabled.set($event)" ariaLabel="Activar" />`,
  },
  {
    id: 'select',
    label: 'Selector',
    selector: 'as-select',
    description: 'Una lista desplegable con búsqueda y selección múltiple.',
    affects: ['Radio de bordes', 'Densidad', 'Tamaño de fuente'],
    code: `<as-select label="Plan" [options]="plans" optionLabel="label" optionValue="value" [formControl]="plan" />`,
  },
  {
    id: 'avatar',
    label: 'Avatar',
    selector: 'as-avatar',
    description: 'Una imagen o las iniciales de una persona, circular o con esquinas redondeadas.',
    affects: [],
    code: `<as-avatar label="AB" [size]="40" />`,
  },
  {
    id: 'divider',
    label: 'Separador',
    selector: 'as-divider',
    description: 'Una línea horizontal o vertical, sólida o punteada, con texto opcional.',
    affects: [],
    code: `<as-divider />`,
  },
  {
    id: 'skeleton',
    label: 'Esqueleto',
    selector: 'as-skeleton',
    description: 'El marcador de un contenido que todavía se está cargando.',
    affects: [],
    code: `<as-skeleton layout="line" [lines]="2" />`,
  },
  {
    id: 'tooltip',
    label: 'Tooltip',
    selector: '[asTooltip]',
    description: 'Un texto flotante que aparece al pasar el cursor por cualquier elemento.',
    affects: ['Radio de bordes', 'Tamaño de fuente'],
    code: `<as-button label="Ayuda" asTooltip="Texto de ayuda" tooltipPosition="top" />`,
  },
  {
    id: 'modal',
    label: 'Modal',
    selector: 'as-modal',
    description: 'Un diálogo sobre la página, con título, pie y cierre con Escape.',
    affects: ['Densidad', 'Tamaño de fuente'],
    code: `<as-modal [(visible)]="open" title="Título">Contenido</as-modal>`,
  },
  {
    id: 'drawer',
    label: 'Panel lateral',
    selector: 'as-drawer',
    description: 'Un panel que entra por un lado de la pantalla.',
    affects: ['Tamaño de fuente'],
    code: `<as-drawer [(visible)]="open" position="right">Contenido</as-drawer>`,
  },
  {
    id: 'toast',
    label: 'Toast',
    selector: 'as-toast',
    description: 'Avisos breves; se muestran con AlertService y se alojan en el layout.',
    affects: ['Tamaño de fuente'],
    code: `private readonly alerts = inject(AlertService);

this.alerts.showSuccess('Guardado', 'Los cambios se guardaron.');`,
  },
  {
    id: 'tabs',
    label: 'Pestañas',
    selector: 'as-tabs',
    description: 'Pestañas con desplazamiento y flechas cuando no caben.',
    affects: ['Tamaño de fuente'],
    code: `<as-tabs [tabs]="tabs" [(active)]="active" ariaLabel="Secciones" />`,
  },
  {
    id: 'popover',
    label: 'Popover',
    selector: 'as-popover',
    description: 'Un panel anclado a un botón, que se cierra al hacer clic fuera.',
    affects: ['Radio de bordes', 'Tamaño de fuente'],
    code: `<as-popover triggerIcon="Ellipsis">Contenido del popover</as-popover>`,
  },
];
