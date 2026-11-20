/**
 * Solid swatches used as accent colors: the background of avatars without a photo and any
 * "brand color" picker. They live in shared/ so every feature can use them without depending on
 * another feature.
 */
export const PREVIEW_ACCENTS = ['#2563eb', '#f97316', '#7c3aed', '#16a34a', '#171717', '#ef4444', '#3b82f6', '#ca8a04', '#dc2626', '#0d9488', '#6366f1'] as const;

/**
 * The "black" swatch of the palette. Mixing it with `var(--app-panel-bg)` makes it disappear in
 * dark mode (black on a dark panel has almost no contrast), so where it is used as a background tint
 * swap it for a neutral gray (`--app-panel-muted-bg`) instead of mixing it.
 */
export const NEUTRAL_ACCENT: string = PREVIEW_ACCENTS[4];
