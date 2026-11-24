import { NgComponentOutlet } from '@angular/common';
import { ChangeDetectionStrategy, Component, type Signal, type Type, computed, inject, signal } from '@angular/core';
import { FormControl, ReactiveFormsModule } from '@angular/forms';

import { SaAvatar, SaButton, SaCheckbox, SaDivider, SaDrawer, SaIcon, SaInput, SaModal, SaPopover, SaSelect, SaSkeleton, SaTabs, SaTextarea, SaToggle, SaTooltip, type SaTab } from '@shared/components';
import { AlertService } from '@shared/services';
import type { ToastPosition } from '@shared/components/sa-toast/sa-toast.types';
import { ACTIONS, UI_COMPONENTS, codeOfVariant, groupsOf, type UiComponentEntry, type UiOption, type UiVariant } from './ui-system.catalog';
import { inputsOf, type UiProps } from './ui-system.code';

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
  imports: [NgComponentOutlet, ReactiveFormsModule, SaButton, SaCheckbox, SaDrawer, SaInput, SaModal, SaSelect, SaTabs, SaToggle, SaTooltip],
  templateUrl: './ui-system.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class UiSystem {
  private readonly alertService = inject(AlertService);

  readonly components = UI_COMPONENTS;
  readonly groupsOf = groupsOf;
  /** El componente que pinta, tal cual, las variantes de cada tarjeta (el resto tiene su propia plantilla). */
  readonly outlets: Readonly<Record<string, Type<unknown>>> = { icon: SaIcon, button: SaButton, input: SaInput, textarea: SaTextarea, select: SaSelect, toggle: SaToggle, avatar: SaAvatar, skeleton: SaSkeleton, divider: SaDivider, popover: SaPopover };

  /** Lo que se escribe en el buscador. */
  readonly query = signal('');
  /** Los componentes cuya vista previa está oculta. */
  private readonly hidden = signal<ReadonlySet<string>>(new Set());
  /** La variante elegida de cada componente (su id); sin elegir, la primera. */
  private readonly chosen = signal<Readonly<Record<string, string>>>({});
  /** El estado de los interruptores de modal y panel, por `componente/opción`. */
  private readonly switches = signal<Readonly<Record<string, boolean>>>({});
  /** Los componentes cuyo código de todas las variantes está desplegado. */
  private readonly codeOpen = signal<ReadonlySet<string>>(new Set());
  /** La pestaña activa de cada ejemplo, por variante: ninguno comparte estado con otro. */
  private readonly ownActive = signal<Readonly<Record<string, string>>>({});
  /** Las contraseñas que se están viendo, por variante. */
  private readonly shownPasswords = signal<ReadonlySet<string>>(new Set());

  readonly filtered = computed(() => {
    const text = this.query().trim().toLowerCase();
    if (!text) return this.components;
    return this.components.filter((entry) => `${entry.label} ${entry.selector} ${entry.description}`.toLowerCase().includes(text));
  });

  // Datos de las vistas previas.
  readonly modalOpen = signal(false);
  readonly drawerOpen = signal(false);
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
  readonly actionItems = ACTIONS;
  /** Un control por selector de solo lectura de la vista previa, con un valor elegido para que se vea cómo luce. */
  readonly readonlySelects: Readonly<Record<string, FormControl<unknown>>> = Object.fromEntries(
    entryOf('select')
      .variants.filter((item) => item.props['readonlyInput'] === true)
      .map((item) => [item.id, new FormControl<unknown>('pro')]),
  );
  /** Un control por casilla de la vista previa: su estado sale de la variante. */
  readonly checkboxes: Readonly<Record<string, FormControl<boolean | null>>> = Object.fromEntries(
    entryOf('checkbox').variants.map((item) => [item.id, new FormControl({ value: item.props['checked'] === true, disabled: item.props['disabled'] === true })]),
  );

  /** El código de todas las variantes de cada componente, uno por tarjeta: solo cambia con los interruptores de esa tarjeta. */
  readonly allCode: Readonly<Record<string, Signal<string>>> = Object.fromEntries(UI_COMPONENTS.map((entry) => [entry.id, computed(() => this.allCodeOf(entry))]));

  /** Lo que recibe el modal abierto y el panel abierto. */
  readonly modalInputs = computed(() => inputsOf(this.propsOf(entryOf('modal'))) as ModalInputs);
  readonly drawerInputs = computed(() => inputsOf(this.propsOf(entryOf('drawer'))) as DrawerInputs);
  readonly drawerFooter = computed(() => this.isOptionOn(entryOf('drawer'), { id: 'footer', label: '' }));
  readonly drawerLong = computed(() => this.isOptionOn(entryOf('drawer'), { id: 'long', label: '' }));
  readonly modalLong = computed(() => this.isOptionOn(entryOf('modal'), { id: 'long', label: '' }));
  /** Un texto largo para ver la barra de desplazamiento en el borde del modal y del panel. */
  readonly longText = Array.from({ length: 24 }, (_, index) => `Línea ${index + 1} de un contenido largo que se desplaza.`);

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

  /** La pestaña activa de un ejemplo: la suya, que empieza en la primera. */
  activeOf(item: UiVariant): string {
    return this.ownActive()[item.id] ?? 'one';
  }

  setActive(item: UiVariant, id: string): void {
    this.ownActive.update((current) => ({ ...current, [item.id]: id }));
  }

  isPasswordShown(item: UiVariant): boolean {
    return this.shownPasswords().has(item.id);
  }

  togglePassword(item: UiVariant): void {
    this.shownPasswords.update((current) => {
      const next = new Set(current);
      if (!next.delete(item.id)) next.add(item.id);
      return next;
    });
  }

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

  /** Las propiedades de lo que se muestra: las de la variante elegida y las de los interruptores que cambiaron. */
  private propsOf(entry: UiComponentEntry, item: UiVariant = this.selectedOf(entry)): UiProps {
    const extra: Record<string, string | number | boolean> = {};
    for (const option of entry.options ?? []) {
      if (!option.prop) continue;
      const on = this.isOptionOn(entry, option);
      if (on === (option.startsOn ?? false)) continue;
      extra[option.prop] = (on ? option.on : option.off) ?? on;
    }
    return { ...entry.baseProps, ...item.props, ...extra };
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

  /** Abre el modal o el panel con la variante pedida (y la deja elegida, para que el código la siga). */
  openOverlay(entry: UiComponentEntry, item: UiVariant): void {
    this.choose(entry, item);
    if (entry.id === 'modal') this.modalOpen.set(true);
    else this.drawerOpen.set(true);
  }

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
}
