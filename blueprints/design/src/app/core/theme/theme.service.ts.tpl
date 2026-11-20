import { DOCUMENT } from '@angular/common';
import { Injectable, inject, signal } from '@angular/core';
import { getPrimaryColor, getSurfaceColor } from './theme-palettes';
import {
  getStoredMode,
  getStoredPrimaryKey,
  getStoredSurfaceKey,
  setStoredMode,
  setStoredPrimaryKey,
  setStoredSurfaceKey,
  type ThemeMode,
} from './theme-storage';

export type { ThemeMode } from './theme-storage';

/**
 * Light and dark mode, the primary (accent) color and the surface (neutral) color of the app.
 *
 * The design tokens in `src/styles/tokens.css` already define a default theme, so the first paint
 * is right; this service only changes them at run time: `dark` class on `<html>`, the
 * `--as-primary-*` and `--as-surface-*` ramps, and the preference saved in the browser.
 */
@Injectable({ providedIn: 'root' })
export class ThemeService {
  private readonly root = inject(DOCUMENT).documentElement;

  readonly mode = signal<ThemeMode>('light');
  readonly primaryColorKey = signal('');
  readonly surfaceColorKey = signal('');

  /** Applies the saved preference, or the one the operating system asks for. */
  initialize(): void {
    const preferred = globalThis.matchMedia?.('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
    this.applyMode(getStoredMode() ?? preferred);
    this.applyPrimary(getStoredPrimaryKey());
    this.applySurface(getStoredSurfaceKey());
  }

  setMode(mode: ThemeMode): void {
    this.applyMode(mode);
    setStoredMode(mode);
  }

  toggleMode(): void {
    this.setMode(this.mode() === 'dark' ? 'light' : 'dark');
  }

  setPrimaryColor(key: string): void {
    this.applyPrimary(key);
    setStoredPrimaryKey(this.primaryColorKey());
  }

  setSurfaceColor(key: string): void {
    this.applySurface(key);
    setStoredSurfaceKey(this.surfaceColorKey());
  }

  private applyMode(mode: ThemeMode): void {
    this.mode.set(mode);
    this.root.classList.toggle('dark', mode === 'dark');
  }

  private applyPrimary(key: string): void {
    const color = getPrimaryColor(key);
    for (const [shade, value] of Object.entries(color.palette)) {
      this.root.style.setProperty(`--as-primary-${shade}`, value);
    }
    this.primaryColorKey.set(color.key);
  }

  private applySurface(key: string): void {
    const color = getSurfaceColor(key);
    for (const [shade, value] of Object.entries(color.palette)) {
      this.root.style.setProperty(`--as-surface-${shade}`, value);
    }
    this.surfaceColorKey.set(color.key);
  }
}
