import { availableIds, type CapabilityCategory } from '../config/capabilities.js';
import type { StarterOptions } from '../config/schema.js';

// What `as` needs to describe `as add` in its help, apart from the command itself: the command pulls in
// the whole engine, which the help, `--version` and `as list` do not need to load.

/** The capabilities `as add` can apply to an existing project, by the word the user types. */
export const ADDABLE: Readonly<Record<string, Extract<CapabilityCategory, keyof StarterOptions>>> =
  {
    icons: 'icons',
    components: 'components',
    routing: 'routing',
    'app-shell': 'appShell',
    presence: 'presence',
    'ui-system': 'uiSystem',
    rendering: 'rendering',
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
};

/** The values of a capability that can be added, from the registry. */
export function addableValues(capability: string): string[] {
  const category = ADDABLE[capability];
  if (!category) return [];
  return availableIds(category).filter((id) => !NOT_ADDABLE[capability]?.includes(id));
}
