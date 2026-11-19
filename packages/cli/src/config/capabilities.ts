export type CapabilityCategory =
  'architecture' | 'routing' | 'style' | 'rendering' | 'components' | 'icons' | 'packageManager';

export interface CapabilityOption {
  readonly id: string;
  readonly label: string;
  /** False for options that are planned but cannot be generated yet. */
  readonly available: boolean;
  readonly recommended?: boolean;
  /** Architectures this option can be generated on; any architecture when absent. */
  readonly requiresArchitecture?: readonly string[];
}

/**
 * Single registry of everything `as new` can offer. Setting `available` to true is the only change
 * needed to expose an option in the wizard, in `--help` and in `as list`.
 */
export const CAPABILITIES: Readonly<Record<CapabilityCategory, readonly CapabilityOption[]>> = {
  architecture: [
    { id: 'angular-default', label: 'Angular default structure', available: true },
    { id: 'screaming', label: 'Screaming Architecture', available: true },
    { id: 'modular', label: 'Modular Architecture', available: false },
    { id: 'hexagonal', label: 'Hexagonal Architecture', available: false },
    { id: 'clean', label: 'Clean Architecture', available: false },
    { id: 'feature-sliced', label: 'Feature-Sliced Design', available: false },
  ],
  routing: [
    { id: 'angular', label: 'Default Angular Routing', available: true },
    {
      id: 'starter',
      label: 'Angular Starter Routing',
      available: true,
      requiresArchitecture: ['screaming'],
    },
  ],
  style: [
    { id: 'css', label: 'CSS', available: true, recommended: true },
    { id: 'scss', label: 'SCSS (Sass)', available: true },
    { id: 'sass', label: 'Indented Sass', available: true },
    { id: 'less', label: 'Less', available: true },
  ],
  rendering: [
    { id: 'csr', label: 'Client-Side Rendering', available: true },
    { id: 'ssr', label: 'Default Angular SSR', available: true },
    { id: 'starter-ssr', label: 'Angular Starter SSR + Incremental Hydration', available: false },
  ],
  components: [
    { id: 'none', label: 'None', available: true },
    { id: 'recommended', label: 'Recommended component collection', available: false },
    { id: 'all', label: 'All available components', available: false },
  ],
  icons: [
    { id: 'none', label: 'None', available: true },
    { id: 'lucide', label: 'Lucide Icons', available: true, recommended: true },
    { id: 'heroicons', label: 'Heroicons', available: false },
    { id: 'phosphor', label: 'Phosphor Icons', available: false },
    { id: 'tabler', label: 'Tabler Icons', available: false },
    { id: 'bootstrap-icons', label: 'Bootstrap Icons', available: false },
  ],
  packageManager: [
    { id: 'npm', label: 'npm', available: true },
    { id: 'pnpm', label: 'pnpm', available: true },
    { id: 'yarn', label: 'yarn', available: true },
  ],
};

/** The App Shell is a yes/no capability, so it lives outside the option lists. */
export const APP_SHELL_AVAILABLE = false;

export const CATEGORIES = Object.keys(CAPABILITIES) as CapabilityCategory[];

export function availableOptions(category: CapabilityCategory): readonly CapabilityOption[] {
  return CAPABILITIES[category].filter((option) => option.available);
}

export function availableIds(category: CapabilityCategory): string[] {
  return availableOptions(category).map((option) => option.id);
}

/** Whether `option` can be generated on `architecture`. */
export function supportsArchitecture(option: CapabilityOption, architecture: string): boolean {
  return option.requiresArchitecture?.includes(architecture) ?? true;
}

export function isAvailable(category: CapabilityCategory, id: string): boolean {
  return CAPABILITIES[category].some((option) => option.id === id && option.available);
}
