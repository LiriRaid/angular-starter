import { Command, Help } from 'commander';
import { availableIds, type CapabilityCategory } from './config/capabilities.js';
import { ADDABLE, addableValues } from './commands/addable.js';
import type { AddFlags } from './commands/add.js';
import { configCommand } from './commands/config.js';
import { doctorCommand } from './commands/doctor.js';
import { GENERATE_KINDS } from './commands/generate-kinds.js';
import type { GenerateFlags } from './commands/generate.js';
import { infoCommand } from './commands/info.js';
import { listCommand } from './commands/list.js';
import type { NewFlags } from './commands/new.js';
import type { ProgramDeps } from './deps.js';
import { RuntimeError } from './errors.js';
import { println, type CliIo } from './io.js';
import { formatRows } from './ui/format.js';
import { VERSION_TEXT } from './version.js';

/** The commands of the root help, in order, with the usage each one is listed with. */
const ROOT_COMMANDS: readonly (readonly [name: string, term: string])[] = [
  ['new', 'new [name]'],
  ['init', 'init'],
  ['add', 'add <capability> [value]'],
  ['generate', 'generate, g <kind> <name>'],
  ['list', 'list [category]'],
  ['info', 'info'],
  ['config', 'config <list|get> [key]'],
  ['doctor', 'doctor'],
  ['update', 'update'],
  ['version', 'version'],
  ['help', 'help [command]'],
];

const ONLY_NEW =
  'Only `as new` decides: stylesheet format, Tailwind CSS, the purpose of the Starter SSR, the layout of the shell, package manager and selector prefix.';

export function createProgram(io: CliIo, deps: ProgramDeps): Command {
  const program = new Command();
  program
    .name('as')
    .description('Angular Starter CLI')
    .usage('[command] [options]')
    .version(VERSION_TEXT, '-v, --version', 'Display versions')
    .helpOption('-h, --help', 'Display help')
    .helpCommand('help [command]', 'Display command help')
    .configureOutput({ writeOut: io.stdout, writeErr: io.stderr })
    .configureHelp({
      formatHelp: (command, helper) =>
        command.parent
          ? Help.prototype.formatHelp.call(helper, command, helper)
          : formatRootHelp(command, helper),
    })
    .exitOverride();

  registerNewCommand(program, io, deps);
  program
    .command('init')
    .description('Prepare an Angular project you already have')
    .option('--force', 'Read the project again and replace its angular-starter.config.json')
    .option('--dry-run', 'Show what it found without writing anything')
    .addHelpText(
      'after',
      examples([
        ['as init', 'Record what the project already has'],
        ['as init --dry-run', 'Only show it'],
      ]),
    )
    .action(async (flags: { force?: boolean; dryRun?: boolean }) => {
      const { initCommand } = await import('./commands/init.js');
      await initCommand(io, flags);
    });

  registerAddCommand(program, io, deps);
  registerGenerateCommand(program, io);

  program
    .command('list')
    .description('List the options, with their commands and docs')
    .argument(
      '[category]',
      'architecture, routing, style, rendering, ssrPurpose, appShell, layout, presence, components, uiSystem, icons or packageManager',
    )
    .addHelpText(
      'after',
      examples([
        ['as list', 'Every category'],
        ['as list rendering', 'Only the rendering strategies'],
      ]),
    )
    .action((category: string | undefined) => {
      listCommand(io, category);
    });

  program
    .command('info')
    .description('Display CLI and project information')
    .action(async () => {
      await infoCommand(io, deps);
    });

  program
    .command('config')
    .description('Read the options recorded in the project')
    .usage('<list|get> [key]')
    .argument('[action]', 'list: every option · get <key>: one option')
    .argument('[key]', 'Option to read')
    // "as config set ..." gets its own explanation instead of a generic usage error.
    .allowExcessArguments()
    .addHelpText(
      'after',
      `\nThe project configuration (angular-starter.config.json) is read-only: ${ONLY_NEW}\n` +
        examples([
          ['as config list', 'Every option of the project'],
          ['as config get architecture', 'One value, ready for a script'],
        ]),
    )
    .action(async (action: string | undefined, key: string | undefined) => {
      await configCommand(io, action, key);
    });

  program
    .command('doctor')
    .description('Diagnose your environment')
    .action(async () => {
      await doctorCommand(io, deps);
    });

  program
    .command('update')
    .description('Update a project (not available yet)')
    .allowUnknownOption()
    .allowExcessArguments()
    .argument('[args...]')
    .action(() => {
      throw new RuntimeError(
        '"as update" is not available yet. It is planned for a future release.',
      );
    });

  program
    .command('version')
    .description('Display the CLI and Angular CLI versions')
    .action(() => {
      println(io.stdout, VERSION_TEXT);
    });

  return program;
}

