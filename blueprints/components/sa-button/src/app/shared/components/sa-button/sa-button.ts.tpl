import { NgClass, NgTemplateOutlet } from '@angular/common';
import { ChangeDetectionStrategy, Component, booleanAttribute, computed, input, output } from '@angular/core';

import { SaIcon } from '../sa-icon/sa-icon';
import { SaRipple } from './sa-ripple';

/** Mismo vocabulario de severidades que exponía PrimeNG — se conserva para no tocar
 *  a ningún consumidor del wrapper (solo primary/secondary/success/danger se usan hoy). */
export type ButtonSeverity = 'primary' | 'secondary' | 'success' | 'info' | 'warn' | 'help' | 'danger' | 'contrast';

type ButtonVariant = 'outlined' | 'text' | 'dashed' | undefined;
type ButtonType = 'button' | 'submit' | 'reset';
type IconPosition = 'left' | 'right' | 'top' | 'bottom';
type ButtonSize = 'xsmall' | 'small' | 'medium' | 'high' | 'large';
export type ButtonRounded = 'default' | 'lg' | 'full';

type ButtonClassParts = {
  button: string;
  label: string;
};

@Component({
  selector: 'sa-button',
  standalone: true,
  imports: [NgClass, NgTemplateOutlet, SaIcon, SaRipple],
  templateUrl: './sa-button.html',
  styleUrl: './sa-button.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    '[class]': 'hostClass()',
  },
})
export class SaButton {
  readonly label = input<string>('');
  readonly icon = input<string | null>(null);
  readonly badge = input<string | number | null>(null);

  readonly iconSize = input<string | number>('16');
  readonly iconPos = input<IconPosition>('left');
  readonly loadingIcon = input<string>('Loader');

  /** Segundo ícono, siempre pegado al final del contenido (después del label/badge),
   * independiente de `iconPos`. Para casos como un indicador "+" a la derecha
   * de un botón que ya usa `icon` para el ícono principal a la izquierda. */
  readonly trailingIcon = input<string | null>(null);
  readonly trailingIconColor = input<string | undefined>(undefined);
  readonly trailingIconSize = input<string | number>('18');
  readonly trailingIconExtraClass = input<string>('');

  readonly size = input<ButtonSize>('medium');
  /** Radio del borde: `default` (el de siempre), `lg` (1rem) o `full` (píldora). */
  readonly rounded = input<ButtonRounded>('default');

  readonly severity = input<ButtonSeverity | undefined>(undefined);
  readonly outlined = input(false, { transform: booleanAttribute });
  readonly raised = input(false, { transform: booleanAttribute });
  readonly text = input(false, { transform: booleanAttribute });
  readonly loading = input(false, { transform: booleanAttribute });
  readonly disabled = input(false, { transform: booleanAttribute });
  /** El botón representa una opción actualmente elegida (ej. la pestaña "Responder" vs "Nota
   *  interna", un ícono de formato con el toggle prendido) — a diferencia de `:active` (CSS, solo
   *  mientras se mantiene el clic presionado), esto es un estado que el consumidor decide y puede
   *  quedar prendido. Agrega `sa-btn-selected`, que en `variant="text"` fuerza el texto/ícono a
   *  `--app-text-color` (blanco en dark) — el mismo color de hover, nunca gris — así ningún
   *  feature necesita repetir esa regla a mano (ver button-styles.css). El FONDO que distingue
   *  cuál opción es cuál (ej. tinte primary vs ámbar) sigue siendo cosa del consumidor. */
  readonly selected = input(false, { transform: booleanAttribute });
  readonly variant = input<ButtonVariant>(undefined);
  readonly type = input<ButtonType>('button');

  readonly href = input<string | null>(null);
  readonly target = input<string | null | undefined>(null);
  readonly rel = input<string | null | undefined>(null);
  readonly ariaLabel = input<string | null>(null);
  readonly ariaControls = input<string | null>(null);
  readonly ariaExpanded = input<boolean | string | null>(null);
  /** Para botones de alternar (negrita, "Responder"/"Nota interna"): anuncia el estado a lectores de pantalla. `null` no emite el atributo. */
  readonly ariaPressed = input<boolean | null>(null);

  readonly styleClass = input<string>('');
  readonly labelClass = input<string>('');
  readonly badgeClass = input<string>('');
  readonly iconExtraClass = input<string>('');
  readonly iconColor = input<string | undefined>(undefined);

  readonly onClick = output<MouseEvent>();

