import { CAPABILITIES, availableIds, type CapabilityCategory } from '../config/capabilities.js';
import type { StarterOptions } from '../config/schema.js';

// What `sa` needs to describe `sa add` in its help, apart from the command itself: the command pulls in
// the whole engine, which the help, `--version` and `sa list` do not need to load.

/** The capabilities `sa add` can apply to an existing project, by the word the user types. */
export const ADDABLE: Readonly<Record<string, Extract<CapabilityCategory, keyof StarterOptions>>> =
  {
    icons: 'icons',
    components: 'components',
    routing: 'routing',
    'app-shell': 'appShell',
    presence: 'presence',
    'ui-system': 'uiSystem',
    rendering: 'rendering',
    architecture: 'architecture',
  };

/** Options that are "off" in a project and that adding a capability can turn on. */
export const NOT_ADDABLE: Readonly<Record<string, readonly string[]>> = {
  icons: ['none'],
  components: ['none', 'custom'],
  routing: ['angular'],
  'app-shell': ['none'],
  presence: ['none'],
  'ui-system': ['none'],
  rendering: ['csr'],
  architecture: ['angular-default'],
};

/** The values of a capability that can be added, from the registry. */
export function addableValues(capability: string): string[] {
  const category = ADDABLE[capability];
  if (!category) return [];
  return availableIds(category).filter((id) => !NOT_ADDABLE[capability]?.includes(id));
}

/** The word `sa add` takes for a category, when a project can add it. */
export const ADD_WORD: ReadonlyMap<string, string> = new Map(
  Object.entries(ADDABLE).map(([word, category]) => [category, word]),
);

export interface AddStep {
  capability: string;
  value: string;
}

/** The requirements of an option that adding a capability can satisfy. */
const PREREQUISITE_KEYS = ['architecture', 'routing', 'appShell'] as const;

/**
 * What an option needs that the developer chooses and `sa add` never adds on their behalf: which
 * components the project gets is their decision (a collection or their own selection), so the chain
 * stops and names the command instead of picking a collection for them.
 */
const CHOSEN_KEYS = ['components'] as const;

/** The requirements of `option` that the developer must settle first, as the `sa add` word that does. */
export function unchosenOf(
  category: CapabilityCategory,
  id: string,
  options: StarterOptions,
): AddStep[] {
  const option = CAPABILITIES[category].find((candidate) => candidate.id === id);
  const steps: AddStep[] = [];
  for (const key of CHOSEN_KEYS) {
    const accepted = option?.requires?.[key] as readonly string[] | undefined;
    const capability = ADD_WORD.get(key);
    if (accepted && capability !== undefined && !accepted.includes(options[key])) {
      steps.push({ capability, value: '' });
    }
  }
  return steps;
}

/**
 * What `option` needs that the project does not have and that `sa add` can bring, in the order to add
 * it: the registry says what each option requires, so a capability that needs another one is added
 * after it. A requirement `sa add` cannot satisfy (the rendering, Tailwind CSS) is left to the check
 * that names it.
 */
export function prerequisitesOf(
  category: CapabilityCategory,
  id: string,
  options: StarterOptions,
): AddStep[] {
  const option = CAPABILITIES[category].find((candidate) => candidate.id === id);
  const steps: AddStep[] = [];
  const has = (capability: string): boolean => steps.some((step) => step.capability === capability);
  for (const key of PREREQUISITE_KEYS) {
    const accepted = option?.requires?.[key] as readonly string[] | undefined;
    const actual: string = options[key];
    if (!accepted || accepted.includes(actual)) continue;
    const capability = ADD_WORD.get(key);
    const value = accepted.find(
      (candidate) => capability !== undefined && addableValues(capability).includes(candidate),
    );
    if (capability === undefined || value === undefined) continue;
    for (const inner of prerequisitesOf(key, value, options))
      if (!has(inner.capability)) steps.push(inner);
    if (!has(capability)) steps.push({ capability, value });
  }
  return steps;
}