/** Values listed in the help are only the ones that can be generated today. */
function valuesOf(category: CapabilityCategory): string {
  return availableIds(category).join(', ');
}

function examples(rows: readonly (readonly [string, string])[]): string {
  const lines = formatRows(rows.map(([command, note]) => [command, note] as const));
  return `\nExamples:\n${lines.join('\n')}\n`;
}

function registerNewCommand(program: Command, io: CliIo, deps: ProgramDeps): void {
  program
    .command('new')
    .description('Create a new Angular application')
    .argument('[name]', 'Name of the project, also the folder that is created')
    .option('--architecture <id>', `Project architecture (${valuesOf('architecture')})`)
    .option('--routing <id>', `Routing system (${valuesOf('routing')})`)
    .option('--style <format>', `Stylesheet format (${valuesOf('style')})`)
    .option('--tailwind', 'Integrate Tailwind CSS (same as --style tailwind)')
    .option('--no-tailwind', 'Do not integrate Tailwind CSS')
    .option('--rendering <strategy>', `Rendering strategy (${valuesOf('rendering')})`)
    .option('--ssr-purpose <id>', `What the Starter SSR is for (${valuesOf('ssrPurpose')})`)
    .option('--app-shell <id>', `Application shell (${valuesOf('appShell')})`)
    .option('--layout <id>', `Layout of the app shell (${valuesOf('layout')})`)
    .option('--presence <id>', `Real-time presence (${valuesOf('presence')})`)
    .option(
      '--components <set>',
      `Native UI components (${valuesOf('components')}); or ids, like button,modal`,
    )
    .option('--ui-system <id>', `UI System of the design preferences (${valuesOf('uiSystem')})`)
    .option('--icons <library>', `Icon library (${valuesOf('icons')})`)
    .option('--package-manager <name>', `Package manager (${valuesOf('packageManager')})`)
    .option('--prefix <prefix>', 'Selector prefix of your application components (default: app)')
    .option('--git', 'Initialize a Git repository (default)')
    .option('--no-git', 'Do not initialize a Git repository')
    .option('--install', 'Install dependencies (default)')
    .option('--no-install', 'Do not install dependencies')
    .option('--defaults', 'Never prompt: use the default for every option that was not provided')
    .option('--config <file>', 'Read options from a JSON file (flags override it)')
    .option('--dry-run', 'Show what would be done without creating anything')
    .option('--verbose', 'Show the output of the commands that are run')
    .addHelpText(
      'after',
      '\nOnly Tailwind CSS, Client-Side Rendering and Lucide Icons are marked (Recommended) and preselected.\n' +
        'The defaults also use the Screaming Architecture, Angular Starter Routing, the Angular Starter App Shell and the essential components.\n' +
        'In the wizard, press Esc to go back to the previous question; the last one can change any answer.\n' +
        'Run "as list" to see what each option is and where its documentation lives.\n' +
        examples([
          ['as new InventorySystem', 'Ask for each option'],
          ['as new Shop --defaults', 'The default set, no questions'],
          ['as new Shop --style scss --rendering ssr', 'Pick some options, be asked the rest'],
          [
            'as new Shop --defaults --architecture angular-default --routing angular',
            "Angular's own structure",
          ],
          [
            'as new Shop --config starter.json --dry-run',
            'Read options from a file, show the plan',
          ],
        ]),
    )
    .action(async (name: string | undefined, flags: NewFlags) => {
      // The commands that change files load the engine and ts-morph only when they run.
      const { newCommand } = await import('./commands/new.js');
      await newCommand(io, deps, name, flags);
    });
}

