import { CAPABILITIES, CATEGORIES, type CapabilityCategory } from '../config/capabilities.js';
import { UsageError } from '../errors.js';
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
    }
  });
}

function selectCategories(category: string | undefined): CapabilityCategory[] {
  if (category === undefined) return CATEGORIES;
  const match = CATEGORIES.find((name) => name === category);
  if (!match) {
    throw new UsageError(
      `Unknown category "${category}". Choose one of: ${CATEGORIES.join(', ')}.`,
    );
  }
  return [match];
}
