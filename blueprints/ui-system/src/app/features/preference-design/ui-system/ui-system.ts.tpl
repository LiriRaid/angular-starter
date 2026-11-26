import { NgComponentOutlet } from '@angular/common';
import { ChangeDetectionStrategy, Component, type Signal, type Type, computed, inject, signal } from '@angular/core';
import { FormControl, ReactiveFormsModule } from '@angular/forms';

import {
  SaAvatar, // uis(avatar)
  SaButton,
  SaCheckbox, // uis(checkbox)
  SaDivider, // uis(divider)
  SaDrawer, // uis(drawer)
  SaIcon, // uis(icon)
  SaInput, // uis(input)
  SaModal, // uis(modal)
  SaPopover, // uis(popover)
  SaSearch, // uis(search)
  SaSelect, // uis(select)
  SaSkeleton, // uis(skeleton)
  SaTabs, // uis(tabs)
  SaTextarea, // uis(textarea)
  SaThemeColorPicker, // uis(theme-color-picker)
  SaToggle,
  SaTooltip, // uis(tooltip)
  type SaTab, // uis(tabs)
} from '@shared/components';
import { AlertService } from '@shared/services'; // uis(toast)
import type { ToastPosition } from '@shared/components/sa-toast/sa-toast.types'; // uis(toast)
import { ACTIONS, UI_COMPONENTS, codeOfVariant, groupsOf, type UiComponentEntry, type UiOption, type UiVariant } from './ui-system.catalog';
import { inputsOf, type UiProps } from './ui-system.code';

// uis:begin(modal)
/** Lo que recibe el modal de la vista previa: las propiedades de la variante elegida y de los interruptores. */
interface ModalInputs {
  readonly width?: string;
  readonly variant?: 'default' | 'preview';
  readonly showFooter?: boolean;
  readonly closable?: boolean;
  readonly dismissableMask?: boolean;
  readonly draggable?: boolean;
  readonly titleIcon?: string;
  readonly titleDotColor?: string;
  readonly flush?: boolean;
}
// uis:end

// uis:begin(drawer)
/** Lo que recibe el panel de la vista previa. */
interface DrawerInputs {
  readonly position?: 'left' | 'right' | 'top' | 'bottom' | 'full';
  readonly width?: string;
  readonly closable?: boolean;
  readonly dismissible?: boolean;
  readonly closeOnEscape?: boolean;
  readonly density?: 'comfortable' | 'compact';
  readonly flush?: boolean;
  readonly closeIcon?: string;
  readonly closeLabel?: string;
}
// uis:end

const entryOf = (id: string): UiComponentEntry => {
  const entry = UI_COMPONENTS.find((candidate) => candidate.id === id);
  if (!entry) throw new Error(`The UI System catalog has no "${id}".`);
  return entry;
};

/**
 * El UI System (ADR-0010, ADR-0012): el catálogo de los componentes `sa-` instalados, cada uno con todas
 * sus variantes a la vista, el código de la que se elige y los tokens de la pestaña UI que lo cambian.
 * Las variantes son solo de este catálogo: los tokens (radio, tamaño de botones, densidad, tamaño de
 * fuente) siguen cambiando por variables CSS y todas las vistas previas los siguen.
 */
