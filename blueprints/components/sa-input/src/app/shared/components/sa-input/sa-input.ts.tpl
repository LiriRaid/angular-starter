import { NgClass, NgStyle, NgTemplateOutlet } from '@angular/common';
import { afterNextRender, ChangeDetectionStrategy, Component, computed, DestroyRef, effect, ElementRef, forwardRef, inject, Injector, input, output, signal, viewChild } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { AbstractControl, ControlValueAccessor, FormsModule, NG_VALUE_ACCESSOR, NgControl, ReactiveFormsModule } from '@angular/forms';

import { AsButton } from '../as-button/as-button';
import { AsIcon } from '../as-icon/as-icon';
import { getSelectPanelLayout } from '../as-select/as-select.config';
import { LucideIconName } from '@core/common/icons/lucide-icons';
import { PHONE_COUNTRIES, type PhoneCountry } from '@shared/data/phone-countries';
import { groupNationalDigits, matchDialCode } from '@shared/utils/format-phone-number';
import { coerceReadonly, createInputPresentation, sanitizeDecimalInput, stepNumberValue, unformatPrice } from './as-input.config';
import type { AsIconPosition, AsInputType, AsVariant } from './as-input.entity';

@Component({
  selector: 'as-input',
  standalone: true,
  imports: [NgClass, NgStyle, NgTemplateOutlet, FormsModule, ReactiveFormsModule, AsIcon, AsButton],
  templateUrl: './as-input.html',
  styleUrl: './as-input.css',
  providers: [{ provide: NG_VALUE_ACCESSOR, useExisting: forwardRef(() => AsInput), multi: true }],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AsInput implements ControlValueAccessor {
  private static nextInputId = 0;

  readonly type = input<AsInputType>('text');
  readonly inputId = input<string>('');
  readonly placeholder = input<string>('');
  readonly label = input<string | undefined>(undefined);
  readonly value = input<string>('');
  readonly autocomplete = input<string>('');

  readonly isTagInput = input<boolean>(false);
  readonly tagPlaceholder = input<string>('Escribe para agregar un Tag');
  readonly currencySymbol = input<string>('$');

  readonly variant = input<AsVariant>('on');
  /** Marca visual (*) junto al label — no valida nada por sí solo, solo indica visualmente que
   *  el campo es requerido (el `Validators.required` real vive en el `FormControl`). */
  readonly required = input<boolean>(false);

  /** Modo teléfono con selector de código de país (bandera SVG real + código de marcación) —
   *  independiente de `variant` (esa solo posiciona el label). El valor del CVA siempre es el
   *  número completo ("+504 9699 1587"); el selector y el input de abajo solo lo componen/parsean. */
  readonly phoneCountryPicker = input<boolean>(false);
  /** País a mostrar mientras el valor está vacío (ver `applyIncomingPhoneValue`) — ej. el
   *  detectado por `detectRegionDefaults()` en vez de dejar el selector sin bandera. Sin
   *  efecto una vez que el usuario escribe o elige un país a mano (ese cambio no pasa por acá). */
  readonly defaultCountryIso2 = input<string>('');
  readonly phoneCountries = PHONE_COUNTRIES;
  readonly selectedDialCode = signal<string>('');
  // Varios países comparten el mismo dialCode (ej. "1" = NANP: EE.UU., Canadá, Puerto Rico,
  // American Samoa...) — con solo el dialCode, `.find()` siempre resolvería al primer país
  // alfabético de ese código, sin importar cuál se haya seleccionado realmente. Por eso se
  // guarda también el iso2 exacto elegido; solo cae a buscar por dialCode cuando el valor
  // llegó de afuera (ej. writeValue) y no se conoce el iso2 (ver applyIncomingPhoneValue).
  readonly selectedCountryIso2 = signal<string>('');
  readonly selectedCountry = computed(() => this.phoneCountries.find((c) => c.iso2 === this.selectedCountryIso2()) ?? this.phoneCountries.find((c) => c.dialCode === this.selectedDialCode()) ?? null);

  readonly dialCodeMenuOpen = signal(false);
  readonly countrySearch = signal('');
  readonly filteredPhoneCountries = computed(() => {
    const term = this.countrySearch().trim().toLowerCase();
    if (!term) return this.phoneCountries;
    return this.phoneCountries.filter((c) => c.name.toLowerCase().includes(term) || c.dialCode.includes(term));
  });

  readonly lucideIcon = input<LucideIconName | ''>('');
  readonly iconSize = input<number>(16);
  readonly iconPosition = input<AsIconPosition>('left');
  readonly iconClickable = input<boolean>(false);

  readonly showErrorMessage = input<boolean>(true);
  readonly readonlyInput = input<boolean | string>(false);

  /** Muestra los botones ▲▼ de incremento/decremento en inputs type="number". Son propios, no las flechas nativas
   *  (ver `stepNumberValue`); ↑/↓ y la rueda con el campo enfocado funcionan en todo input numérico. Solo afecta a la instancia que lo pida. */
  readonly showStepper = input<boolean>(false);

  /** Incremento de los botones, las flechas ↑/↓ y la rueda en inputs type="number" (ej. 0.1, 0.25, 5). Sin definir, 1. */
  readonly step = input<number | string | undefined>(undefined);

  /** Límites del input type="number": acotan el stepper (botones, flechas y rueda); sin definir, no hay tope. */
  readonly min = input<number | undefined>(undefined);
  readonly max = input<number | undefined>(undefined);

  /** Clases extra aplicadas directo al <input> real (ej. "placeholder:text-surface-200").
   *  Un [class] en el host de <as-input> no llega al input interno del template. */
  readonly inputClass = input<string>('');

  readonly readonly = computed<boolean>(() => {
    return coerceReadonly(this.readonlyInput());
  });

  readonly valueChange = output<string>();
  readonly tagsChange = output<string[]>();
  readonly iconClick = output<Event>();
  readonly keyup = output<KeyboardEvent>();

  readonly isDisabled = signal(false);
  readonly tags = signal<string[]>([]);
  readonly currentTagValue = signal('');
  readonly isFocused = signal(false);
  readonly isInputFocused = signal(false);
  readonly isPlaceholderVisible = signal(false);
  readonly isPlaceholderFading = signal(false);
  readonly transitionReady = signal(false);

  private readonly validationTick = signal(0);
  private placeholderTimer?: ReturnType<typeof setTimeout>;
  private readonly generatedInputId = `as-input-${AsInput.nextInputId++}`;

  private readonly valueSig = signal<string>('');

  // Cuando el input se usa con Reactive Forms (formControlName/[formControl]), Angular
  // llama a writeValue() para setear el valor — nunca se pasa `[value]`. El effect de abajo
  // sincroniza `valueSig` con el input `[value]` (para el uso SUELTO, sin formulario, ej. un
  // OTP que se autocompleta); si no se desactiva apenas llega el primer writeValue(), pisa
  // cada valor que ponga el formulario de vuelta al default vacío de `[value]`.
  private readonly formBound = signal(false);

  onChange: (value: string | string[]) => void = () => {};
  onTouched: () => void = () => {};

  private readonly injector = inject(Injector);
  private readonly destroyRef = inject(DestroyRef);
  private ngControl?: NgControl;

  // `read: ElementRef` es obligatorio acá: el ref apunta a un <as-button> (un componente),
  // y sin esto viewChild() devuelve la instancia del componente en vez del ElementRef — .nativeElement
  // sería undefined, positionCountryPanel() retornaría antes de tiempo, y el panel se quedaría
  // en su posición estática por defecto (esquina superior izquierda) en vez de bajo el trigger.
  private readonly dialCodeTrigger = viewChild('dialCodeTrigger', { read: ElementRef<HTMLElement> });
  private readonly countryPanel = viewChild<ElementRef<HTMLElement>>('countryPanel');

  constructor() {
    // Mantiene valueSig sincronizado con actualizaciones externas del input `value` (ej. un
    // componente padre marcando dígitos programáticamente vía signal), no solo con la escritura
    // inicial — sin esto, cambios al signal ligado a [value] después del primer render no se
    // reflejaban en el input. Solo aplica cuando el input NO está atado a un formulario.
    effect(() => {
      if (this.isTagInput() || this.formBound()) return;
      this.applyIncomingValue(this.value() ?? '');
    });

    // `defaultCountryIso2` no solo se lee una vez al montar (ver `applyIncomingPhoneValue`): si
    // cambia en vivo (ej. `add-contact-modal` vinculándolo a la "Zona horaria" elegida) y el
    // usuario todavía NO escribió ni eligió país a mano, el selector lo sigue. En cuanto hay un
    // país resuelto (a mano o porque el valor entrante ya traía uno real) deja de reaccionar —
    // nunca pisa una elección explícita.
    effect(() => {
      const iso2 = this.defaultCountryIso2();
      if (!iso2 || !this.phoneCountryPicker() || this.selectedCountryIso2() || this.selectedDialCode()) return;
      this.selectedCountryIso2.set(iso2);
    });

    afterNextRender(() => {
      this.ngControl = this.injector.get(NgControl, null) || undefined;

      this.control?.events.pipe(takeUntilDestroyed(this.destroyRef)).subscribe(() => this.refreshValidation());

      setTimeout(() => this.transitionReady.set(true), 0);
    });

    // Browser only: there is no window while the server renders.
    if (typeof window === 'undefined') return;
    this.destroyRef.onDestroy(() => window.removeEventListener('resize', this.onWindowResize));
    window.addEventListener('resize', this.onWindowResize);
  }

  private readonly onWindowResize = (): void => {
    if (this.dialCodeMenuOpen()) this.positionCountryPanel();
  };

  private get control(): AbstractControl | null {
    return this.ngControl?.control ?? null;
  }

  private refreshValidation(): void {
    this.validationTick.update((value) => value + 1);
  }

  readonly hasIcon = computed(() => !!this.lucideIcon());
  private readonly presentation = createInputPresentation({
    control: () => this.control,
    validationTick: this.validationTick,
    type: this.type,
    isTagInput: this.isTagInput,
    tags: this.tags,
    value: this.valueSig,
    label: this.label,
    placeholder: this.placeholder,
    inputId: this.inputId,
    generatedInputId: this.generatedInputId,
    showErrorMessage: this.showErrorMessage,
    isDisabled: this.isDisabled,
    readonly: this.readonly,
    isFocused: this.isFocused,
    isInputFocused: this.isInputFocused,
    variant: this.variant,
    hasIcon: this.hasIcon,
    iconPosition: this.iconPosition,
    showStepper: this.showStepper,
    phoneCountryPicker: this.phoneCountryPicker,
    phoneCountryIso2: () => this.selectedCountry()?.iso2,
  });

  /** Los botones ▲▼ solo existen en inputs numéricos que los pidieron (`showStepper`). */
  readonly hasNumberStepper = computed(() => this.type() === 'number' && this.showStepper());

  readonly hasErrors = this.presentation.hasErrors;
  readonly errorMessage = this.presentation.errorMessage;
  readonly displayValue = this.presentation.displayValue;
  readonly inputType = this.presentation.inputType;
  readonly showCurrencySymbol = this.presentation.showCurrencySymbol;
  readonly hasValue = this.presentation.hasValue;
  readonly hasLeftIcon = this.presentation.hasLeftIcon;
  readonly resolvedInputId = this.presentation.resolvedInputId;
  readonly errorId = this.presentation.errorId;
  readonly describedBy = this.presentation.describedBy;
  readonly shouldFloat = this.presentation.shouldFloat;
  readonly placeholderAttr = this.presentation.placeholderAttr;
  readonly inputFieldStyles = this.presentation.inputFieldStyles;
  readonly inputFieldNgClass = this.presentation.inputFieldNgClass;
  readonly inputBackground = this.presentation.inputBackground;
  readonly inputTextColor = this.presentation.inputTextColor;
  readonly inputBorderColor = this.presentation.inputBorderColor;
  readonly inputBoxShadow = this.presentation.inputBoxShadow;
  readonly tagContainerBackground = this.presentation.tagContainerBackground;
  readonly tagContainerBoxShadow = this.presentation.tagContainerBoxShadow;
  readonly legendOffset = this.presentation.legendOffset;
  readonly legendMaxWidth = this.presentation.legendMaxWidth;
  readonly legendTransition = this.presentation.legendTransition;
  readonly fieldsetClasses = this.presentation.fieldsetClasses;
  readonly fieldsetBoxShadow = this.presentation.fieldsetBoxShadow;
  readonly labelBackground = this.presentation.labelBackground;
  readonly labelColor = this.presentation.labelColor;
  readonly labelClass = this.presentation.labelClass;
  /** En `in` el label vive dentro, arriba, y las etiquetas empiezan debajo: 21px + el borde y el relleno de abajo dan los 54px de un input en `in`. */
  readonly tagsPaddingTop = computed(() => (this.variant() === 'in' && !!this.label() ? '1.3125rem' : null));

  writeValue(value: unknown): void {
    this.formBound.set(true);

    if (this.isTagInput()) {
      if (Array.isArray(value)) {
        this.tags.set([...value]);
      } else if (typeof value === 'string' && value) {
        this.tags.set(
          value
            .split(',')
            .map((tag) => tag.trim())
            .filter((tag) => tag),
        );
      } else {
        this.tags.set([]);
      }

      this.refreshValidation();
      return;
    }

    this.applyIncomingValue(value !== null && value !== undefined ? String(value) : '');
    this.refreshValidation();
  }

  /** Normaliza un valor entrante (input plano o CVA `writeValue`) antes de guardarlo en
   *  `valueSig` — el tipo `price` siempre se guarda "desformateado" (sin comas/símbolo). */
  private applyIncomingValue(raw: string): void {
    if (this.phoneCountryPicker()) {
      this.applyIncomingPhoneValue(raw);
      return;
    }
    this.valueSig.set(this.type() === 'price' ? unformatPrice(raw) : raw);
  }

  /** Separa un valor entrante ("+504 9699 1587") en código de país (selecciona el trigger) y
   *  número nacional (queda en el input) — prueba los códigos más largos primero para no
   *  confundir, ej. "+52" con el inicio de un código de 1 dígito. */
  private applyIncomingPhoneValue(raw: string): void {
    const trimmed = (raw ?? '').trim();
    if (!trimmed) {
      this.valueSig.set('');
      this.selectedDialCode.set('');
      this.selectedCountryIso2.set(this.defaultCountryIso2());
      return;
    }

    const withoutPlus = trimmed.startsWith('+') ? trimmed.slice(1) : trimmed;
    const match = matchDialCode(withoutPlus);

    if (match) {
      this.selectedDialCode.set(match.dialCode);
      // Un número crudo no identifica el país exacto cuando varios comparten dialCode (ej. "1")
      // — se resuelve al primer país alfabético de ese código, misma ambigüedad que ya existía.
      this.selectedCountryIso2.set(match.iso2);
      this.valueSig.set(withoutPlus.slice(match.dialCode.length).replace(/\D/g, ''));
    } else {
      // Sin match real conocido: no asumimos ningún país por defecto (sin fallback).
      this.selectedDialCode.set('');
      this.selectedCountryIso2.set('');
      this.valueSig.set(trimmed.replace(/\D/g, ''));
    }
  }

  onPhoneNumberInput(event: Event): void {
    const digits = (event.target as HTMLInputElement).value.replace(/\D/g, '');
    this.valueSig.set(digits);
    this.emitPhoneValue();
  }

  toggleDialCodeMenu(): void {
    if (this.isDisabled() || this.readonly()) return;

    if (this.dialCodeMenuOpen()) {
      this.closeDialCodeMenu();
      return;
    }

    const panel = this.countryPanel()?.nativeElement;
    if (!panel) return;

    if (!panel.matches(':popover-open')) panel.showPopover();
    this.dialCodeMenuOpen.set(true);
    requestAnimationFrame(() => this.positionCountryPanel());
  }

  closeDialCodeMenu(): void {
    const panel = this.countryPanel()?.nativeElement;
    this.dialCodeMenuOpen.set(false);
    if (panel?.matches(':popover-open')) panel.hidePopover();
    this.countrySearch.set('');
  }

  onCountryPanelToggle(event: ToggleEvent): void {
    if (event.newState === 'closed' && this.dialCodeMenuOpen()) {
      this.dialCodeMenuOpen.set(false);
      this.countrySearch.set('');
    }
  }

  onCountrySearch(event: Event): void {
    this.countrySearch.set((event.target as HTMLInputElement).value);
  }

  selectCountry(country: PhoneCountry): void {
    this.selectedDialCode.set(country.dialCode);
    this.selectedCountryIso2.set(country.iso2);
    this.emitPhoneValue();
    this.closeDialCodeMenu();
  }

  private positionCountryPanel(): void {
    const trigger = this.dialCodeTrigger()?.nativeElement;
    const panel = this.countryPanel()?.nativeElement;
    if (!trigger || !panel) return;

    const triggerRect = trigger.getBoundingClientRect();
    const panelHeight = panel.getBoundingClientRect().height;
    const layout = getSelectPanelLayout(triggerRect, panelHeight, document.documentElement.clientWidth, document.documentElement.clientHeight);

    panel.style.top = `${layout.top}px`;
    panel.style.left = `${layout.left}px`;
    panel.style.minWidth = `${triggerRect.width}px`;
  }

  /** El valor emitido al CVA (y por lo tanto lo que viaja en el payload al guardar) siempre
   *  incluye el código de país, ej. "+504 9699 1587" — nunca solo el número nacional. */
  private emitPhoneValue(): void {
    const composed = `+${this.selectedDialCode()} ${groupNationalDigits(this.valueSig(), this.selectedCountry()?.iso2)}`.trim();
    this.onChange(composed);
    this.valueChange.emit(composed);
    this.refreshValidation();
  }

  setDisabledState(isDisabled: boolean): void {
    this.isDisabled.set(isDisabled);
    this.refreshValidation();
  }

  registerOnChange(fn: (value: string | string[]) => void): void {
    this.onChange = fn;
  }

  registerOnTouched(fn: () => void): void {
    this.onTouched = fn;
  }

  onInput(event: Event): void {
    if (this.isTagInput()) {
      this.currentTagValue.set((event.target as HTMLInputElement).value);
      this.refreshValidation();
      return;
    }

    let val = (event.target as HTMLInputElement).value;

    if (this.type() === 'price') {
      val = unformatPrice(val);
      (event.target as HTMLInputElement).value = val;
    }

    if (this.type() === 'number') {
      val = sanitizeDecimalInput(val, { allowNegative: true });
      (event.target as HTMLInputElement).value = val;
    }

    this.commitValue(val);
  }

  /** Sube (+1) o baja (-1) el valor numérico con el paso y los límites del input. */
  stepValue(direction: 1 | -1): void {
    if (this.isDisabled() || this.readonly()) return;

    this.commitValue(stepNumberValue({ current: this.valueSig(), direction, step: this.step(), min: this.min(), max: this.max() }));
  }

  /** ↑/↓ en cualquier input numérico (con o sin botones): pasan por `stepValue` en vez del stepUp() nativo, que realinea al múltiplo de step. */
  onNumberKeydown(event: KeyboardEvent): void {
    if (this.type() !== 'number' || (event.key !== 'ArrowUp' && event.key !== 'ArrowDown')) return;

    event.preventDefault();
    this.stepValue(event.key === 'ArrowUp' ? 1 : -1);
  }

  /** La rueda sobre el campo enfocado hace lo mismo que las flechas; sin foco deja pasar el scroll de la página. */
  onNumberWheel(event: WheelEvent): void {
    if (this.type() !== 'number' || !this.isInputFocused()) return;

    event.preventDefault();
    this.stepValue(event.deltaY < 0 ? 1 : -1);
  }

  private commitValue(val: string): void {
    this.valueSig.set(val);
    this.onChange(val);
    this.valueChange.emit(val);
    this.refreshValidation();
  }

  onFocusInput(): void {
    this.isInputFocused.set(true);
    clearTimeout(this.placeholderTimer);
    this.placeholderTimer = setTimeout(() => this.isPlaceholderVisible.set(true), 150);
    this.refreshValidation();
  }

  onBlurInput(): void {
    this.isInputFocused.set(false);
    clearTimeout(this.placeholderTimer);
    this.isPlaceholderVisible.set(false);
    this.onTouched();
    this.refreshValidation();
  }

  onFocus(): void {
    this.isFocused.set(true);
    this.refreshValidation();
  }

  onBlur(): void {
    this.isFocused.set(false);
    this.onTouched();
    this.refreshValidation();
  }

  onTagKeyDown(event: KeyboardEvent): void {
    if (event.key === 'Enter' || event.key === ',') {
      event.preventDefault();
      this.addTag();
    }
  }

  addTag(): void {
    const tag = this.currentTagValue().trim();
    const current = this.tags();

    if (tag && !current.includes(tag)) {
      const next = [...current, tag];

      this.tags.set(next);
      this.currentTagValue.set('');
      this.updateTagsValue(next);
      this.refreshValidation();
    }
  }

  removeTag(index: number): void {
    const next = [...this.tags()];
    next.splice(index, 1);

    this.tags.set(next);
    this.updateTagsValue(next);
    this.refreshValidation();
  }

  private updateTagsValue(next: string[]): void {
    this.onChange(next);
    this.tagsChange.emit([...next]);
  }

  onIconClick(event: Event): void {
    if (this.iconClickable() && !this.isDisabled() && !this.readonly()) {
      this.iconClick.emit(event);
    }
  }
}
