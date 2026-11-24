import { CAPABILITIES, CATEGORIES, type CapabilityCategory } from '../config/capabilities.js';
import { UsageError } from '../errors.js';
import { ADDABLE, addableValues } from './addable.js';
import { println, type CliIo } from '../io.js';
import { createStyler } from '../ui/format.js';

const TITLES: Record<CapabilityCategory, string> = {
  architecture: 'Architectures',
  routing: 'Routing systems',
  style: 'Stylesheet formats',
  rendering: 'Rendering strategies',
  ssrPurpose: 'Purposes of the Starter SSR',
  appShell: 'Application shells',
  layout: 'Layout modes of the application shell',
  presence: 'Presence',
  components: 'Native UI components',
  uiSystem: 'UI Systems',
  icons: 'Icon libraries',
  packageManager: 'Package managers',
};

/** The flag of `as new` that sets each category. */
const NEW_FLAGS: Record<CapabilityCategory, string> = {
  architecture: '--architecture',
  routing: '--routing',
  style: '--style',
  rendering: '--rendering',
  ssrPurpose: '--ssr-purpose',
  appShell: '--app-shell',
  layout: '--layout',
  presence: '--presence',
  components: '--components',
  uiSystem: '--ui-system',
  icons: '--icons',
  packageManager: '--package-manager',
};

/** The word `as add` takes for a category, when a project can add it. */
const ADD_WORD = new Map(Object.entries(ADDABLE).map(([word, category]) => [category, word]));

/** The kebab-case spelling of a category: `app-shell` for `appShell`. */
const kebab = (name: string): string =>
  name.replace(/[A-Z]/g, (letter) => `-${letter.toLowerCase()}`);

export function listCommand(io: CliIo, category?: string): void {
  const style = createStyler(io.color);
  const selected = selectCategories(category);
  selected.forEach((name, index) => {
    if (index > 0) println(io.stdout);
    println(io.stdout, style.bold(`${TITLES[name]} (${name})`));
    const options = CAPABILITIES[name];
    const idWidth = Math.max(...options.map((option) => option.id.length));
    const margin = ' '.repeat(2 + idWidth + 2);
    for (const option of options) {
      const badge = option.available ? (option.recommended ? ' (Recommended)' : '') : ' (planned)';
      println(io.stdout, `  ${option.id.padEnd(idWidth)}  ${option.label}${badge}`);
      println(io.stdout, style.dim(`${margin}${option.description}`));
      if (option.docs) println(io.stdout, style.dim(`${margin}${option.docs}`));
      if (option.available) {
        const word = ADD_WORD.get(name);
        if (word && addableValues(word).includes(option.id)) {
          println(io.stdout, style.dim(`${margin}Add: as add ${word} ${option.id}`));
        }
        println(io.stdout, style.dim(`${margin}New: as new ${NEW_FLAGS[name]} ${option.id}`));
      }
    }
  });
}

function selectCategories(category: string | undefined): CapabilityCategory[] {
  if (category === undefined) return CATEGORIES;
  const match = CATEGORIES.find((name) => name === category || kebab(name) === category);
  if (!match) {
    throw new UsageError(
      `Unknown category "${category}". Choose one of: ${CATEGORIES.join(', ')}.`,
    );
  }
  return [match];
}
