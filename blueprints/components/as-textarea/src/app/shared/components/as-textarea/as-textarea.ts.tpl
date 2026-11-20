import { NgClass } from '@angular/common';
import { afterNextRender, ChangeDetectionStrategy, Component, ElementRef, computed, DestroyRef, effect, forwardRef, inject, Injector, input, output, signal, viewChild } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { AbstractControl, ControlValueAccessor, FormsModule, NG_VALUE_ACCESSOR, NgControl, ReactiveFormsModule } from '@angular/forms';

import { AsIcon } from '../as-icon/as-icon';
import { LucideIconName } from '@core/common/icons/lucide-icons';
import { createInputPresentation } from '../as-input/as-input.config';
import type { AsIconPosition, AsVariant } from '../as-input/as-input.entity';

@Component({
  selector: 'as-textarea',
  standalone: true,
  imports: [NgClass, FormsModule, ReactiveFormsModule, AsIcon],
  templateUrl: './as-textarea.html',
  styleUrl: './as-textarea.css',
  providers: [{ provide: NG_VALUE_ACCESSOR, useExisting: forwardRef(() => AsTextarea), multi: true }],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AsTextarea implements ControlValueAccessor {
  private static nextInputId = 0;

  readonly inputId = input<string>('');
  readonly placeholder = input<string>('');
  readonly label = input<string | undefined>(undefined);
  readonly value = input<string>('');
  readonly autocomplete = input<string>('');

  /** Filas visibles iniciales. Con `autoResize` en true, arranca del alto de un input y crece hacia abajo desde ahí. */
  readonly rows = input<number>(1);
  readonly autoResize = input<boolean>(true);

  readonly lucideIcon = input<LucideIconName | ''>('');
  readonly iconSize = input<number>(16);
  readonly iconPosition = input<AsIconPosition>('left');

  readonly showErrorMessage = input<boolean>(true);
  readonly readonlyInput = input<boolean>(false);
  /** Default `'on'` preserva el comportamiento de siempre para todo consumidor que no lo pase
   *  explícito (label sobre el borde, legend cutout) — solo `add-contact-modal` pasa `'over'`. */
  readonly variant = input<AsVariant>('on');
  readonly required = input(false);

  readonly valueChange = output<string>();
  readonly keyup = output<KeyboardEvent>();

  readonly isDisabled = signal(false);
  readonly isFocused = signal(false);
  readonly transitionReady = signal(false);
  /**
   * Se toca cada vez que el host cambia de tamaño (ResizeObserver). Sin Zone.js, PrimeNG solo
   * recalcula el alto del textarea (scrollHeight) durante los ciclos de detección de cambios que
   * Angular efectivamente dispara. Dentro de un modal, el diálogo todavía está resolviendo su ancho
   * final cuando ocurre esa primera medición, y como es zoneless nada la vuelve a disparar sola —
   * por eso quedaba con el alto por defecto del navegador hasta que el usuario tocaba el campo
   * (un evento real que sí escribe una señal). Este signal, leído en el template, fuerza ese
   * segundo chequeo apenas el contenedor real se asienta, sin depender de un timer arbitrario.
   */
  readonly resizeTick = signal(0);

  private readonly textareaEl = viewChild<ElementRef<HTMLTextAreaElement>>('textareaEl');

  private readonly validationTick = signal(0);
  private readonly generatedInputId = `as-textarea-${AsTextarea.nextInputId++}`;

  private readonly valueSig = signal<string>('');

  onChange: (value: string) => void = () => {};
  onTouched: () => void = () => {};

  private readonly injector = inject(Injector);
  private readonly destroyRef = inject(DestroyRef);
  private readonly elementRef = inject(ElementRef<HTMLElement>);
  private ngControl?: NgControl;

  constructor() {
    afterNextRender(() => {
      this.ngControl = this.injector.get(NgControl, null) || undefined;

      const initial = this.value() ?? '';
      if (initial) this.valueSig.set(initial);

      this.control?.events.pipe(takeUntilDestroyed(this.destroyRef)).subscribe(() => this.refreshValidation());

      setTimeout(() => this.transitionReady.set(true), 0);

      const resizeObserver = new ResizeObserver(() => this.resizeTick.update((tick) => tick + 1));
      resizeObserver.observe(this.elementRef.nativeElement);
      this.destroyRef.onDestroy(() => resizeObserver.disconnect());
    });

    effect(() => {
      this.displayValue();
      this.resizeTick();
      if (this.autoResize()) this.autoSize();
    });
  }

  /** Réplica del autoResize de pTextarea: alto = auto (colapsa) y luego scrollHeight
   *  (crece al contenido real). Se dispara por el effect() de arriba (valor/resize del
   *  contenedor) y también directo en onInput() para feedback inmediato al escribir. */
  private autoSize(): void {
    const el = this.textareaEl()?.nativeElement;
    if (!el) return;

    el.style.height = 'auto';
    el.style.height = `${el.scrollHeight}px`;
  }

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
    type: () => 'text',
    isTagInput: () => false,
    tags: () => [],
    value: this.valueSig,
    label: this.label,
    placeholder: this.placeholder,
    inputId: this.inputId,
    generatedInputId: this.generatedInputId,
    showErrorMessage: this.showErrorMessage,
    isDisabled: this.isDisabled,
    readonly: this.readonlyInput,
    isFocused: this.isFocused,
    isInputFocused: this.isFocused,
    variant: this.variant,
    hasIcon: this.hasIcon,
    iconPosition: this.iconPosition,
  });

  readonly hasErrors = this.presentation.hasErrors;
  readonly errorMessage = this.presentation.errorMessage;
  readonly displayValue = this.presentation.displayValue;
  readonly hasLeftIcon = this.presentation.hasLeftIcon;
  readonly resolvedInputId = this.presentation.resolvedInputId;
  readonly errorId = this.presentation.errorId;
  readonly describedBy = this.presentation.describedBy;
  readonly placeholderAttr = this.presentation.placeholderAttr;
  readonly legendOffset = this.presentation.legendOffset;
  readonly legendMaxWidth = this.presentation.legendMaxWidth;
  readonly legendTransition = this.presentation.legendTransition;
  readonly fieldsetClasses = this.presentation.fieldsetClasses;
  readonly fieldsetBoxShadow = this.presentation.fieldsetBoxShadow;
  readonly labelBackground = this.presentation.labelBackground;
  readonly labelColor = this.presentation.labelColor;
  readonly labelClass = this.presentation.labelClass;

  /** Con varias filas el label en reposo no se centra en el alto del campo (quedaría flotando a mitad de un cuadro de 4 líneas): se ancla junto a la primera línea. Flotando o en `over` no cambia nada. */
  readonly resolvedLabelClass = computed(() => {
    const labelClass = this.labelClass();
    if (this.rows() <= 1 || !labelClass['top-1/2']) return labelClass;

    return { ...labelClass, 'top-1/2': false, '-translate-y-1/2': false, 'top-3': true, 'translate-y-0': true };
  });

  writeValue(value: unknown): void {
    this.valueSig.set(value !== null && value !== undefined ? String(value) : '');
    this.refreshValidation();
  }

  setDisabledState(isDisabled: boolean): void {
    this.isDisabled.set(isDisabled);
    this.refreshValidation();
  }

  registerOnChange(fn: (value: string) => void): void {
    this.onChange = fn;
  }

  registerOnTouched(fn: () => void): void {
    this.onTouched = fn;
  }

  onInput(event: Event): void {
    const val = (event.target as HTMLTextAreaElement).value;
    this.valueSig.set(val);
    this.onChange(val);
    this.valueChange.emit(val);
    this.refreshValidation();
    if (this.autoResize()) this.autoSize();
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
}
