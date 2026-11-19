import { UsageError } from '../errors.js';
import { APP_SHELL_AVAILABLE, CATEGORIES, availableIds, isAvailable } from './capabilities.js';
import { formatIssues } from './issues.js';
import { optionsSchema, type StarterOptions } from './schema.js';

export const DEFAULT_OPTIONS: StarterOptions = {
  architecture: 'angular-default',
  routing: 'angular',
  style: 'css',
  tailwind: true,
  rendering: 'csr',
  appShell: false,
  components: 'none',
  icons: 'none',
  packageManager: 'npm',
  prefix: 'app',
  git: true,
  install: true,
};

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
  const merged = { ...withoutUndefined(layers.file), ...withoutUndefined(layers.flags) };
  const style = merged.style ?? DEFAULT_OPTIONS.style;
  const candidate = { ...DEFAULT_OPTIONS, tailwind: style === 'css', ...merged };

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