@Component({
  selector: '__PREFIX__-ui-system',
  imports: [
    NgComponentOutlet,
    ReactiveFormsModule,
    SaButton,
    SaCheckbox, // uis(checkbox)
    SaDrawer, // uis(drawer)
    SaInput, // uis(input)
    SaModal, // uis(modal)
    SaSearch, // uis(search)
    SaSelect, // uis(select)
    SaTabs, // uis(tabs)
    SaToggle,
    SaTooltip, // uis(tooltip)
  ],
  templateUrl: './ui-system.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class UiSystem {
  private readonly alertService = inject(AlertService); // uis(toast)

  readonly components = UI_COMPONENTS;
  readonly groupsOf = groupsOf;
  /** El componente que pinta, tal cual, las variantes de cada tarjeta (el resto tiene su propia plantilla). */
  readonly outlets: Readonly<Record<string, Type<unknown>>> = {
    icon: SaIcon, // uis(icon)
    button: SaButton,
    input: SaInput, // uis(input)
    textarea: SaTextarea, // uis(textarea)
    select: SaSelect, // uis(select)
    toggle: SaToggle,
    avatar: SaAvatar, // uis(avatar)
    skeleton: SaSkeleton, // uis(skeleton)
    divider: SaDivider, // uis(divider)
    popover: SaPopover, // uis(popover)
    'theme-color-picker': SaThemeColorPicker, // uis(theme-color-picker)
  };

  /** Lo que se escribe en el buscador. */
  readonly query = signal('');
  // uis:begin(search)
  /** El control del buscador de la vista previa. */
  readonly searchControl = new FormControl('');
  /** El control del buscador colapsable, aparte: lo que se escribe ahí no aparece en los otros modos. */
  readonly collapsibleSearchControl = new FormControl('');
  /** Los buscadores colapsables (por variante) que están abiertos. */
  private readonly openedSearches = signal<ReadonlySet<string>>(new Set());

  /**
   * El modo con el que se dibuja el buscador de una variante. El colapsado funciona como el del sidebar:
   * el botón avisa, la vista decide el modo y el componente enfoca el campo al abrirse.
   */
  searchModeOf(item: UiVariant): string {
    const mode = String(item.inputs['mode'] ?? 'input');
    return mode === 'collapsed' && this.openedSearches().has(item.id) ? 'input' : mode;
  }

  searchControlOf(item: UiVariant): FormControl<string | null> {
    return item.inputs['mode'] === 'collapsed' ? this.collapsibleSearchControl : this.searchControl;
  }

  expandSearch(item: UiVariant): void {
    if (item.inputs['mode'] !== 'collapsed') return;
    this.openedSearches.update((current) => new Set(current).add(item.id));
  }

  /** Se cierra con Escape (borrando lo escrito) o al perder el foco vacío; con texto se queda abierto para no esconder un filtro activo. */
  collapseSearch(item: UiVariant, clear = false): void {
    if (item.inputs['mode'] !== 'collapsed') return;
    if (clear) this.collapsibleSearchControl.setValue('');
    if (this.collapsibleSearchControl.value) return;
    this.openedSearches.update((current) => {
      const next = new Set(current);
      next.delete(item.id);
      return next;
    });
  }

  /** Solo el campo al perder el foco colapsa: el botón, al desmontarse en el cambio de modo, también lo pierde. */
  onSearchFocusOut(item: UiVariant, event: FocusEvent): void {
    if ((event.target as Element | null)?.tagName === 'INPUT') this.collapseSearch(item);
  }
  // uis:end
  /** Los componentes cuya vista previa está oculta. */
  private readonly hidden = signal<ReadonlySet<string>>(new Set());
  /** La variante elegida de cada componente (su id); sin elegir, la primera. */
  private readonly chosen = signal<Readonly<Record<string, string>>>({});
  /** El estado de los interruptores de modal y panel, por `componente/opción`. */
  private readonly switches = signal<Readonly<Record<string, boolean>>>({});
  /** El modo elegido de cada tarjeta que tiene modos (`entry.modes`); sin elegir, el primero. */
  private readonly modeChoice = signal<Readonly<Record<string, string>>>({});
  /** Los componentes cuyo código de todas las variantes está desplegado. */
  private readonly codeOpen = signal<ReadonlySet<string>>(new Set());
  // uis:begin(tabs)
  /** La pestaña activa de cada ejemplo, por variante: ninguno comparte estado con otro. */
  private readonly ownActive = signal<Readonly<Record<string, string>>>({});
  // uis:end
  // uis:begin(input)
  /** Las contraseñas que se están viendo, por variante. */
  private readonly shownPasswords = signal<ReadonlySet<string>>(new Set());
  // uis:end

  readonly filtered = computed(() => {
    const text = this.query().trim().toLowerCase();
    if (!text) return this.components;
    return this.components.filter((entry) => `${entry.label} ${entry.selector} ${entry.description}`.toLowerCase().includes(text));
  });

  // Datos de las vistas previas.
  // uis:begin(modal)
  readonly modalOpen = signal(false);
  // uis:end
  // uis:begin(drawer)
  readonly drawerOpen = signal(false);
  // uis:end
  // uis:begin(tabs)
  readonly tabs: readonly SaTab[] = [
    { id: 'one', label: 'Uno' },
    { id: 'two', label: 'Dos' },
    { id: 'three', label: 'Tres' },
  ];
  readonly iconTabs: readonly SaTab[] = [
    { id: 'one', label: 'Uno', icon: 'Home' },
    { id: 'two', label: 'Dos', icon: 'Search' },
    { id: 'three', label: 'Tres', icon: 'Settings' },
  ];
  readonly countTabs: readonly SaTab[] = [
    { id: 'one', label: 'Todos', count: 12 },
    { id: 'two', label: 'Pendientes', count: 3, countTone: 'danger' },
    { id: 'three', label: 'Cerrados' },
  ];
  readonly manyIconTabs: readonly SaTab[] = [
    { id: 'one', label: 'Uno', icon: 'Home' },
    { id: 'two', label: 'Dos', icon: 'Search' },
    { id: 'three', label: 'Tres', icon: 'Users' },
    { id: 'four', label: 'Cuatro', icon: 'MessageCircle' },
    { id: 'five', label: 'Cinco', icon: 'Bell' },
    { id: 'six', label: 'Seis', icon: 'Folder' },
    { id: 'seven', label: 'Siete', icon: 'FileText' },
    { id: 'eight', label: 'Ocho', icon: 'Settings' },
  ];
  readonly manyCountTabs: readonly SaTab[] = [
    { id: 'one', label: 'Todos', count: 128 },
    { id: 'two', label: 'Pendientes', count: 12, countTone: 'danger' },
    { id: 'three', label: 'En curso', count: 24 },
    { id: 'four', label: 'Resueltos', count: 80 },
    { id: 'five', label: 'Archivados', count: 6 },
    { id: 'six', label: 'Borradores', count: 3 },
    { id: 'seven', label: 'Eliminados', count: 1 },
    { id: 'eight', label: 'Spam', count: 9 },
  ];
  // uis:end
  readonly actionItems = ACTIONS;
  // uis:begin(select)
  /** Un control por selector de solo lectura de la vista previa, con un valor elegido para que se vea cómo luce. */
  readonly readonlySelects: Readonly<Record<string, FormControl<unknown>>> = Object.fromEntries(
    entryOf('select')
      .variants.filter((item) => item.props['readonlyInput'] === true)
      .map((item) => [item.id, new FormControl<unknown>('pro')]),
  );
  // uis:end
  // uis:begin(checkbox)
  /** Un control por casilla de la vista previa: su estado sale de la variante. */
  readonly checkboxes: Readonly<Record<string, FormControl<boolean | null>>> = Object.fromEntries(
    entryOf('checkbox').variants.map((item) => [item.id, new FormControl({ value: item.props['checked'] === true, disabled: item.props['disabled'] === true })]),
  );
  // uis:end

  /** Lo que recibe cada vista previa de las tarjetas con modos: las propiedades de la variante, en el modo elegido. */
  private readonly modePreviews: Readonly<Record<string, Signal<Readonly<Record<string, Record<string, unknown>>>>>> = Object.fromEntries(
    UI_COMPONENTS.filter((entry) => entry.modes).map((entry) => [entry.id, computed(() => Object.fromEntries(entry.variants.map((item) => [item.id, inputsOf({ ...item.props, ...this.modeProps(entry, item) })])))]),
  );

  /** El código de todas las variantes de cada componente, uno por tarjeta: solo cambia con los interruptores de esa tarjeta. */
  readonly allCode: Readonly<Record<string, Signal<string>>> = Object.fromEntries(UI_COMPONENTS.map((entry) => [entry.id, computed(() => this.allCodeOf(entry))]));

  /** Lo que recibe el modal abierto y el panel abierto. */
  readonly modalInputs = computed(() => inputsOf(this.propsOf(entryOf('modal'))) as ModalInputs); // uis(modal)
  readonly drawerInputs = computed(() => inputsOf(this.propsOf(entryOf('drawer'))) as DrawerInputs); // uis(drawer)
  readonly drawerFooter = computed(() => this.isOptionOn(entryOf('drawer'), { id: 'footer', label: '' })); // uis(drawer)
  readonly drawerLong = computed(() => this.isOptionOn(entryOf('drawer'), { id: 'long', label: '' })); // uis(drawer)
  readonly modalLong = computed(() => this.isOptionOn(entryOf('modal'), { id: 'long', label: '' })); // uis(modal)
  // uis:begin(modal|drawer)
  /** Un texto largo para ver la barra de desplazamiento en el borde del modal y del panel. */
  readonly longText = Array.from({ length: 24 }, (_, index) => `Línea ${index + 1} de un contenido largo que se desplaza.`);
  // uis:end

  isShown(id: string): boolean {
    return !this.hidden().has(id);
  }

  setShown(id: string, shown: boolean): void {
    this.hidden.update((current) => {
      const next = new Set(current);
      if (shown) next.delete(id);
      else next.add(id);
      return next;
    });
  }

  /** La variante elegida de un componente. */
  selectedOf(entry: UiComponentEntry): UiVariant {
    return entry.variants.find((item) => item.id === this.chosen()[entry.id]) ?? entry.variants[0];
  }

  isSelected(entry: UiComponentEntry, item: UiVariant): boolean {
    return this.selectedOf(entry).id === item.id;
  }

  choose(entry: UiComponentEntry, item: UiVariant): void {
    this.chosen.update((current) => ({ ...current, [entry.id]: item.id }));
  }

  isOptionOn(entry: UiComponentEntry, option: Pick<UiOption, 'id'> & Partial<UiOption>): boolean {
    const declared = entry.options?.find((candidate) => candidate.id === option.id)?.startsOn ?? false;
    return this.switches()[`${entry.id}/${option.id}`] ?? declared;
  }

  setOption(entry: UiComponentEntry, option: UiOption, on: boolean): void {
    this.switches.update((current) => ({ ...current, [`${entry.id}/${option.id}`]: on }));
  }

  /** El modo elegido de una tarjeta con modos. */
  modeOf(entry: UiComponentEntry): string {
    return this.modeChoice()[entry.id] ?? entry.modes?.[0] ?? '';
  }

  setMode(entry: UiComponentEntry, mode: string): void {
    this.modeChoice.update((current) => ({ ...current, [entry.id]: mode }));
  }

  /** Lo que recibe la vista previa de una variante: sus propiedades, en el modo elegido de su tarjeta. */
  previewOf(entry: UiComponentEntry, item: UiVariant): Record<string, unknown> {
    return this.modePreviews[entry.id]?.()[item.id] ?? item.inputs;
  }

  isCodeOpen(id: string): boolean {
    return this.codeOpen().has(id);
  }

  toggleCode(id: string): void {
    this.codeOpen.update((current) => {
      const next = new Set(current);
      if (!next.delete(id)) next.add(id);
      return next;
    });
  }

  // uis:begin(tabs)
  /** La pestaña activa de un ejemplo: la suya, que empieza en la primera. */
  activeOf(item: UiVariant): string {
    return this.ownActive()[item.id] ?? 'one';
  }
  // uis:end

  // uis:begin(tabs)
  setActive(item: UiVariant, id: string): void {
    this.ownActive.update((current) => ({ ...current, [item.id]: id }));
  }
  // uis:end

  // uis:begin(input)
  isPasswordShown(item: UiVariant): boolean {
    return this.shownPasswords().has(item.id);
  }
  // uis:end

  // uis:begin(input)
  togglePassword(item: UiVariant): void {
    this.shownPasswords.update((current) => {
      const next = new Set(current);
      if (!next.delete(item.id)) next.add(item.id);
      return next;
    });
  }
  // uis:end

  /** Lo que se proyecta dentro del componente de una variante (el texto de un popover o de un separador), una sola vez por variante. */
  private readonly projected = new Map<string, Node[][]>();

  contentOf(entry: UiComponentEntry, item: UiVariant): Node[][] {
    const key = `${entry.id}/${item.id}`;
    let nodes = this.projected.get(key);
    if (!nodes) {
      if (entry.id === 'popover') {
        const text = document.createElement('p');
        text.className = 'w-48 p-3 text-caption-1-regular text-(--app-text-color)';
        text.textContent = item.text ?? '';
        nodes = [[], item.text ? [text] : []];
      } else {
        nodes = [item.text ? [document.createTextNode(item.text)] : []];
      }
      this.projected.set(key, nodes);
    }
    return nodes;
  }

  /** El modo que se le pone a una variante: ninguno si fija el suyo, si la tarjeta no tiene modos o si es el que el componente ya tiene. */
  private modeProps(entry: UiComponentEntry, item: UiVariant): UiProps {
    const modes = entry.modes;
    if (!modes || 'variant' in item.props) return {};
    const mode = this.modeOf(entry);
    return mode === modes[0] ? {} : { variant: mode };
  }

  /** Las propiedades de lo que se muestra: las de la variante elegida, en el modo elegido, y las de los interruptores que cambiaron. */
  private propsOf(entry: UiComponentEntry, item: UiVariant = this.selectedOf(entry)): UiProps {
    const extra: Record<string, string | number | boolean> = {};
    for (const option of entry.options ?? []) {
      if (!option.prop) continue;
      const on = this.isOptionOn(entry, option);
      if (on === (option.startsOn ?? false)) continue;
      extra[option.prop] = (on ? option.on : option.off) ?? on;
    }
    return { ...entry.baseProps, ...item.props, ...this.modeProps(entry, item), ...extra };
  }

  /** Las zonas activas: los interruptores que están encendidos. */
  private zonesOf(entry: UiComponentEntry): ReadonlySet<string> {
    return new Set((entry.options ?? []).filter((option) => this.isOptionOn(entry, option)).map((option) => option.id));
  }

  /** El código de la variante elegida (con lo que dicen los interruptores). */
  codeOf(entry: UiComponentEntry): string {
    const item = this.selectedOf(entry);
    return codeOfVariant(entry, item, this.propsOf(entry, item), this.zonesOf(entry));
  }

  /** El código de todas las variantes, con el nombre de cada grupo como comentario. */
  allCodeOf(entry: UiComponentEntry): string {
    const comment = (text: string) => (entry.language === 'ts' ? `// ${text}` : `<!-- ${text} -->`);
    return groupsOf(entry)
      .map((group) => [comment(group.name), ...group.variants.map((item) => codeOfVariant(entry, item, this.propsOf(entry, item), this.zonesOf(entry)))].join('\n'))
      .join('\n\n');
  }

  // uis:begin(modal|drawer)
  /** Abre el modal o el panel con la variante pedida (y la deja elegida, para que el código la siga). */
  openOverlay(entry: UiComponentEntry, item: UiVariant): void {
    this.choose(entry, item);
    if (entry.id === 'modal') this.modalOpen.set(true);
    else this.drawerOpen.set(true);
  }
  // uis:end

  // uis:begin(toast)
  showToast(item: UiVariant): void {
    this.choose(entryOf('toast'), item);
    const position = item.props['position'] as ToastPosition | undefined;
    const title = String(item.props['title']);
    const message = String(item.props['message']);
    const alerts = this.alertService;
    switch (item.props['method']) {
      case 'showInfo':
        alerts.showInfo(title, message, undefined, undefined, position);
        break;
      case 'showWarning':
        alerts.showWarning(title, message, undefined, undefined, false, position);
        break;
      case 'showError':
        alerts.showError(title, message, undefined, undefined, position);
        break;
      case 'showSecondary':
        alerts.showSecondary(title, message, undefined, undefined, position);
        break;
      case 'showContrast':
        alerts.showContrast(title, message, undefined, undefined, position);
        break;
      case 'showLoading':
        alerts.showLoading(title, message, undefined, undefined, position);
        break;
      default:
        alerts.showSuccess(title, message, undefined, undefined, position);
    }
  }
  // uis:end

  // uis:begin(tabs)
  /** Las pestañas de la variante: las de siempre, con iconos, con contador, o muchas para que no quepan. */
  tabsOf(item: UiVariant): readonly SaTab[] {
    switch (item.props['[tabs]']) {
      case 'iconTabs':
        return this.iconTabs;
      case 'countTabs':
        return this.countTabs;
      case 'manyIconTabs':
        return this.manyIconTabs;
      case 'manyCountTabs':
        return this.manyCountTabs;
      default:
        return this.tabs;
    }
  }
  // uis:end
}
