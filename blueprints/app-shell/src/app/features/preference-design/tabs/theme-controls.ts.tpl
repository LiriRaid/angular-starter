import { ChangeDetectionStrategy, Component, computed, inject, input, output } from '@angular/core';

import { type ThemeColor } from '@core/theme/theme-palettes';
import { ThemeService } from '@core/theme/theme.service';
import { AsIcon } from '@shared/components';

/** Los colores de una paleta como muestras; la página de preferencias la usa para el color principal y la superficie. */
@Component({
  selector: '__PREFIX__-color-swatches',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="flex flex-wrap gap-1.5" role="group" [attr.aria-label]="label()">
      @for (color of colors(); track color.key) {
        <button type="button" class="size-7 rounded-lg border-2 border-white shadow-[0_0_0_1px_var(--app-border-color)]" [class.outline-2]="current() === color.key" [class.outline-offset-2]="current() === color.key" [class.outline-(--as-primary-color)]="current() === color.key" [style.background]="color.swatch" [attr.aria-label]="itemLabel() + ' ' + color.label" [attr.aria-pressed]="current() === color.key" (click)="chosen.emit(color.key)"></button>
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
}

/** El interruptor Claro / Oscuro de `ThemeService`. */
@Component({
  selector: '__PREFIX__-mode-switch',
  imports: [AsIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="flex gap-1 rounded-xl border border-(--app-border-color) p-1" role="group" [attr.aria-label]="label()">
      <button type="button" class="flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-caption-2-semibold" [class.bg-(--as-primary-color)]="!isDark()" [class.text-(--as-primary-contrast-color)]="!isDark()" [class.text-(--app-text-color)]="isDark()" [attr.aria-pressed]="!isDark()" (click)="themeService.setMode('light')">
        <as-icon name="Sun" size="14" />Claro
      </button>
      <button type="button" class="flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-caption-2-semibold" [class.bg-(--as-primary-color)]="isDark()" [class.text-(--as-primary-contrast-color)]="isDark()" [class.text-(--app-text-color)]="!isDark()" [attr.aria-pressed]="isDark()" (click)="themeService.setMode('dark')">
        <as-icon name="Moon" size="14" />Oscuro
      </button>
    </div>
  `,
})
export class ModeSwitch {
  readonly themeService = inject(ThemeService);
  readonly label = input('Tema');
  readonly isDark = computed(() => this.themeService.mode() === 'dark');
}
