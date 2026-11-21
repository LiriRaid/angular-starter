import { NgClass, NgTemplateOutlet } from '@angular/common';
import { afterNextRender, ChangeDetectionStrategy, Component, computed, DestroyRef, ElementRef, forwardRef, inject, Injector, input, output, signal, viewChild, ViewEncapsulation } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { AbstractControl, ControlValueAccessor, FormsModule, NG_VALUE_ACCESSOR, NgControl } from '@angular/forms';

import { LucideIconName } from '@core/common/icons/lucide-icons';
import { deriveInitials } from '@shared/utils/derive-initials';
import { accentFor } from '@shared/utils/avatar-accent';
import { AsAvatar } from '../as-avatar/as-avatar';
import { AsIcon } from '../as-icon/as-icon';
import { createSelectInteractions } from './as-select.interactions';
import { SELECT_ALL_VALUE, coerceBooleanAttribute, createSelectAllOption, createSelectPresentation, getSelectPanelLayout, normalizeSelectValue, pluckOption } from './as-select.config';
import type { AsIconPosition, AsSelectVariant } from './as-select.entity';

@Component({
  selector: 'as-select',
  standalone: true,
  imports: [NgClass, NgTemplateOutlet, FormsModule, AsIcon, AsAvatar],
  templateUrl: './as-select.html',
  styleUrl: './as-select.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
  providers: [{ provide: NG_VALUE_ACCESSOR, useExisting: forwardRef(() => AsSelect), multi: true }],
})
export class AsSelect implements ControlValueAccessor {
  private static nextId = 0;

  private readonly triggerRef = viewChild<ElementRef<HTMLElement>>('triggerRef');
  private readonly panelRef = viewChild<ElementRef<HTMLElement>>('panelRef');
  private readonly multiSearchInput = viewChild<ElementRef<HTMLInputElement>>('multiSearchInput');

  /** Nombre del campo de cada opción (dentro del objeto que ya viene en `options()`) que trae el
   *  dato a pintar por opción — evita que cada consumidor tenga que armar su propio template
   *  para lo mismo (avatar de agente, color de estado/prioridad, ícono de canal). Si el campo no
   *  existe en una opción puntual, esa fila cae al texto plano de siempre. */
  readonly optionAvatar = input<string | undefined>(undefined);
  /** Campo con el texto corto del avatar — si no se define, cae a las iniciales del label. */
  readonly optionAvatarLabel = input<string | undefined>(undefined);
  readonly optionAvatarShape = input<'circle' | 'rounded'>('circle');
  /** Campo con el estado de presencia (`online`, `away`, `busy`…) de cada opción: solo aplica junto a
   *  `optionAvatar` y dibuja el punto de presencia sobre el avatar. Sin definir, el avatar no lleva punto. */
  readonly optionPresence = input<string | undefined>(undefined);
  readonly optionIcon = input<string | undefined>(undefined);
  readonly optionColor = input<string | undefined>(undefined);
  /** Cómo dibujar el color/ícono de cada opción: `'chip'` = píldora con fondo tintado, `'bar'` =
   *  barrita vertical, `'box'` = ícono en caja tintada, `'dot'` (default) = punto simple. */
  readonly optionShape = input<'dot' | 'chip' | 'bar' | 'box'>('dot');
  /** Tamaño del ícono de cada opción cuando no hay `optionShape` de caja/chip (rama plana). */
  readonly optionIconSize = input<string | number>(14);
  /** Oculta el texto de la etiqueta en las filas de la lista y en el campo cerrado (select no buscable), para selects "solo ícono". */
  readonly hideOptionLabel = input<boolean>(false);
  /** Tiñe el fondo del CAMPO con una mezcla suave de este color; sin definir, el fondo de siempre. */
  readonly accentColor = input<string | undefined>(undefined);
  /** Clase(s) extra del panel desplegable, para escopar estilos propios sin tocar `.as-select-panel`, compartida por todos los selects. */
  readonly panelStyleClass = input<string>('');

