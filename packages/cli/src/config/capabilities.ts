export type CapabilityCategory =
  'architecture' | 'routing' | 'style' | 'rendering' | 'components' | 'icons' | 'packageManager';

/** What an option needs from the rest of the project; any value is accepted when a key is absent. */
export interface OptionRequirements {
  readonly architecture?: readonly string[];
  /** Stylesheet format (`css` also covers Tailwind CSS). */
  readonly style?: readonly string[];
  readonly icons?: readonly string[];
}

export interface CapabilityOption {
  readonly id: string;
  readonly label: string;
  /** One sentence: what it is, how it looks and when to use it. Shown by the wizard and `as list`. */
  readonly description: string;
  /** Official documentation of what gets installed; absent when nothing is installed. */
  readonly docs?: string;
  /** False for options that are planned but cannot be generated yet. */
  readonly available: boolean;
  readonly recommended?: boolean;
  readonly requires?: OptionRequirements;
}

export type Registry = Readonly<Record<CapabilityCategory, readonly CapabilityOption[]>>;

/** The choices that decide whether an option can be used; unknown ones are not checked. */
export interface RequirementContext {
  architecture?: string;
  style?: string;
  icons?: string;
}

const STARTER_DOCS = 'https://github.com/LiriRaid/as-starter/blob/main/docs/adr';

/**
 * Single registry of everything `as new` can offer. Setting `available` to true is the only change
 * needed to expose an option in the wizard, in `--help` and in `as list`; the wizard, the help and
 * the list read every text from here.
 */
export const CAPABILITIES: Registry = {
  architecture: [
    {
      id: 'angular-default',
      label: 'Angular default structure',
      description:
        'The folders ng new generates, untouched: a flat src/app with the root component, ready for you to organize.',
      docs: 'https://angular.dev/style-guide',
      available: true,
    },
    {
      id: 'screaming',
      label: 'Screaming Architecture',
      description:
        'core/ for infrastructure, features/ with one folder per business capability and shared/ for reusable pieces, with @core, @features and @shared aliases.',
      docs: 'https://blog.cleancoder.com/uncle-bob/2011/09/30/Screaming-Architecture.html',
      available: true,
      recommended: true,
    },
    {
      id: 'modular',
      label: 'Modular Architecture',
      description: 'Self-contained modules with explicit public APIs between them.',
      docs: 'https://angular.dev/style-guide',
      available: false,
    },
    {
      id: 'hexagonal',
      label: 'Hexagonal Architecture',
      description: 'A domain core isolated from the framework behind ports and adapters.',
      docs: 'https://alistair.cockburn.us/hexagonal-architecture/',
      available: false,
    },
    {
      id: 'clean',
      label: 'Clean Architecture',
      description: 'Concentric layers where dependencies only point towards the domain.',
      docs: 'https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html',
      available: false,
    },
    {
      id: 'feature-sliced',
      label: 'Feature-Sliced Design',
      description: 'Layers, slices and segments with strict import rules between them.',
      docs: 'https://feature-sliced.design',
      available: false,
    },
  ],
  routing: [
    {
      id: 'angular',
      label: 'Default Angular Routing',
      description: 'The Angular router with an empty route table, as ng new generates it.',
      docs: 'https://angular.dev/guide/routing',
      available: true,
    },
    {
      id: 'starter',
      label: 'Angular Starter Routing',
      description:
        'One navigation tree that feeds page titles and breadcrumbs, ready for a sidebar. Needs the Screaming Architecture.',
      docs: `${STARTER_DOCS}/0003-starter-routing.md`,
      available: true,
      recommended: true,
      requires: { architecture: ['screaming'] },
    },
  ],
  style: [
    {
      id: 'css',
      label: 'CSS',
      description: 'Plain CSS files with no extra tooling.',
      docs: 'https://developer.mozilla.org/docs/Web/CSS',
      available: true,
    },
    {
      id: 'tailwind',
      label: 'Tailwind CSS',
      description:
        'Utility-first CSS through the official PostCSS plugin; your stylesheets stay plain .css.',
      docs: 'https://tailwindcss.com',
      available: true,
      recommended: true,
    },
    {
      id: 'scss',
      label: 'SCSS (Sass)',
      description: 'Sass with the CSS-like syntax: variables, nesting and mixins.',
      docs: 'https://sass-lang.com/documentation/syntax#scss',
      available: true,
    },
    {
      id: 'sass',
      label: 'Sass (Indented)',
      description: 'Sass with the original indented syntax, no braces or semicolons.',
      docs: 'https://sass-lang.com/documentation/syntax#the-indented-syntax',
      available: true,
    },
    {
      id: 'less',
      label: 'Less',
      description: 'Less: variables, mixins and nesting compiled to CSS.',
      docs: 'https://lesscss.org',
      available: true,
    },
  ],
  rendering: [
    {
      id: 'csr',
      label: 'Client-Side Rendering',
      description:
        'No server rendering: the browser builds the page. Static hosting and the best fit for back offices and apps behind a login.',
      docs: 'https://angular.dev/overview',
      available: true,
      recommended: true,
    },
    {
      id: 'ssr',
      label: 'Default Angular SSR',
      description:
        'Angular server-side rendering with hydration (ng new --ssr): the server sends ready HTML. Use it for public pages that need SEO or a fast first paint.',
      docs: 'https://angular.dev/guide/ssr',
      available: true,
    },
    {
      id: 'starter-ssr',
      label: 'Angular Starter SSR + Incremental Hydration',
      description:
        'Default SSR plus incremental hydration, event replay and view transitions, with a @defer (hydrate on viewport) example as in the maintainer portfolio. Use it for content-heavy public sites.',
      docs: 'https://angular.dev/guide/incremental-hydration',
      available: true,
    },
  ],
  components: [
    {
      id: 'none',
      label: 'None',
      description: 'No native components. You can add them later with as add components.',
      docs: `${STARTER_DOCS}/0005-design-base-and-native-components.md`,
      available: true,
    },
    {
      id: 'recommended',
      label: 'Recommended component collection',
      description:
        'Design tokens, light and dark theme, utilities and 16 as- components: icon, button, input, textarea, checkbox, toggle, select, avatar, divider, skeleton, tooltip, modal, drawer, toast, tabs and popover.',
      docs: `${STARTER_DOCS}/0005-design-base-and-native-components.md`,
      available: false,
      recommended: true,
      requires: { architecture: ['screaming'], style: ['css'], icons: ['lucide'] },
    },
    {
      id: 'all',
      label: 'All available components',
      description:
        'The recommended collection plus table, search, datepicker, section-nav, selectable-item, reorder-list, preview, media-preview, theme-color-picker and weekly-schedule.',
      docs: `${STARTER_DOCS}/0005-design-base-and-native-components.md`,
      available: false,
      requires: { architecture: ['screaming'], style: ['css'], icons: ['lucide'] },
    },
  ],
  icons: [
    {
      id: 'none',
      label: 'None',
      description: 'No icon library; add one later with as add icons.',
      available: true,
    },
    {
      id: 'lucide',
      label: 'Lucide Icons',
      description:
        'Open-source icon set (@lucide/angular): crisp stroke icons, tree-shaken. The as-icon component renders them.',
      docs: 'https://lucide.dev/guide/angular/getting-started',
      available: true,
      recommended: true,
    },
    {
      id: 'heroicons',
      label: 'Heroicons',
      description: 'Hand-crafted SVG icons by the makers of Tailwind CSS.',
      docs: 'https://heroicons.com',
      available: false,
    },
    {
      id: 'phosphor',
      label: 'Phosphor Icons',
      description: 'A flexible icon family with several weights.',
      docs: 'https://phosphoricons.com',
      available: false,
    },
    {
      id: 'tabler',
      label: 'Tabler Icons',
      description: 'Free, consistent stroke icons for web projects.',
      docs: 'https://tabler.io/icons',
      available: false,
    },
    {
      id: 'bootstrap-icons',
      label: 'Bootstrap Icons',
      description: 'The official open-source SVG icon library of Bootstrap.',
      docs: 'https://icons.getbootstrap.com',
      available: false,
    },
  ],
  packageManager: [
    {
      id: 'npm',
      label: 'npm',
      description: 'The package manager that ships with Node.js.',
      docs: 'https://docs.npmjs.com',
      available: true,
    },
    {
      id: 'pnpm',
      label: 'pnpm',
      description: 'Fast and disk-efficient installs with a strict node_modules layout.',
      docs: 'https://pnpm.io',
      available: true,
    },
    {
      id: 'yarn',
      label: 'yarn',
      description: 'Yarn: deterministic installs and workspaces.',
      docs: 'https://yarnpkg.com',
      available: true,
    },
  ],
};

