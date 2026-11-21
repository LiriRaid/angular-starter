import { NgComponentOutlet } from '@angular/common';
import { ChangeDetectionStrategy, Component, type Type, computed, inject, signal } from '@angular/core';
import { FormControl, ReactiveFormsModule } from '@angular/forms';

import { AsAvatar, AsButton, AsCheckbox, AsDivider, AsDrawer, AsIcon, AsInput, AsModal, AsPopover, AsSelect, AsSkeleton, AsTabs, AsTextarea, AsToggle, AsTooltip, type AsTab } from '@shared/components';
import { AlertService } from '@shared/services';
import { ACTIONS, UI_COMPONENTS, codeOfVariant, groupsOf, type UiComponentEntry, type UiOption, type UiVariant } from './ui-system.catalog';
import { inputsOf, type UiProps } from './ui-system.code';

/** Lo que recibe el modal de la vista previa: las propiedades de la variante elegida y de los interruptores. */
interface ModalInputs {
  readonly width?: string;
  readonly variant?: 'default' | 'preview';
  readonly showFooter?: boolean;
  readonly closable?: boolean;
  readonly dismissableMask?: boolean;
  readonly titleIcon?: string;
  readonly titleDotColor?: string;
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
}

const entryOf = (id: string): UiComponentEntry => UI_COMPONENTS.find((entry) => entry.id === id) as UiComponentEntry;

/**
 * El UI System (ADR-0010, ADR-0012): el catálogo de los componentes `as-` instalados, cada uno con todas
 * sus variantes a la vista, el código de la que se elige y los tokens de la pestaña UI que lo cambian.
 * Las variantes son solo de este catálogo: los tokens (radio, tamaño de botones, densidad, tamaño de
 * fuente) siguen cambiando por variables CSS y todas las vistas previas los siguen.
 */
@Component({
  selector: '__PREFIX__-ui-system',
  imports: [NgComponentOutlet, ReactiveFormsModule, AsButton, AsCheckbox, AsDivider, AsDrawer, AsModal, AsPopover, AsTabs, AsToggle, AsTooltip],
  templateUrl: './ui-system.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class UiSystem {
  private readonly alertService = inject(AlertService);

  readonly components = UI_COMPONENTS;
  readonly groupsOf = groupsOf;
  /** El componente que pinta, tal cual, las variantes de cada tarjeta (el resto tiene su propia plantilla). */
  readonly outlets: Readonly<Record<string, Type<unknown>>> = { icon: AsIcon, button: AsButton, input: AsInput, textarea: AsTextarea, select: AsSelect, toggle: AsToggle, avatar: AsAvatar, skeleton: AsSkeleton };

  /** Lo que se escribe en el buscador. */
  readonly query = signal('');
  /** Los componentes cuya vista previa está oculta. */
  private readonly hidden = signal<ReadonlySet<string>>(new Set());
  /** La variante elegida de cada componente (su id); sin elegir, la primera. */
  private readonly chosen = signal<Readonly<Record<string, string>>>({});
  /** El estado de los interruptores de modal y panel, por `componente/opción`. */
  private readonly switches = signal<Readonly<Record<string, boolean>>>({});

  readonly filtered = computed(() => {
    const text = this.query().trim().toLowerCase();
    if (!text) return this.components;
    return this.components.filter((entry) => `${entry.label} ${entry.selector} ${entry.description}`.toLowerCase().includes(text));
  });

  // Datos de las vistas previas.
  readonly modalOpen = signal(false);
  readonly drawerOpen = signal(false);
  readonly tabs: readonly AsTab[] = [
    { id: 'one', label: 'Uno' },
    { id: 'two', label: 'Dos' },
    { id: 'three', label: 'Tres' },
  ];
  readonly iconTabs: readonly AsTab[] = [
    { id: 'one', label: 'Inicio', icon: 'Home' },
    { id: 'two', label: 'Buscar', icon: 'Search' },
    { id: 'three', icon: 'Settings' },
  ];
  readonly countTabs: readonly AsTab[] = [
    { id: 'one', label: 'Todos', count: 12 },
    { id: 'two', label: 'Pendientes', count: 3, countTone: 'danger' },
    { id: 'three', label: 'Cerrados' },
  ];
  readonly activeTab = signal('one');
  readonly actionItems = ACTIONS;
  /** Un control por casilla de la vista previa: su estado sale de la variante. */
  readonly checkboxes: Readonly<Record<string, FormControl<boolean | null>>> = Object.fromEntries(
    entryOf('checkbox').variants.map((item) => [item.id, new FormControl({ value: item.props['checked'] === true, disabled: item.props['disabled'] === true })]),
  );

  /** El código de todas las variantes de cada componente; solo cambia con los interruptores. */
  readonly allCode = computed(() => Object.fromEntries(UI_COMPONENTS.map((entry) => [entry.id, this.allCodeOf(entry)])));

  /** Lo que recibe el modal abierto y el panel abierto. */
  readonly modalInputs = computed(() => inputsOf(this.propsOf(entryOf('modal'))) as ModalInputs);
  readonly drawerInputs = computed(() => inputsOf(this.propsOf(entryOf('drawer'))) as DrawerInputs);
  readonly drawerFooter = computed(() => this.isOptionOn(entryOf('drawer'), { id: 'footer', label: '' }));

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

  /** Las propiedades de lo que se muestra: las de la variante elegida y las de los interruptores que cambiaron. */
  private propsOf(entry: UiComponentEntry, item: UiVariant = this.selectedOf(entry)): UiProps {
    const extra: Record<string, string | number | boolean> = {};
    for (const option of entry.options ?? []) {
      if (!option.prop) continue;
      const on = this.isOptionOn(entry, option);
      if (on === (option.startsOn ?? false)) continue;
      extra[option.prop] = (on ? option.on : option.off) ?? on;
    }
    return { ...item.props, ...extra };
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
    const position = item.props['position'] as 'top-left' | 'top-right' | 'bottom-left' | 'bottom-center' | 'bottom-right' | 'center' | undefined;
    const title = String(item.props['title']);
    const message = String(item.props['message']);
    switch (item.props['method']) {
      case 'showInfo':
        this.alertService.showInfo(title, message, undefined, undefined, position);
        break;
      case 'showWarning':
        this.alertService.showWarning(title, message);
        break;
      case 'showError':
        this.alertService.showError(title, message);
        break;
      case 'showSecondary':
        this.alertService.showSecondary(title, message);
        break;
      case 'showContrast':
        this.alertService.showContrast(title, message);
        break;
      case 'showLoading':
        this.alertService.showLoading(title, message);
        break;
      default:
        this.alertService.showSuccess(title, message);
    }
  }

  /** Las pestañas de la variante: las de siempre, con iconos o con contador. */
  tabsOf(item: UiVariant): readonly AsTab[] {
    const binding = item.props['[tabs]'];
    if (binding === 'iconTabs') return this.iconTabs;
    if (binding === 'countTabs') return this.countTabs;
    return this.tabs;
  }
}
