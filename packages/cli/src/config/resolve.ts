import { UsageError } from '../errors.js';
import {
  APP_SHELL_AVAILABLE,
  CAPABILITIES,
  CATEGORIES,
  availableIds,
  defaultOption,
  isAvailable,
  unmetRequirements,
  type CapabilityCategory,
  type RequirementContext,
} from './capabilities.js';
import { formatIssues } from './issues.js';
import { optionsSchema, type StarterOptions } from './schema.js';

/** A given value, else the registry's default for the category among what `context` allows. */
function pick<T extends string>(
  given: T | undefined,
  category: CapabilityCategory,
  context: RequirementContext,
  fallback: T,
): T {
  return given ?? (defaultOption(category, context)?.id as T | undefined) ?? fallback;
}

/**
 * The defaults for everything that was not given: Screaming, Angular Starter Routing, Tailwind CSS,
 * Client-Side Rendering, Lucide and the essential components. Each one is derived from what was
 * already chosen so a default never conflicts with a choice: with SCSS there is no Tailwind CSS and
 * no component collection, without the Screaming Architecture the routing is Angular's own.
 */
function defaultsFor(given: Partial<StarterOptions>): StarterOptions {
  const architecture = pick(given.architecture, 'architecture', {}, 'angular-default');
  const style = given.style ?? 'css';
  // An explicit stylesheet format means no Tailwind CSS unless it was asked for.
  const tailwind = given.tailwind ?? given.style === undefined;
  const icons = pick(given.icons, 'icons', {}, 'none');
  const context = { architecture, style, tailwind, icons };
  return {
    architecture,
    routing: pick(given.routing, 'routing', context, 'angular'),
    style,
    tailwind,
    rendering: pick(given.rendering, 'rendering', {}, 'csr'),
    appShell: false,
    components: pick(given.components, 'components', context, 'none'),
    icons,
    packageManager: 'npm',
    prefix: 'app',
    git: true,
    install: true,
  };
}

export const DEFAULT_OPTIONS: StarterOptions = defaultsFor({});

export interface OptionLayers {
  /** Values read from `--config`. */
  file?: Partial<StarterOptions>;
  /** Values given as command-line flags or answered in the wizard. They win over the file. */
  flags?: Partial<StarterOptions>;
}

/**
 * Merges every source into one validated `StarterOptions`. Interactive and non-interactive runs
 * both end here, so the generation engine only ever sees this one shape.
 */
export function resolveOptions(layers: OptionLayers = {}): StarterOptions {
  const merged = withStyleAlias({
    ...withoutUndefined(layers.file),
    ...withoutUndefined(layers.flags),
  });
  const candidate = { ...defaultsFor(merged), ...merged };

  const parsed = optionsSchema.safeParse(candidate);
  if (!parsed.success) {
    throw new UsageError(`Invalid options:\n${formatIssues(parsed.error)}`);
  }

  const problems = [...compatibilityProblems(parsed.data), ...availabilityProblems(parsed.data)];
  if (problems.length > 0) {
    throw new UsageError(
      `Invalid options:\n${problems.map((problem) => `  - ${problem}`).join('\n')}`,
    );
  }
  return parsed.data;
}

/** A configuration file may spell the "Tailwind CSS" entry of the stylesheet list as `style: tailwind`. */
function withStyleAlias(options: Partial<StarterOptions>): Partial<StarterOptions> {
  const { style, tailwind } = normalizeStyleChoice(options.style, options.tailwind);
  return withoutUndefined({ ...options, style, tailwind } as Partial<StarterOptions>);
}

function withoutUndefined<T extends object>(value: T | undefined): Partial<T> {
  if (!value) return {};
  return Object.fromEntries(
    Object.entries(value).filter(([, entry]) => entry !== undefined),
  ) as Partial<T>;
}

function compatibilityProblems(options: StarterOptions): string[] {
  const problems: string[] = [];
  if (options.tailwind && options.style !== 'css') {
    problems.push(
      `tailwind: Tailwind CSS requires the CSS stylesheet format; "${options.style}" cannot be combined with it.`,
    );
  }
  for (const category of CATEGORIES) {
    const option = CAPABILITIES[category].find((entry) => entry.id === options[category]);
    const unmet = option ? unmetRequirements(option, options) : [];
    if (option && unmet.length > 0) {
      problems.push(`${category}: "${options[category]}" requires ${unmet.join(' and ')}.`);
    }
  }
  return problems;
}

function availabilityProblems(options: StarterOptions): string[] {
  const problems: string[] = [];
  for (const category of CATEGORIES) {
    const value = options[category];
    if (!isAvailable(category, value)) {
      problems.push(
        `${category}: "${value}" is not available yet. Available: ${availableIds(category).join(', ')}.`,
      );
    }
  }
  if (options.appShell && !APP_SHELL_AVAILABLE) {
    problems.push('appShell: Angular Starter App Shell is not available yet.');
  }
  return problems;
}

/**
 * The stylesheet list offers "Tailwind CSS" next to the formats, but a project stores it as the CSS
 * format with Tailwind enabled; `--style tailwind` is that same choice.
 */
export function normalizeStyleChoice(
  style: string | undefined,
  tailwind: boolean | undefined,
): { style: string | undefined; tailwind: boolean | undefined } {
  if (style !== 'tailwind') return { style, tailwind };
  if (tailwind === false) {
    throw new UsageError('--style tailwind cannot be combined with --no-tailwind.');
  }
  return { style: 'css', tailwind: true };
}