  readonly options = input<unknown[]>([]);
  readonly optionLabel = input<string | undefined>(undefined);
  readonly optionValue = input<string | undefined>(undefined);
  readonly placeholder = input<string>('');
  readonly label = input<string | undefined>(undefined);
  /** Marca visual (*) junto al label — no valida nada por sí solo, solo indica visualmente que
   *  el campo es requerido (el `Validators.required` real vive en el `FormControl`). */
  readonly required = input<boolean>(false);
  readonly inputId = input<string>('');

  readonly variant = input<AsSelectVariant>('on');
  readonly lucideIcon = input<LucideIconName | ''>('');
  readonly iconPosition = input<AsIconPosition>('left');
  readonly searchable = input<boolean>(true);
  readonly multiselect = input<boolean | string>(false);
  readonly showClear = input<boolean>(false);
  readonly showErrorMessage = input<boolean>(true);
  readonly readonlyInput = input<boolean | string>(false);
  /** Bloquea abrir/cambiar el select sin aplicar la apariencia visual de disabled. */
  readonly interactionDisabled = input<boolean | string>(false);

  readonly valueChange = output<unknown>();

  readonly isDisabled = signal(false);
  readonly isFocused = signal(false);
  readonly searchTerm = signal('');
  readonly isOpen = signal(false);
  readonly activeIndex = signal<number | null>(null);

  private readonly injector = inject(Injector);
  private readonly destroyRef = inject(DestroyRef);

  private readonly validationTick = signal(0);
  private readonly valueSig = signal<unknown>(null);
  private readonly generatedId = `as-select-${AsSelect.nextId++}`;
  private readonly preservePanelOpen = signal(false);

  private ngControl?: NgControl;

  onChange: (value: unknown) => void = () => {};
  onTouched: () => void = () => {};

  readonly isInteractionDisabled = computed(() => coerceBooleanAttribute(this.interactionDisabled()));

  /** Si el select tiene `[optionAvatar]` configurado — muestra siempre el avatar (aunque la
   *  opción puntual no traiga foto, `as-avatar` ya cae solo a las iniciales). */
  readonly hasAvatarOption = computed(() => !!this.optionAvatar());

  private readonly presentation = createSelectPresentation({
    control: () => this.control,
    validationTick: this.validationTick,
    multiselect: this.multiselect,
    readonlyInput: this.readonlyInput,
    isInteractionDisabled: () => this.isInteractionDisabled(),
    value: this.valueSig,
    options: this.options,
    optionLabel: this.optionLabel,
    optionValue: this.optionValue,
    searchTerm: this.searchTerm,
    searchable: this.searchable,
    placeholder: this.placeholder,
    label: this.label,
    inputId: this.inputId,
    generatedId: this.generatedId,
    showErrorMessage: this.showErrorMessage,
    lucideIcon: this.lucideIcon,
    iconPosition: this.iconPosition,
    isFocused: this.isFocused,
    isDisabled: this.isDisabled,
    variant: this.variant,
    currentValues: () => this.currentValues(),
    optionValueOf: (option) => this.optionValueOf(option),
    labelForOption: (option) => this.labelForOption(option),
    selectAllOption: () => this.selectAllOption(),
  });

