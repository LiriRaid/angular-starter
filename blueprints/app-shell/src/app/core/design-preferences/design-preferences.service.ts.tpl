import { DOCUMENT } from '@angular/common';
import { DestroyRef, Injectable, computed, inject, signal } from '@angular/core';
import { DEFAULT_PRIMARY_COLOR_KEY, DEFAULT_SURFACE_COLOR_KEY } from '@core/theme/theme-palettes';
import { ThemeService } from '@core/theme/theme.service';
import { DESIGN_CHANGE_NOTIFIER, type DesignChange } from './design-change-notifier';
import { DESIGN_PREFERENCES_STORE } from './design-preferences.store';
import { DEFAULT_LAYOUT_MODE, isEnabledLayoutMode, layoutTraits, type LayoutModeId, type LayoutTraits } from './layout-modes';

export type UiRadius = 'sharp' | 'soft' | 'default' | 'rounded';
export type UiButtonSize = 'small' | 'medium' | 'large';
export type UiDensity = 'compact' | 'normal' | 'wide';
export type UiFontSize = 'small' | 'normal' | 'large';

/** Lo que la página de preferencias de diseño cambia en tiempo real. El tema y los colores los guarda `ThemeService`. */
export interface DesignPreferences {
  readonly layout: LayoutModeId;
  readonly radius: UiRadius;
  readonly buttonSize: UiButtonSize;
  readonly density: UiDensity;
  readonly fontSize: UiFontSize;
  readonly showBreadcrumb: boolean;
  readonly animations: boolean;
}

