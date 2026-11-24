export interface SaSvg {
  name: string;
  url: string;
  /** Tinted with the primary color instead of following `currentColor`. */
  colored?: boolean;
}

/**
 * Local SVG files that `sa-icon` renders by name, next to the Lucide icons. Put the files in
 * `public/assets/svg/` and register each one here: `{ name: 'Logo', url: 'assets/svg/logo.svg' }`.
 */
export const SaIconsSVG: SaSvg[] = [];
