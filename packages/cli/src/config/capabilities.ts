export type CapabilityCategory =
  | 'architecture'
  | 'routing'
  | 'style'
  | 'rendering'
  | 'ssrPurpose'
  | 'appShell'
  | 'layout'
  | 'presence'
  | 'components'
  | 'uiSystem'
  | 'icons'
  | 'packageManager';

/** What an option needs from the rest of the project; any value is accepted when a key is absent. */
export interface OptionRequirements {
  readonly architecture?: readonly string[];
  readonly routing?: readonly string[];
  readonly rendering?: readonly string[];
  /** The application shell the option is built on. */
  readonly appShell?: readonly string[];
  /** The component collection the option previews or extends. */
  readonly components?: readonly string[];
  /** Stylesheet format (`css` also covers Tailwind CSS). */
  readonly style?: readonly string[];
  /** True when the option only works in a project that uses Tailwind CSS. */
  readonly tailwind?: true;
  readonly icons?: readonly string[];
}

export interface CapabilityOption {
  readonly id: string;
  readonly label: string;
  /** One sentence: what it is, how it looks and when to use it. Shown by the wizard and `sa list`. */
  readonly description: string;
  /** Official documentation of what gets installed; absent when nothing is installed. */
  readonly docs?: string;
  /** False for options that are planned but cannot be generated yet. */
  readonly available: boolean;
  /** Badge and preselection in the wizard: only for what has one best answer. */
  readonly recommended?: boolean;
  /** What `--defaults` and a flag-less run pick, without any badge in the wizard. */
  readonly default?: boolean;
  /** What a project cannot be generated without: validated by `sa new` and by `sa add`. */
  readonly requires?: OptionRequirements;
  /**
   * What the wizard and `--defaults` need to offer the option: the same shape as `requires`, but a
   * project that has the option without it is still valid (ADR-0010).
   */
  readonly offeredWith?: OptionRequirements;
}

export type Registry = Readonly<Record<CapabilityCategory, readonly CapabilityOption[]>>;

/** The choices that decide whether an option can be used; unknown ones are not checked. */
export interface RequirementContext {
  architecture?: string;
  routing?: string;
  rendering?: string;
  appShell?: string;
  components?: string;
  style?: string;
  tailwind?: boolean;
  icons?: string;
}

const STARTER_DOCS = 'https://github.com/LiriRaid/starter-angular/blob/main/docs/adr';
const STARTER_PRESENCE_DOCS = `${STARTER_DOCS}/0009-presence-documentation-and-welcome-home.md`;
const STARTER_COMPONENTS_DOCS = `${STARTER_DOCS}/0011-components-picker-and-design-preferences-tabs.md`;
const STARTER_ROUTED_DOCS = `${STARTER_DOCS}/0010-routed-wizard-layout-modes-and-design-preferences.md`;

/**
 * The categories whose options that cannot be generated yet are still listed by the wizard, disabled
 * and marked as under construction, so a developer sees the map of the product (ADR-0010).
 */
export const SHOWN_WHEN_PLANNED: readonly CapabilityCategory[] = ['ssrPurpose', 'layout'];

