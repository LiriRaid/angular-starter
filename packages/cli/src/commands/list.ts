import { CAPABILITIES, CATEGORIES, type CapabilityCategory } from '../config/capabilities.js';
import { UsageError } from '../errors.js';
import { println, type CliIo } from '../io.js';
import { formatRows } from '../ui/format.js';

const TITLES: Record<CapabilityCategory, string> = {
  architecture: 'Architectures',
  routing: 'Routing systems',
  style: 'Stylesheet formats',
  rendering: 'Rendering strategies',
  components: 'Native UI components',
  icons: 'Icon libraries',
  packageManager: 'Package managers',
};

export function listCommand(io: CliIo, category?: string): void {
  const selected = selectCategories(category);
  selected.forEach((name, index) => {
    if (index > 0) println(io.stdout);
    println(io.stdout, `${TITLES[name]} (${name})`);
    const rows = CAPABILITIES[name].map(
      (option) => [option.id, `${option.label}${option.available ? '' : ' (planned)'}`] as const,
    );
    for (const line of formatRows(rows)) println(io.stdout, line);
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