  readonly isMultiSelect = this.presentation.isMultiSelect;
  readonly isCompactMultiSelect = this.presentation.isCompactMultiSelect;
  readonly isCompactSingleSelect = this.presentation.isCompactSingleSelect;
  readonly isAnyMultiSelect = this.presentation.isAnyMultiSelect;
  readonly readonly = this.presentation.readonly;
  readonly value = this.presentation.value;
  readonly selectedCount = this.presentation.selectedCount;
  readonly hasIcon = this.presentation.hasIcon;
  readonly hasLeftIcon = this.presentation.hasLeftIcon;
  readonly resolvedInputId = this.presentation.resolvedInputId;
  readonly errorId = this.presentation.errorId;
  readonly hasValue = this.presentation.hasValue;
  readonly displayOptions = this.presentation.displayOptions;
  readonly multiselectOptions = this.presentation.multiselectOptions;
  readonly selectedOptions = this.presentation.selectedOptions;
  readonly allVisibleSelected = this.presentation.allVisibleSelected;
  readonly hasErrors = this.presentation.hasErrors;
  readonly errorMessage = this.presentation.errorMessage;
  readonly describedBy = this.presentation.describedBy;
  readonly shouldFloat = this.presentation.shouldFloat;
  readonly shouldFloatLabel = this.presentation.shouldFloatLabel;
  readonly multiSearchPlaceholder = this.presentation.multiSearchPlaceholder;
  readonly legendOffset = this.presentation.legendOffset;
  readonly legendMaxWidth = this.presentation.legendMaxWidth;
  readonly legendTransition = this.presentation.legendTransition;
  readonly fieldsetBoxShadow = this.presentation.fieldsetBoxShadow;
  readonly fieldsetClasses = this.presentation.fieldsetClasses;
  /** Fondo propio del campo cuando hay `accentColor` y el campo está habilitado; `null` deja el de las clases. */
  readonly fieldsetBackground = computed(() => {
    const accent = this.accentColor();
    if (!accent || this.isDisabled() || this.readonly() || this.isInteractionDisabled()) return null;

    return `color-mix(in srgb, ${accent} 14%, var(--app-control-surface-bg))`;
  });
  readonly labelBackground = this.presentation.labelBackground;
  readonly labelColor = this.presentation.labelColor;
  readonly labelClass = this.presentation.labelClass;

  /** currentValues()/selectedOptions() del presentation están pensados para arrays
   *  (multiselect) y siempre devuelven vacío en single-select — para el input editable hace
   *  falta resolver la opción seleccionada buscando por value() directamente. Público: el
   *  trigger no-searchable (ver más abajo) también la necesita para pintar `richOptionLabel`. */
  readonly resolvedSelectedOption = () => this.options().find((option) => this.optionValueOf(option) === this.value()) ?? null;

  /** Texto mostrado en el input editable de single-select: el término tipeado mientras se
   *  busca, o el label de la opción seleccionada cuando no se está escribiendo. */
  readonly editableValue = () => this.searchTerm() || (this.hasValue() ? this.labelForOption(this.resolvedSelectedOption()) : '');

  readonly activeOptions = () => (this.isAnyMultiSelect() ? this.multiselectOptions() : this.displayOptions());

  private readonly interactions = createSelectInteractions({
    isMultiSelect: this.isMultiSelect,
    isAnyMultiSelect: this.isAnyMultiSelect,
    searchable: this.searchable,
    isDisabled: this.isDisabled,
    readonly: this.readonly,
    interactionDisabled: () => this.isInteractionDisabled(),
    hasValue: this.hasValue,
    allVisibleSelected: this.allVisibleSelected,
    currentValues: () => this.currentValues(),
    visibleOptionValues: () => this.visibleOptionValues(),
    optionValueOf: (option) => this.optionValueOf(option),
    isValidOptionValue: (value) => this.isValidOptionValue(value),
    setSearchTerm: (value) => this.searchTerm.set(value),
    setFocused: (value) => this.isFocused.set(value),
    setValue: (value) => this.valueSig.set(value),
    emitValue: (value) => this.emitValue(value),
    refreshValidation: () => this.refreshValidation(),
    touch: () => this.onTouched(),
    multiSearchInput: () => this.multiSearchInput(),
    preservePanelOpen: this.preservePanelOpen,
    isOpen: this.isOpen,
    showPanel: () => this.showPanel(),
    hidePanel: () => this.hidePanel(),
    activeOptions: this.activeOptions,
    activeIndex: this.activeIndex,
    isSelectAllOption: (option) => this.isSelectAllOption(option),
  });

