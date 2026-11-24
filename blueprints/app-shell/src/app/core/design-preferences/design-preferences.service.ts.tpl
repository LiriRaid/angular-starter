import { DOCUMENT } from '@angular/common';
import { Injectable, computed, inject, signal } from '@angular/core';
import { DEFAULT_PRIMARY_COLOR_KEY, DEFAULT_SURFACE_COLOR_KEY } from '@core/theme/theme-palettes';
import { ThemeService } from '@core/theme/theme.service';

export type UiRadius = 'sharp' | 'soft' | 'default' | 'rounded';
export type UiButtonSize = 'small' | 'medium' | 'large';
export type UiDensity = 'compact' | 'normal' | 'wide';
export type UiFontSize = 'small' | 'normal' | 'large';

/** Lo que la página de preferencias de diseño cambia en tiempo real. El tema y los colores los guarda `ThemeService`. */
export interface DesignPreferences {
  readonly radius: UiRadius;
  readonly buttonSize: UiButtonSize;
  readonly density: UiDensity;
  readonly fontSize: UiFontSize;
  readonly showBreadcrumb: boolean;
  readonly animations: boolean;
}

export const DEFAULT_DESIGN_PREFERENCES: DesignPreferences = {
  radius: 'default',
  buttonSize: 'medium',
  density: 'normal',
  fontSize: 'normal',
  showBreadcrumb: true,
  animations: true,
};

/** Cada token es un multiplicador de la variable CSS que lo aplica (ver `design-preferences-styles.css`). */
export const RADIUS_SCALE: Record<UiRadius, number> = { sharp: 0.25, soft: 0.6, default: 1, rounded: 1.6 };
export const BUTTON_SCALE: Record<UiButtonSize, number> = { small: 0.9, medium: 1, large: 1.1 };
export const DENSITY_SCALE: Record<UiDensity, number> = { compact: 0.875, normal: 1, wide: 1.125 };
export const FONT_SCALE: Record<UiFontSize, number> = { small: 0.875, normal: 1, large: 1.125 };

const STORAGE_KEY = '__PROJECT_NAME__:design-preferences';

const readStored = (): DesignPreferences => {
  try {
    const text = globalThis.localStorage?.getItem(STORAGE_KEY);
    return text ? sanitize(JSON.parse(text) as Partial<Record<keyof DesignPreferences, unknown>>) : DEFAULT_DESIGN_PREFERENCES;
  } catch {
    return DEFAULT_DESIGN_PREFERENCES;
  }
};

const writeStored = (preferences: DesignPreferences | null): void => {
  try {
    if (preferences) globalThis.localStorage?.setItem(STORAGE_KEY, JSON.stringify(preferences));
    else globalThis.localStorage?.removeItem(STORAGE_KEY);
  } catch {
    // Preference persistence is best-effort.
  }
};

/** The value when it is one of the keys of `allowed` (its own, not the ones of Object.prototype), else the fallback. */
const oneOf = <T extends string>(value: unknown, allowed: Record<T, unknown>, fallback: T): T => (typeof value === 'string' && Object.hasOwn(allowed, value) ? (value as T) : fallback);

const flag = (value: unknown, fallback: boolean): boolean => (typeof value === 'boolean' ? value : fallback);

/** Keeps only valid values, so an old or edited entry never breaks the page. */
const sanitize = (stored: Partial<Record<keyof DesignPreferences, unknown>>): DesignPreferences => ({
  radius: oneOf(stored.radius, RADIUS_SCALE, DEFAULT_DESIGN_PREFERENCES.radius),
  buttonSize: oneOf(stored.buttonSize, BUTTON_SCALE, DEFAULT_DESIGN_PREFERENCES.buttonSize),
  density: oneOf(stored.density, DENSITY_SCALE, DEFAULT_DESIGN_PREFERENCES.density),
  fontSize: oneOf(stored.fontSize, FONT_SCALE, DEFAULT_DESIGN_PREFERENCES.fontSize),
  showBreadcrumb: flag(stored.showBreadcrumb, DEFAULT_DESIGN_PREFERENCES.showBreadcrumb),
  animations: flag(stored.animations, DEFAULT_DESIGN_PREFERENCES.animations),
});

const sameAs = (a: DesignPreferences, b: DesignPreferences): boolean => (Object.keys(a) as (keyof DesignPreferences)[]).every((key) => a[key] === b[key]);

@Injectable({ providedIn: 'root' })
export class DesignPreferencesService {
  private readonly rootElement = inject(DOCUMENT).documentElement;
  private readonly themeService = inject(ThemeService);

  /** Lo que se ve ahora: cada cambio se aplica al instante. */
  readonly preferences = signal<DesignPreferences>(DEFAULT_DESIGN_PREFERENCES);
  private readonly saved = signal<DesignPreferences>(DEFAULT_DESIGN_PREFERENCES);

  /** Hay cambios que "Guardar cambios" todavía no persistió. */
  readonly hasChanges = computed(() => !sameAs(this.preferences(), this.saved()));

  /** Aplica lo guardado al arrancar la aplicación. */
  initialize(): void {
    const stored = readStored();
    this.saved.set(stored);
    this.preferences.set(stored);
    this.apply(stored);
  }

  set<K extends keyof DesignPreferences>(key: K, value: DesignPreferences[K]): void {
    const next = { ...this.preferences(), [key]: value };
    this.preferences.set(next);
    this.apply(next);
  }

  /** Persiste lo que se ve ahora; al recargar la página vuelve igual. */
  save(): void {
    writeStored(this.preferences());
    this.saved.set(this.preferences());
  }

  /** Vuelve a los valores de fábrica, también el tema y los colores, y borra lo guardado. */
  reset(): void {
    this.preferences.set(DEFAULT_DESIGN_PREFERENCES);
    this.saved.set(DEFAULT_DESIGN_PREFERENCES);
    this.apply(DEFAULT_DESIGN_PREFERENCES);
    writeStored(null);
    this.themeService.setMode('light');
    this.themeService.applyColor(DEFAULT_PRIMARY_COLOR_KEY);
    this.themeService.applySurface(DEFAULT_SURFACE_COLOR_KEY);
  }

  private apply(preferences: DesignPreferences): void {
    const style = this.rootElement.style;
    style.setProperty('--sa-ui-radius-scale', String(RADIUS_SCALE[preferences.radius]));
    style.setProperty('--sa-ui-button-scale', String(BUTTON_SCALE[preferences.buttonSize]));
    style.setProperty('--sa-ui-density-scale', String(DENSITY_SCALE[preferences.density]));
    style.setProperty('--sa-ui-font-scale', String(FONT_SCALE[preferences.fontSize]));
    // Attributes, not `dataset`: the DOM of the server renderer has no `dataset`.
    this.rootElement.setAttribute('data-animations', preferences.animations ? 'on' : 'off');
  }
}