/**
 * Single registry of everything `sa new` can offer. Setting `available` to true is the only change
 * needed to expose an option in the wizard, in `--help` and in `sa list`; the wizard, the help and
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
      docs: `${STARTER_DOCS}/0002-screaming-architecture-profile.md`,
      available: true,
      default: true,
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
      label: 'Starter Angular Routing',
      description:
        'One navigation tree that feeds page titles and breadcrumbs, ready for a sidebar. Needs the Screaming Architecture.',
      docs: `${STARTER_DOCS}/0003-starter-routing.md`,
      available: true,
      default: true,
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
      label: 'Starter Angular SSR + Incremental Hydration',
      description:
        'Default SSR plus incremental hydration, event replay and view transitions, with a @defer (hydrate on viewport) example as in the maintainer portfolio. Use it for content-heavy public sites.',
      docs: 'https://angular.dev/guide/incremental-hydration',
      available: true,
      offeredWith: { architecture: ['screaming'] },
    },
  ],
  ssrPurpose: [
    {
      id: 'none',
      label: 'None',
      description: 'Not applicable: only the Starter Angular SSR has a purpose.',
      docs: STARTER_ROUTED_DOCS,
      available: true,
      requires: { rendering: ['csr', 'ssr'] },
    },
    {
      id: 'landing',
      label: 'Landing page',
      description:
        'A public page rendered on the server, with its own shell and sections for search engines. Under construction.',
      docs: STARTER_ROUTED_DOCS,
      available: false,
      requires: { rendering: ['starter-ssr'] },
    },
    {
      id: 'ecommerce',
      label: 'Ecommerce',
      description:
        'A storefront with catalog, product pages and cart, rendered on the server. Under construction.',
      docs: STARTER_ROUTED_DOCS,
      available: false,
      requires: { rendering: ['starter-ssr'] },
    },
    {
      id: 'backoffice',
      label: 'Backoffice',
      description:
        'An administration application with tables, forms and dashboards, with incremental hydration. The application shell is client-side for now.',
      docs: STARTER_ROUTED_DOCS,
      available: true,
      default: true,
      requires: { rendering: ['starter-ssr'] },
    },
  ],
  appShell: [
    {
      id: 'none',
      label: 'None',
      description:
        'No application shell: the project keeps the default Angular look, with no sidebar, header or content layout, and the root component is just the router outlet. You can add it later with sa add app-shell.',
      docs: `${STARTER_DOCS}/0008-app-shell.md`,
      available: true,
    },
    {
      id: 'starter',
      label: 'Starter Angular App Shell',
      description:
        'A wide sidebar that floats, with the header and the content floating too, reading the navigation tree, with five example pages to try it. Needs the starter routing, Tailwind CSS and client-side rendering (server rendering is not supported yet).',
      docs: `${STARTER_DOCS}/0008-app-shell.md`,
      available: true,
      default: true,
      requires: {
        architecture: ['screaming'],
        routing: ['starter'],
        rendering: ['csr'],
        tailwind: true,
        icons: ['lucide'],
      },
    },
  ],
  layout: [
    {
      id: 'none',
      label: 'None',
      description: 'No application shell, so there is no layout to choose.',
      docs: STARTER_ROUTED_DOCS,
      available: true,
      requires: { appShell: ['none'] },
    },
    {
      id: 'wide-joined',
      label: 'Wide sidebar (joined)',
      description:
        'A wide sidebar with the icon and the text in a row, joined to the header and the content. Under construction.',
      docs: STARTER_ROUTED_DOCS,
      available: false,
      requires: { appShell: ['starter'] },
    },
    {
      id: 'compact-joined',
      label: 'Compact sidebar (joined)',
      description:
        'A compact sidebar with the icon above the text, joined to the header and the content. Under construction.',
      docs: STARTER_ROUTED_DOCS,
      available: false,
      requires: { appShell: ['starter'] },
    },
    {
      id: 'floating-wide',
      label: 'Floating (wide)',
      description:
        'A wide sidebar that floats, with the header and the content floating too: the layout of the reference application.',
      docs: STARTER_ROUTED_DOCS,
      available: true,
      recommended: true,
      default: true,
      requires: { appShell: ['starter'] },
    },
    {
      id: 'floating-compact',
      label: 'Floating (compact)',
      description:
        'A compact sidebar with the header and the content floating. Under construction.',
      docs: STARTER_ROUTED_DOCS,
      available: false,
      requires: { appShell: ['starter'] },
    },
    {
      id: 'transparent-joined',
      label: 'Transparent (joined)',
      description:
        'A sidebar with no background, joined to the header and the content. Under construction.',
      docs: STARTER_ROUTED_DOCS,
      available: false,
      requires: { appShell: ['starter'] },
    },
    {
      id: 'transparent-floating',
      label: 'Transparent (floating)',
      description:
        'A sidebar with no background and the header and the content floating. Under construction.',
      docs: STARTER_ROUTED_DOCS,
      available: false,
      requires: { appShell: ['starter'] },
    },
  ],
  presence: [
    {
      id: 'none',
      label: 'None',
      description:
        'No presence: the user menu has no status. You can add it later with sa add presence.',
      docs: STARTER_PRESENCE_DOCS,
      available: true,
    },
    {
      id: 'starter',
      label: 'Starter Angular Presence',
      description:
        'The user status of the reference (online, away, busy, invisible, with a duration) in the user menu, automatic away on inactivity, and a transport contract with an in-memory mock and a WebSocket transport, plus a guide to connect Redis and your API. Needs the application shell.',
      docs: STARTER_PRESENCE_DOCS,
      available: true,
      requires: { appShell: ['starter'] },
    },
  ],
  components: [
    {
      id: 'none',
      label: 'None',
      description: 'No native components. You can add them later with sa add components.',
      docs: `${STARTER_DOCS}/0007-omni-structure-design-and-components.md`,
      available: true,
    },
    {
      id: 'recommended',
      label: 'Essential component collection',
      description:
        'The essential 16 sa- components (icon, button, input, textarea, checkbox, toggle, select, avatar, divider, skeleton, tooltip, modal, drawer, toast, tabs and popover) with the design base: tokens, light and dark theme, typography and animations. Needs Tailwind CSS.',
      docs: `${STARTER_DOCS}/0007-omni-structure-design-and-components.md`,
      available: true,
      default: true,
      requires: { tailwind: true, icons: ['lucide'] },
      offeredWith: { architecture: ['screaming'] },
    },
    {
      id: 'all',
      label: 'All available components',
      description:
        'All 26 sa- components: the 16 of the essential collection plus ten more (table, search, datepicker, section-nav, selectable-item, reorder-list, preview, media-preview, theme-color-picker and weekly-schedule), with the design base. Needs Tailwind CSS.',
      docs: `${STARTER_DOCS}/0007-omni-structure-design-and-components.md`,
      available: true,
      requires: { tailwind: true, icons: ['lucide'] },
      offeredWith: { architecture: ['screaming'] },
    },
    {
      id: 'custom',
      label: 'Custom selection',
      description:
        'The components you tick one by one (--components button,modal,toast): each one comes with the components it imports. Needs Tailwind CSS.',
      docs: STARTER_COMPONENTS_DOCS,
      available: true,
      requires: { tailwind: true, icons: ['lucide'] },
      offeredWith: { architecture: ['screaming'] },
    },
  ],
  uiSystem: [
    {
      id: 'none',
      label: 'None',
      description:
        'No UI System: the components keep the design base as it is generated. You can add it later with sa add ui-system.',
      docs: STARTER_ROUTED_DOCS,
      available: true,
    },
    {
      id: 'starter',
      label: 'Starter Angular UI System',
      description:
        'A catalog of the installed sa- components with a preview of each one, its code and what it affects, and the design tokens (radius, button size, density, font size) that you change in real time from the design preferences page. Needs the application shell and a component collection.',
      docs: STARTER_ROUTED_DOCS,
      available: true,
      requires: {
        architecture: ['screaming'],
        appShell: ['starter'],
        components: ['recommended', 'all'],
        tailwind: true,
      },
    },
  ],
  icons: [
    {
      id: 'none',
      label: 'None',
      description: 'No icon library; add one later with sa add icons.',
      available: true,
    },
    {
      id: 'lucide',
      label: 'Lucide Icons',
      description:
        'Open-source icon set (@lucide/angular): crisp stroke icons, tree-shaken. The sa-icon component renders them.',
      docs: 'https://lucide.dev/guide/angular/getting-started',
      available: true,
      recommended: true,
      offeredWith: { architecture: ['screaming'] },
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

const REQUIREMENT_TEXT: Record<
  'architecture' | 'routing' | 'rendering' | 'appShell' | 'components' | 'style' | 'icons',
  string
> = {
  architecture: 'the architecture',
  routing: 'the routing',
  rendering: 'the rendering',
  appShell: 'the app shell',
  components: 'the components',
  style: 'the stylesheet format',
  icons: 'the icons',
};

function unmet(
  requirements: OptionRequirements | undefined,
  context: RequirementContext,
): string[] {
  const missing: string[] = [];
  if (!requirements) return missing;
  for (const key of Object.keys(REQUIREMENT_TEXT) as (keyof typeof REQUIREMENT_TEXT)[]) {
    const accepted = requirements[key];
    const actual = context[key];
    if (accepted && actual !== undefined && !accepted.includes(actual)) {
      missing.push(`${REQUIREMENT_TEXT[key]}: ${accepted.join(', ')}`);
    }
  }
  if (requirements.tailwind && context.tailwind === false) missing.push('Tailwind CSS');
  return missing;
}

/**
 * What `option` needs that `context` does not provide, as "the architecture: screaming". A choice
 * the context does not know yet is not checked.
 */