  readonly onSelectChange = this.interactions.onSelectChange;
  readonly onFocus = this.interactions.onFocus;
  readonly onBlur = this.interactions.onBlur;
  readonly onEditableTriggerPointer = this.interactions.onEditableTriggerPointer;
  readonly onMultiSelectSearchPointer = this.interactions.onMultiSelectSearchPointer;
  readonly onMultiSelectSearchInput = this.interactions.onMultiSelectSearchInput;
  readonly onSelectedChipPointer = this.interactions.onSelectedChipPointer;
  readonly onChipRemovePointer = this.interactions.onChipRemovePointer;
  readonly removeSelectedOption = this.interactions.removeSelectedOption;
  readonly toggleAllVisibleOptions = this.interactions.toggleAllVisibleOptions;
  readonly selectOption = this.interactions.selectOption;
  readonly clearValue = this.interactions.clearValue;
  readonly openPanel = this.interactions.openPanel;
  readonly togglePanel = this.interactions.togglePanel;
  readonly closePanel = this.interactions.closePanel;
  readonly onTriggerKeydown = this.interactions.onTriggerKeydown;

  constructor() {
    afterNextRender(() => {
      this.ngControl = this.injector.get(NgControl, null) || undefined;
      this.control?.events.pipe(takeUntilDestroyed(this.destroyRef)).subscribe(() => this.refreshValidation());
    });

    // Browser only: there is no window while the server renders.
    if (typeof window === 'undefined') return;
    this.destroyRef.onDestroy(() => window.removeEventListener('resize', this.onWindowResize));
    window.addEventListener('resize', this.onWindowResize);
  }

  /** Igual que as-popover: showPopover()/hidePopover() se llaman directo y
   *  sincrónicamente desde el handler del click, en vez de reaccionar a un signal vía
   *  effect(). Si se derivara de un signal, un click sobre un elemento fuera del panel (la
   *  flechita del dropdown) dispara primero el light-dismiss nativo del navegador — si en ese
   *  momento el signal ya valía true, set(true) de nuevo no notifica (mismo valor) y el
   *  panel se queda cerrado sin volver a abrirse. Por la misma razón, todo lo que abre el
   *  panel debe hacerlo en (click), nunca en (mousedown): abrir en mousedown deja que el
   *  propio light-dismiss nativo cierre el panel dentro del mismo ciclo mousedown→mouseup de
   *  esa interacción, antes de que termine. */
  showPanel(): void {
    const panel = this.panelRef()?.nativeElement;
    if (!panel) return;

    if (!panel.matches(':popover-open')) panel.showPopover();
    this.isOpen.set(true);
    requestAnimationFrame(() => this.positionPanel());
  }

  hidePanel(): void {
    const panel = this.panelRef()?.nativeElement;
    this.isOpen.set(false);
    if (panel?.matches(':popover-open')) panel.hidePopover();
  }

  onEditableFocus(): void {
    this.onFocus();
  }

  /** A diferencia de as-popover/as-theme-color-picker (que usan `popover="manual"`
   *  y por eso arman a mano su propio outside-click/Escape con NativeOverlayRuntime), este panel
   *  usa `popover` en modo auto (ver template): el navegador ya da gratis el light-dismiss por
   *  click afuera y por Escape. Lo único que falta cubrir a mano es el reposicionamiento en
   *  resize — de ahí que no haga falta ninguno de los helpers de native-overlay-dismiss.ts aquí. */
  private readonly onWindowResize = (): void => {
    if (this.isOpen()) this.positionPanel();
  };

  onPanelToggle(event: ToggleEvent): void {
    if (event.newState === 'closed' && this.isOpen()) {
      this.isOpen.set(false);
      this.activeIndex.set(null);
    }
  }

  isSelectAllOption(option: unknown): boolean {
    return this.optionValueOf(option) === SELECT_ALL_VALUE;
  }

  isOptionSelected(option: unknown): boolean {
    if (this.isSelectAllOption(option)) return this.allVisibleSelected();
    if (this.isAnyMultiSelect()) return this.currentValues().includes(this.optionValueOf(option));

    return this.optionValueOf(option) === this.value();
  }

  optionTrackValue(option: unknown): unknown {
    return this.optionValueOf(option) ?? this.labelForOption(option);
  }