function registerAddCommand(program: Command, io: CliIo, deps: ProgramDeps): void {
  const capabilities: readonly (readonly [string, string])[] = [
    ['icons', 'Icon library'],
    [
      'components',
      'Native as- components, tokens and theme; a collection or ids like button,modal',
    ],
    ['routing', 'Angular Starter Routing (needs the Screaming Architecture)'],
    [
      'app-shell',
      'Angular Starter App Shell: sidebar, header and breadcrumb (needs the starter routing)',
    ],
    [
      'presence',
      'Real-time user status in the shell, with a transport contract and a Redis guide (needs the app shell)',
    ],
    [
      'ui-system',
      'Catalog of the components with live previews in the design preferences (needs the shell and the components)',
    ],
    ['rendering', 'Server-side rendering'],
    [
      'architecture',
      'The Screaming Architecture (core, features, shared), only on a project that is still what ng new generates',
    ],
  ];
  program
    .command('add')
    .description('Add a capability to an existing project')
    .usage('<capability> [value]')
    .argument('[capability]', Object.keys(ADDABLE).join(', '))
    .argument('[value]', 'What to add; optional when the capability has one option')
    .option('--no-install', 'Do not install dependencies')
    .option('--dry-run', 'Show what would be done without changing anything')
    .option('--verbose', 'Show the output of the commands that are run')
    .addHelpText('after', () => {
      const rows = capabilities.map(([name, text]) => {
        const values = addableValues(name);
        return [name, `${text}${values.length > 0 ? ` (${values.join(', ')})` : ''}`] as const;
      });
      return (
        `\nCapabilities:\n${formatRows(rows).join('\n')}\n\n${ONLY_NEW}\n` +
        examples([
          ['as add icons lucide', 'Install Lucide Icons'],
          ['as add routing starter', 'Navigation tree, titles and breadcrumbs'],
          ['as add app-shell', 'Floating sidebar, header and example pages'],
          ['as add presence', 'User status in the shell, in memory or over a WebSocket'],
          ['as add ui-system', 'Components catalog in the UI tab of the design preferences'],
          ['as add rendering starter-ssr', 'Angular SSR with incremental hydration'],
          ['as add components all --dry-run', 'See the steps without changing anything'],
        ])
      );
    })
    .action(async (capability: string | undefined, value: string | undefined, flags: AddFlags) => {
      const { addCommand } = await import('./commands/add.js');
      await addCommand(io, deps, capability, value, flags);
    });
}

function registerGenerateCommand(program: Command, io: CliIo): void {
  const kinds: readonly (readonly [string, string])[] = [
    [
      'feature',
      'features/<name> with its component, lazy routes and spec; adds the route and the menu entry',
    ],
    [
      'component',
      'A standalone component inside a feature (--feature) or in shared/components (--shared)',
    ],
  ];
  program
    .command('generate')
    .alias('g')
    .description('Generate project files that follow the architecture')
    .usage('<kind> <name> [options]')
    .argument('[kind]', GENERATE_KINDS.join(', '))
    .argument('[name]', 'Name in lowercase with hyphens, for example user-profiles')
    .option('--feature <name>', 'Feature that receives the component')
    .option('--shared', 'Create the component in shared/components')
    .option(
      '--path <folder>',
      'Folder below src/app for the component (projects that are not Screaming)',
    )
    .option('--dry-run', 'Show what would be created without writing anything')
    .addHelpText(
      'after',
      `\nKinds:\n${formatRows(kinds).join('\n')}\n\nIt uses your selector prefix. Features and the --feature and --shared places need the Screaming Architecture; in any other project a component goes below src/app, or below --path.\n` +
        examples([
          ['as generate feature billing', 'Create features/billing (Screaming)'],
          ['as generate component invoice-card', 'Create src/app/invoice-card (any other project)'],
          ['as generate component invoice-card --path billing/ui', 'Below src/app/billing/ui'],
          ['as generate component invoice-card --feature billing', 'Inside the feature'],
          [
            'as generate component invoice-card --shared',
            'Reusable, exported by @shared/components',
          ],
        ]),
    )
    .action(async (kind: string | undefined, name: string | undefined, flags: GenerateFlags) => {
      const { generateCommand } = await import('./commands/generate.js');
      await generateCommand(io, kind, name, flags);
    });
}

/** Only the commands and the options, like `ng --help`; the examples live in the help of each command. */
function formatRootHelp(program: Command, helper: Help): string {
  const descriptions = new Map(
    helper
      .visibleCommands(program)
      .map((command) => [command.name(), helper.subcommandDescription(command)] as const),
  );
  const options = helper
    .visibleOptions(program)
    .map((option) => [helper.optionTerm(option), helper.optionDescription(option)] as const);

  return [
    'Angular Starter CLI',
    '',
    'Usage: as [command] [options]',
    '',
    'Commands:',
    ...formatRows(ROOT_COMMANDS.map(([name, term]) => [term, descriptions.get(name) ?? ''])),
    '',
    'Options:',
    ...formatRows(options),
    '',
  ].join('\n');
}