/** The App Shell is a yes/no capability, so it lives outside the option lists. */
export const APP_SHELL_AVAILABLE = false;

export const CATEGORIES = Object.keys(CAPABILITIES) as CapabilityCategory[];

export function availableOptions(
  category: CapabilityCategory,
  registry: Registry = CAPABILITIES,
): readonly CapabilityOption[] {
  return registry[category].filter((option) => option.available);
}

export function availableIds(category: CapabilityCategory): string[] {
  return availableOptions(category).map((option) => option.id);
}

export function isAvailable(category: CapabilityCategory, id: string): boolean {
  return CAPABILITIES[category].some((option) => option.id === id && option.available);
}

const REQUIREMENT_TEXT: Record<keyof OptionRequirements, string> = {
  architecture: 'the architecture',
  style: 'the stylesheet format',
  icons: 'the icons',
};

/** What `option` needs that `context` does not provide, as "the architecture: screaming". */
export function unmetRequirements(option: CapabilityOption, context: RequirementContext): string[] {
  const unmet: string[] = [];
  for (const key of Object.keys(REQUIREMENT_TEXT) as (keyof OptionRequirements)[]) {
    const accepted = option.requires?.[key];
    const actual = context[key];
    if (accepted && actual !== undefined && !accepted.includes(actual)) {
      unmet.push(`${REQUIREMENT_TEXT[key]}: ${accepted.join(', ')}`);
    }
  }
  return unmet;
}

/** The recommended option of a category that can be generated with what `context` already holds. */
export function recommendedOption(
  category: CapabilityCategory,
  context: RequirementContext,
  registry: Registry = CAPABILITIES,
): CapabilityOption | undefined {
  return availableOptions(category, registry).find(
    (option) => option.recommended && unmetRequirements(option, context).length === 0,
  );
}