  labelForOption(option: unknown): string {
    return String(this.pluck(option, this.optionLabel()) ?? '');
  }

  optionAvatarOf(option: unknown): string | undefined {
    const field = this.optionAvatar();
    return field ? ((this.pluck(option, field) as string | undefined) ?? undefined) : undefined;
  }

  optionIconOf(option: unknown): string | undefined {
    const field = this.optionIcon();
    return field ? ((this.pluck(option, field) as string | undefined) ?? undefined) : undefined;
  }

  optionColorOf(option: unknown): string | undefined {
    const field = this.optionColor();
    return field ? ((this.pluck(option, field) as string | undefined) ?? undefined) : undefined;
  }

  /** Color de fondo del avatar cuando no tiene imagen — el propio de la opción (`optionColor`,
   *  ej. el accent real de una marca) si vino, si no uno consistente por valor (mismo agente =
   *  mismo color siempre), mismo util que usa el resto de la app. */
  optionAccent(option: unknown): string {
    return this.optionColorOf(option) ?? accentFor(String(this.optionValueOf(option) ?? ''));
  }

  optionPresenceOf(option: unknown): string | undefined {
    const field = this.optionPresence();
    const raw = field ? this.pluck(option, field) : undefined;
    return raw == null ? undefined : String(raw);
  }

  /** Texto corto del avatar — `optionAvatarLabel` si se definió; si no, las iniciales del label. */
  optionAvatarLabelOf(option: unknown): string {
    const field = this.optionAvatarLabel();
    const raw = field ? this.pluck(option, field) : undefined;
    return String(raw ?? deriveInitials(this.labelForOption(option)));
  }

  writeValue(value: unknown): void {
    this.valueSig.set(this.normalizeIncomingValue(value));
    this.searchTerm.set('');
    this.refreshValidation();
  }

  registerOnChange(fn: (value: unknown) => void): void {
    this.onChange = fn;
  }

  registerOnTouched(fn: () => void): void {
    this.onTouched = fn;
  }

  setDisabledState(isDisabled: boolean): void {
    this.isDisabled.set(isDisabled);
    this.refreshValidation();
  }

  private positionPanel(): void {
    const trigger = this.triggerRef()?.nativeElement;
    const panel = this.panelRef()?.nativeElement;
    if (!trigger || !panel) return;

    const triggerRect = trigger.getBoundingClientRect();
    const panelHeight = panel.getBoundingClientRect().height;
    const layout = getSelectPanelLayout(triggerRect, panelHeight, document.documentElement.clientWidth, document.documentElement.clientHeight);

    panel.style.top = `${layout.top}px`;
    panel.style.left = `${layout.left}px`;
    panel.style.width = `${layout.width}px`;
  }

  private get control(): AbstractControl | null {
    return this.ngControl?.control ?? null;
  }

  private emitValue(value: unknown): void {
    this.onChange(value);
    this.valueChange.emit(value);
    this.refreshValidation();
  }

  private visibleOptionValues(): unknown[] {
    return this.displayOptions().map((option) => this.optionValueOf(option));
  }

  private currentValues(): unknown[] {
    const value = this.valueSig();
    return Array.isArray(value) ? value : [];
  }

  private optionValueOf(option: unknown): unknown {
    return this.pluck(option, this.optionValue());
  }

  private isValidOptionValue(value: unknown): boolean {
    return this.options().some((option) => this.optionValueOf(option) === value);
  }

  private selectAllOption(): Record<string, unknown> {
    const labelKey = this.optionLabel() || 'label';
    const valueKey = this.optionValue() || 'value';

    return createSelectAllOption(labelKey, valueKey);
  }

  private pluck(option: unknown, key: string | undefined): unknown {
    return pluckOption(option, key);
  }

  private normalizeIncomingValue(value: unknown): unknown {
    return normalizeSelectValue(value, this.isAnyMultiSelect());
  }

  private refreshValidation(): void {
    this.validationTick.update((value) => value + 1);
  }
}