export const DEFAULT_DESIGN_PREFERENCES: DesignPreferences = {
  layout: DEFAULT_LAYOUT_MODE,
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

/** How long the application waits for the store before it starts with the defaults. */
export const LOAD_TIMEOUT_MS = 5000;

/** The value when it is one of the keys of `allowed` (its own, not the ones of Object.prototype), else the fallback. */
const oneOf = <T extends string>(value: unknown, allowed: Record<T, unknown>, fallback: T): T => (typeof value === 'string' && Object.hasOwn(allowed, value) ? (value as T) : fallback);

const flag = (value: unknown, fallback: boolean): boolean => (typeof value === 'boolean' ? value : fallback);

/** Keeps only valid values, so an old or edited document never breaks the page. */
const sanitize = (document: unknown): DesignPreferences => {
  const stored = (typeof document === 'object' && document !== null ? document : {}) as Partial<Record<keyof DesignPreferences, unknown>>;
  return {
    layout: isEnabledLayoutMode(stored.layout) ? stored.layout : DEFAULT_DESIGN_PREFERENCES.layout,
    radius: oneOf(stored.radius, RADIUS_SCALE, DEFAULT_DESIGN_PREFERENCES.radius),
    buttonSize: oneOf(stored.buttonSize, BUTTON_SCALE, DEFAULT_DESIGN_PREFERENCES.buttonSize),
    density: oneOf(stored.density, DENSITY_SCALE, DEFAULT_DESIGN_PREFERENCES.density),
    fontSize: oneOf(stored.fontSize, FONT_SCALE, DEFAULT_DESIGN_PREFERENCES.fontSize),
    showBreadcrumb: flag(stored.showBreadcrumb, DEFAULT_DESIGN_PREFERENCES.showBreadcrumb),
    animations: flag(stored.animations, DEFAULT_DESIGN_PREFERENCES.animations),
  };
};

const sameAs = (a: DesignPreferences, b: DesignPreferences): boolean => (Object.keys(a) as (keyof DesignPreferences)[]).every((key) => a[key] === b[key]);

/**
 * El diseño de la plataforma (ADR-0029). Lo que ve cada usuario es el documento que guarda `DESIGN_PREFERENCES_STORE`;
 * el administrador lo cambia desde la página de preferencias y `DESIGN_CHANGE_NOTIFIER` avisa a los demás, que lo
 * ven al recargar. Nada de esto usa el almacenamiento del navegador.
 */
@Injectable({ providedIn: 'root' })
export class DesignPreferencesService {
  private readonly document = inject(DOCUMENT);
  private readonly themeService = inject(ThemeService);
  private readonly store = inject(DESIGN_PREFERENCES_STORE);
  private readonly notifier = inject(DESIGN_CHANGE_NOTIFIER);

  /** Lo que se ve ahora: cada cambio se aplica al instante. */
  readonly preferences = signal<DesignPreferences>(DEFAULT_DESIGN_PREFERENCES);
  private readonly saved = signal<DesignPreferences>(DEFAULT_DESIGN_PREFERENCES);

  /** Hay cambios que "Guardar cambios" todavía no persistió. */
  readonly hasChanges = computed(() => !sameAs(this.preferences(), this.saved()));

  /** Los rasgos del layout actual: los componentes del shell los leen para decidir qué dibujan. */
  readonly layoutTraits = computed<LayoutTraits>(() => layoutTraits(this.preferences().layout));

  /** Quien puede guardar lo decide el store. */
  readonly canSave = computed(() => this.store.canSave());

  private readonly announcedVersionState = signal<string | null>(null);
  /** La versión del diseño que otra persona guardó y que esta pestaña todavía no ve; `null` si no hay ninguna. */
  readonly announcedVersion = this.announcedVersionState.asReadonly();
  /** Otra persona guardó un diseño distinto del que se está viendo: hay que recargar la página para verlo. */
  readonly updateAvailable = computed(() => this.announcedVersionState() !== null);

  private readonly saveFailedState = signal(false);
  /** El último intento de guardar no llegó a la plataforma. */
  readonly saveFailed = this.saveFailedState.asReadonly();

  /** La versión del documento que se aplicó o se guardó desde esta pestaña. */
  private version = '';
  private saving: Promise<void> = Promise.resolve();

  constructor() {
    inject(DestroyRef).onDestroy(() => this.notifier.disconnect());
  }

  /** Carga el diseño de la plataforma al arrancar la aplicación y empieza a escuchar sus cambios. */
  async initialize(): Promise<void> {
    const loaded = await this.load();
    const stored = sanitize(loaded?.preferences);
    this.version = loaded?.version ?? '';
    this.saved.set(stored);
    this.preferences.set(stored);
    this.apply(stored);
    this.notifier.connect((change) => this.onChange(change));
  }

  set<K extends keyof DesignPreferences>(key: K, value: DesignPreferences[K]): void {
    const next = { ...this.preferences(), [key]: value };
    this.preferences.set(next);
    this.apply(next);
  }

  /** Guarda lo que se ve ahora para toda la plataforma; los demás reciben el aviso de que el diseño cambió. */
  async save(): Promise<void> {
    if (!this.canSave()) return;
    this.saving = this.persist(this.preferences());
    await this.saving;
  }

  /** Vuelve a los valores de fábrica, también el tema y los colores; si el store lo permite, los guarda. */
  async reset(): Promise<void> {
    this.preferences.set(DEFAULT_DESIGN_PREFERENCES);
    this.apply(DEFAULT_DESIGN_PREFERENCES);
    this.themeService.setMode('light');
    this.themeService.applyColor(DEFAULT_PRIMARY_COLOR_KEY);
    this.themeService.applySurface(DEFAULT_SURFACE_COLOR_KEY);
    await this.save();
  }

  /** Recarga la página para ver el diseño nuevo. */
  reload(): void {
    this.document.defaultView?.location.reload();
  }

  private async load() {
    let timer: ReturnType<typeof setTimeout> | undefined;
    const timeout = new Promise<null>((resolve) => (timer = setTimeout(() => resolve(null), LOAD_TIMEOUT_MS)));
    try {
      return await Promise.race([this.store.load(), timeout]);
    } catch {
      return null;
    } finally {
      clearTimeout(timer);
    }
  }

  private async persist(preferences: DesignPreferences): Promise<void> {
    try {
      const saved = await this.store.save(preferences);
      this.version = saved.version;
      this.saved.set(preferences);
      this.saveFailedState.set(false);
    } catch {
      this.saveFailedState.set(true);
    }
  }

  /** El propio guardado también llega por el notifier: se espera a que termine para no avisarle a quien lo hizo. */
  private onChange(change: DesignChange): void {
    void this.saving.then(() => {
      if (change.version !== this.version) this.announcedVersionState.set(change.version);
    });
  }

  private apply(preferences: DesignPreferences): void {
    const root = this.document.documentElement;
    const style = root.style;
    style.setProperty('--sa-ui-radius-scale', String(RADIUS_SCALE[preferences.radius]));
    style.setProperty('--sa-ui-button-scale', String(BUTTON_SCALE[preferences.buttonSize]));
    style.setProperty('--sa-ui-density-scale', String(DENSITY_SCALE[preferences.density]));
    style.setProperty('--sa-ui-font-scale', String(FONT_SCALE[preferences.fontSize]));
    // Attributes, not `dataset`: the DOM of the server renderer has no `dataset`.
    root.setAttribute('data-animations', preferences.animations ? 'on' : 'off');
    // The stylesheets of the shell read these: `html[data-layout-traits~='compact']`.
    const traits = layoutTraits(preferences.layout);
    root.setAttribute('data-layout', preferences.layout);
    root.setAttribute('data-layout-traits', (Object.keys(traits) as (keyof LayoutTraits)[]).filter((trait) => traits[trait]).join(' '));
  }
}