export function unmetRequirements(option: CapabilityOption, context: RequirementContext): string[] {
  return unmet(option.requires, context);
}

/** True when a project with `context` can have the option and the wizard and `--defaults` offer it. */
const usable = (option: CapabilityOption, context: RequirementContext): boolean =>
  unmet(option.requires, context).length === 0 && unmet(option.offeredWith, context).length === 0;

/** The options of a category that can be generated and that fit what `context` already holds. */
export function offeredOptions(
  category: CapabilityCategory,
  context: RequirementContext,
  registry: Registry = CAPABILITIES,
): readonly CapabilityOption[] {
  return availableOptions(category, registry).filter((option) => usable(option, context));
}

/**
 * The options the wizard lists as under construction: they fit `context` but cannot be generated
 * yet. Only the categories of `SHOWN_WHEN_PLANNED` have any.
 */
export function plannedOptions(
  category: CapabilityCategory,
  context: RequirementContext,
  registry: Registry = CAPABILITIES,
): readonly CapabilityOption[] {
  if (!SHOWN_WHEN_PLANNED.includes(category)) return [];
  return registry[category].filter((option) => !option.available && usable(option, context));
}

/** The recommended option of a category that can be generated with what `context` already holds. */
export function recommendedOption(
  category: CapabilityCategory,
  context: RequirementContext,
  registry: Registry = CAPABILITIES,
): CapabilityOption | undefined {
  return offeredOptions(category, context, registry).find((option) => option.recommended);
}

/**
 * The option `--defaults` picks for a category: the default, or the recommended one when the
 * category has no default, among those `context` allows.
 */
export function defaultOption(
  category: CapabilityCategory,
  context: RequirementContext,
  registry: Registry = CAPABILITIES,
): CapabilityOption | undefined {
  const options = offeredOptions(category, context, registry);
  return options.find((option) => option.default) ?? options.find((option) => option.recommended);
}
