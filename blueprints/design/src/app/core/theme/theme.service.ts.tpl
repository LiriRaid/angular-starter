import { DOCUMENT } from '@angular/common';
import { Injectable, inject, signal } from '@angular/core';
import { DEFAULT_PRIMARY_COLOR_KEY, DEFAULT_SURFACE_COLOR_KEY, getPrimaryColor, getSurfaceColor } from './theme-palettes';
import { getStoredPrimaryColorKey, getStoredSurfaceColorKey, getStoredThemeMode, setStoredPrimaryColorKey, setStoredSurfaceColorKey, setStoredThemeMode } from './theme-preferences.storage';

export type ThemeMode = 'light' | 'dark';

@Injectable({ providedIn: 'root' })
export class ThemeService {
  private readonly document = inject(DOCUMENT);
  private readonly rootElement = this.document.documentElement;

  readonly mode = signal<ThemeMode>('dark');
  readonly primaryColorKey = signal<string>(DEFAULT_PRIMARY_COLOR_KEY);
  readonly surfaceColorKey = signal<string>(DEFAULT_SURFACE_COLOR_KEY);

  initialize(): void {
    this.initMode();
    this.initColor();
    this.initSurface();
  }

  // ── Mode ──────────────────────────────────────────────

  toggleMode(): void {
    this.setMode(this.mode() === 'dark' ? 'light' : 'dark');
  }

  setMode(mode: ThemeMode): void {
    this.applyMode(mode, true);
    setStoredThemeMode(mode);
  }

  // ── Primary color ─────────────────────────────────────

  applyColor(key: string): void {
    const color = getPrimaryColor(key);
    this.applyPrimaryPaletteVars(color.palette);
    // Attributes, not `dataset`: the DOM of the server renderer has no `dataset`.
    this.rootElement.setAttribute('data-primary-color', color.key);
    this.primaryColorKey.set(color.key);
    setStoredPrimaryColorKey(color.key);
  }

  // ── Surface color ─────────────────────────────────────

  applySurface(key: string): void {
    const color = getSurfaceColor(key);
    this.applySurfacePaletteVars(color.palette);
    this.rootElement.setAttribute('data-surface-color', color.key);
    this.surfaceColorKey.set(color.key);
    setStoredSurfaceColorKey(color.key);
  }

  // ── Private ───────────────────────────────────────────

  private initMode(): void {
    const saved = getStoredThemeMode();
    const resolved = saved ? saved : globalThis.matchMedia?.('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
    this.applyMode(resolved, false);
  }

  private initColor(): void {
    this.applyColor(getStoredPrimaryColorKey());
  }

  private initSurface(): void {
    this.applySurface(getStoredSurfaceColorKey());
  }

  private applyMode(mode: ThemeMode, withTransitionGuard: boolean): void {
    if (withTransitionGuard) this.rootElement.classList.add('theme-switching');
    this.mode.set(mode);
    this.rootElement.classList.toggle('dark', mode === 'dark');
    this.updatePrimaryContrastColor();
    if (withTransitionGuard) {
      requestAnimationFrame(() => requestAnimationFrame(() => this.rootElement.classList.remove('theme-switching')));
    }
  }

  /** Sets the 50-950 ramp of the chosen palette and the semantic tokens derived from it:
   *  color = 500, hover = 600, active = 700, the same in light and dark. */
  private applyPrimaryPaletteVars(palette: Record<string, string>): void {
    for (const [shade, value] of Object.entries(palette)) {
      this.rootElement.style.setProperty(`--as-primary-${shade}`, value);
    }

    this.rootElement.style.setProperty('--as-primary-color', palette['500']);
    this.rootElement.style.setProperty('--as-primary-hover-color', palette['600']);
    this.rootElement.style.setProperty('--as-primary-active-color', palette['700']);
  }

  /** Sets the 50-950 ramp of the chosen surface palette. */
  private applySurfacePaletteVars(palette: Record<string, string>): void {
    for (const [shade, value] of Object.entries(palette)) {
      this.rootElement.style.setProperty(`--as-surface-${shade}`, value);
    }

    this.updatePrimaryContrastColor();
  }

  /** The one semantic token that changes between light and dark: white in light, the 900 shade
   *  of the chosen surface palette in dark. */
  private updatePrimaryContrastColor(): void {
    const contrast = this.mode() === 'dark' ? (getSurfaceColor(this.surfaceColorKey()).palette['900'] ?? '#171717') : '#ffffff';
    this.rootElement.style.setProperty('--as-primary-contrast-color', contrast);
  }
}
