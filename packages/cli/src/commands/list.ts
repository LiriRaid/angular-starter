import { CAPABILITIES, CATEGORIES, type CapabilityCategory } from '../config/capabilities.js';
import { UsageError } from '../errors.js';
import { ADDABLE, addableValues } from './addable.js';
import { println, type CliIo } from '../io.js';
import { createStyler, wrapText } from '../ui/format.js';

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

/** The flag of `sa new` that sets each category. */
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

/** The word `sa add` takes for a category, when a project can add it. */
const ADD_WORD = new Map(Object.entries(ADDABLE).map(([word, category]) => [category, word]));

/** The kebab-case spelling of a category: `app-shell` for `appShell`. */
const kebab = (name: string): string =>
  name.replace(/[A-Z]/g, (letter) => `-${letter.toLowerCase()}`);

/** Used when the output is not a terminal. */
const DEFAULT_COLUMNS = 100;
/** Below this width the third column cannot hold a description: it goes under the row. */
const MIN_TEXT_WIDTH = 40;
const INDENT = 2;
const GAP = 2;

interface Row {
  id: string;
  /** `sa add ...` when a project can add the option, then `sa new --...`; none when it is planned. */
  commands: string[];
  name: string;
  description: string;
  docs?: string;
}

function rowsOf(name: CapabilityCategory): Row[] {
  const word = ADD_WORD.get(name);
  return CAPABILITIES[name].map((option) => {
    const badge = option.available ? (option.recommended ? ' (Recommended)' : '') : ' (planned)';
    const commands = option.available
      ? [
          ...(word && addableValues(word).includes(option.id)
            ? [`sa add ${word} ${option.id}`]
            : []),
          `sa new ${NEW_FLAGS[name]} ${option.id}`,
        ]
      : [];
    return {
      id: option.id,
      commands,
      name: `${option.label}${badge}`,
      description: option.description,
      ...(option.docs ? { docs: option.docs } : {}),
    };
  });
}

/**
 * Prints the options as one table: id, commands, and the name with its description and link. Every
 * category shares the widths of the first two columns, so nothing starts further right than a row of
 * another category.
 */
export function listCommand(io: CliIo, category?: string): void {
  const style = createStyler(io.color);
  const selected = selectCategories(category);
  const tables = selected.map((name) => ({ name, rows: rowsOf(name) }));
  // The widths come from every category, so `sa list style` and `sa list` draw the same columns.
  const rows = CATEGORIES.flatMap(rowsOf);
  const idWidth = Math.max('ID'.length, ...rows.map((row) => row.id.length));
  const commandWidth = Math.max(
    'Commands'.length,
    ...rows.flatMap((row) => row.commands.map((command) => command.length)),
  );
  const commandColumn = INDENT + idWidth + GAP;
  const textColumn = commandColumn + commandWidth + GAP;
  const width = io.columns ?? DEFAULT_COLUMNS;
  // The name never wraps, so the third column must hold the longest one.
  const narrow =
    width - textColumn < Math.max(MIN_TEXT_WIDTH, ...rows.map((row) => row.name.length));

  const cells = (id: string, command: string, text: string): string =>
    `${' '.repeat(INDENT)}${id.padEnd(idWidth)}${' '.repeat(GAP)}${command.padEnd(commandWidth)}${' '.repeat(GAP)}${text}`.trimEnd();
  const line = (id: string, command: string, text: string, paint = (value: string) => value) =>
    println(io.stdout, cells(id, command, paint(text)));
  // The headers are blue, like the headings of `ng --help`.
  const header = () =>
    println(
      io.stdout,
      `${' '.repeat(INDENT)}${style.cyan('ID'.padEnd(idWidth))}${' '.repeat(GAP)}${style.cyan('Commands'.padEnd(commandWidth))}${' '.repeat(GAP)}${narrow ? '' : style.cyan('Option')}`.trimEnd(),
    );

  tables.forEach(({ name, rows: tableRows }, index) => {
    if (index > 0) println(io.stdout);
    println(io.stdout, style.bold(`${TITLES[name]} (${name})`));
    header();
    for (const row of tableRows) {
      const details = (at: number): string[] => [
        ...wrapText(row.description, width - at),
        ...(row.docs ? [row.docs] : []),
      ];
      const third = narrow ? [] : [row.name, ...details(textColumn)];
      for (let at = 0; at < Math.max(row.commands.length, third.length, 1); at++) {
        line(
          at === 0 ? row.id : '',
          row.commands[at] ?? '',
          third[at] ?? '',
          at === 0 ? undefined : style.dim,
        );
      }
      // A narrow terminal has no third column: the name and the description go under the row.
      if (narrow) {
        println(io.stdout, `${' '.repeat(commandColumn)}${row.name}`);
        for (const extra of details(commandColumn)) {
          println(io.stdout, style.dim(`${' '.repeat(commandColumn)}${extra}`));
        }
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
