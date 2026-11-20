import { DEFAULT_PRIMARY_COLOR_KEY, DEFAULT_SURFACE_COLOR_KEY } from './theme-palettes';

export type ThemeMode = 'light' | 'dark';

const MODE_KEY = '__PROJECT_NAME__:theme-mode';
const PRIMARY_KEY = '__PROJECT_NAME__:theme-primary';
const SURFACE_KEY = '__PROJECT_NAME__:theme-surface';

function read(key: string): string | null {
  try {
    return globalThis.localStorage?.getItem(key) ?? null;
  } catch {
    // Storage is missing on the server and blocked in some private windows.
    return null;
  }
}

function write(key: string, value: string): void {
  try {
    globalThis.localStorage?.setItem(key, value);
  } catch {
    // The preference is best effort: the theme still works for this visit.
  }
}

export function getStoredMode(): ThemeMode | null {
  const saved = read(MODE_KEY);
  return saved === 'dark' || saved === 'light' ? saved : null;
}

export const setStoredMode = (mode: ThemeMode): void => write(MODE_KEY, mode);

export const getStoredPrimaryKey = (): string => read(PRIMARY_KEY) ?? DEFAULT_PRIMARY_COLOR_KEY;

export const setStoredPrimaryKey = (key: string): void => write(PRIMARY_KEY, key);

export const getStoredSurfaceKey = (): string => read(SURFACE_KEY) ?? DEFAULT_SURFACE_COLOR_KEY;

export const setStoredSurfaceKey = (key: string): void => write(SURFACE_KEY, key);
