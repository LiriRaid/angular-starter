import { ChangeDetectionStrategy, Component, computed, inject, input, output } from '@angular/core';

import { type ThemeColor } from '@core/theme/theme-palettes';
import { ThemeService } from '@core/theme/theme.service';
import { SaIcon } from '@shared/components';

/** Una muestra: un círculo con un contorno tenue; la elegida lleva un anillo del color del panel y otro del color principal, con un check (como los formularios de marcas y roles de la aplicación de referencia). */
const SWATCH = 'flex size-7 shrink-0 cursor-pointer items-center justify-center rounded-full transition-transform hover:scale-110 shadow-[inset_0_0_0_1px_color-mix(in_srgb,white_18%,transparent)]';
const SWATCH_ACTIVE = 'flex size-7 shrink-0 cursor-pointer items-center justify-center rounded-full transition-transform hover:scale-110 shadow-[inset_0_0_0_1px_color-mix(in_srgb,white_18%,transparent),0_0_0_2px_var(--app-panel-bg),0_0_0_4px_var(--sa-primary-color)]';

/** Los colores de una paleta como muestras; la página de preferencias la usa para el color principal y la superficie. */
@Component({
  selector: '__PREFIX__-color-swatches',
  imports: [SaIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="flex flex-wrap gap-2.5 p-1" role="group" [attr.aria-label]="label()">
      @for (color of colors(); track color.key) {
        <button type="button" [class]="current() === color.key ? activeClass : baseClass" [style.background]="color.swatch" [attr.aria-label]="itemLabel() + ' ' + color.label" [attr.aria-pressed]="current() === color.key" (click)="chosen.emit(color.key)">
          @if (current() === color.key) {
            <sa-icon name="CheckCircle" size="12" color="white" />
          }
        </button>
      }
    </div>
  `,
})
export class ColorSwatches {
  readonly colors = input.required<readonly ThemeColor[]>();
  readonly current = input.required<string>();
  readonly label = input.required<string>();
  /** El principio del nombre accesible de cada muestra: "Color", "Superficie". */
  readonly itemLabel = input('Color');
  readonly chosen = output<string>();

  protected readonly baseClass = SWATCH;
  protected readonly activeClass = SWATCH_ACTIVE;
}

/** El interruptor Claro / Oscuro de `ThemeService`. */
@Component({
  selector: '__PREFIX__-mode-switch',
  imports: [SaIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="flex gap-1 rounded-xl border border-(--app-border-color) p-1" role="group" [attr.aria-label]="label()">
      <button type="button" class="flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-caption-2-semibold" [class.bg-(--sa-primary-color)]="!isDark()" [class.text-(--sa-primary-contrast-color)]="!isDark()" [class.text-(--app-text-color)]="isDark()" [attr.aria-pressed]="!isDark()" (click)="themeService.setMode('light')">
        <sa-icon name="Sun" size="14" />Claro
      </button>
      <button type="button" class="flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-caption-2-semibold" [class.bg-(--sa-primary-color)]="isDark()" [class.text-(--sa-primary-contrast-color)]="isDark()" [class.text-(--app-text-color)]="!isDark()" [attr.aria-pressed]="isDark()" (click)="themeService.setMode('dark')">
        <sa-icon name="Moon" size="14" />Oscuro
      </button>
    </div>
  `,
})
export class ModeSwitch {
  readonly themeService = inject(ThemeService);
  readonly label = input('Tema');
  readonly isDark = computed(() => this.themeService.mode() === 'dark');
}