  private readonly classParts = computed<ButtonClassParts>(() => {
    const tokens = this.toClassList(this.styleClass());

    const labelTokens = tokens.filter((token) => this.isTextClass(token));
    const buttonTokens = tokens.filter((token) => !this.isTextClass(token));

    return {
      button: buttonTokens.join(' '),
      label: labelTokens.join(' '),
    };
  });

  readonly isIconOnly = computed(() => this.hasIcon() && !this.label() && !this.hasBadge());

  /** iconPos 'top'/'bottom' implica apilar ícono y label en columna — a diferencia de
   *  'left'/'right' (que solo cambian el orden en el DOM vía isIconBefore), esto sí necesita
   *  su propia clase en el botón para el flex-direction real. */
  readonly isStackedIcon = computed(() => this.iconPos() === 'top' || this.iconPos() === 'bottom');

  /** Clases base del botón (sa-btn, sa-btn-outlined, sa-btn-{severity}, etc.), separadas
   *  del resto para poder combinarlas con las de tamaño/forma en buttonClass. */
  private readonly baseClasses = computed(() => this.joinClasses('sa-btn', this.severity() ? `sa-btn-${this.severity()}` : '', this.isOutlined() ? 'sa-btn-outlined' : '', this.isTextVariant() ? 'sa-btn-text' : '', this.isDashed() ? 'sa-btn-dashed' : '', this.raised() ? 'sa-btn-raised' : '', this.selected() ? 'sa-btn-selected' : ''));

  /** sa-btn-{size} fija un height pensado para una sola línea (icono+label en fila) — no
   *  aplica cuando el ícono va apilado arriba/abajo, porque ahí el alto lo debe dar el
   *  contenido (2 líneas), no un valor fijo pensado para la variante horizontal. */
  readonly buttonClass = computed(() => this.joinClasses(this.baseClasses(), this.classParts().button, this.isStackedIcon() ? '' : `sa-btn-${this.size()}`, this.isIconOnly() ? 'sa-btn-icon' : '', this.isStackedIcon() ? 'sa-btn-icon-stacked' : '', this.rounded() !== 'default' ? `sa-btn-r-${this.rounded()}` : ''));

  readonly hostClass = computed(() => {
    const widthTokens = this.toClassList(this.styleClass()).filter((token) => this.isWidthClass(token));

    return this.joinClasses(widthTokens.length ? 'block' : '', ...widthTokens);
  });

  readonly iconClass = computed(() => `sa-btn__icon sa-btn__icon--${this.iconPos()}`);

  readonly computedIconClass = computed(() => this.joinClasses(this.iconClass(), this.iconExtraClass()));

  readonly computedLabelClass = computed(() => this.joinClasses('sa-btn__label', this.classParts().label, this.labelClass()));

  readonly computedBadgeClass = computed(() => this.joinClasses('sa-button__badge', this.badgeClass()));

  readonly hasIcon = computed(() => Boolean(this.icon()));
  readonly isOutlined = computed(() => this.outlined() || this.variant() === 'outlined');
  readonly isTextVariant = computed(() => this.text() || this.variant() === 'text');
  readonly isDashed = computed(() => this.variant() === 'dashed');

  readonly isDisabled = computed(() => this.disabled() || this.loading());

  /** Hay algo que mostrar en el slot del ícono: el ícono real o el spinner de carga. */
  readonly showIconSlot = computed(() => this.hasIcon() || this.loading());

  readonly hasBadge = computed(() => {
    const value = this.badge();

    return value !== null && value !== undefined && value !== '';
  });

  readonly showIconBefore = computed(() => this.showIconSlot() && this.isIconBefore(this.iconPos()));

  readonly showIconAfter = computed(() => this.showIconSlot() && !this.isIconBefore(this.iconPos()));

  handleClick(event: MouseEvent): void {
    if (this.isDisabled()) {
      event.preventDefault();
      event.stopPropagation();
      return;
    }

    this.onClick.emit(event);
  }

  private isIconBefore(position: IconPosition): boolean {
    return position === 'left' || position === 'top';
  }

  private isTextClass(token: string): boolean {
    return /(^|:)text-/.test(token);
  }

  private isWidthClass(token: string): boolean {
    return /(^|:)w-/.test(token);
  }

  private toClassList(value: string | null | undefined): string[] {
    return (value ?? '').trim().split(/\s+/).filter(Boolean);
  }

  private joinClasses(...classes: Array<string | null | undefined>): string {
    return classes.flatMap((value) => this.toClassList(value)).join(' ');
  }
}
