import { Command, Help } from 'commander';
import { availableIds, type CapabilityCategory } from './config/capabilities.js';
import { ADDABLE_WORDS, addableValues } from './commands/addable.js';
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
import { createStyler, formatRows, type Styler } from './ui/format.js';
import { VERSION_TEXT } from './version.js';

/** The commands of the root help, in order, with the usage each one is listed with. */
const ROOT_COMMANDS: readonly (readonly [name: string, term: string])[] = [
  ['new', 'sa new [name]'],
  ['init', 'sa init'],
  ['add', 'sa add <capability> [value]'],
  ['generate', 'sa generate, g <kind> <name>'],
  ['test', 'sa test [args...]'],
  ['lint', 'sa lint [--fix] [args...]'],
  ['format', 'sa format [--check] [args...]'],
  ['list', 'sa list [category]'],
  ['info', 'sa info'],
  ['config', 'sa config <list|get> [key]'],
  ['doctor', 'sa doctor'],
  ['update', 'sa update'],
  ['version', 'sa version'],
  ['help', 'sa help [command]'],
];

/** What `sa list <category>` shows, in the order of the wizard; it is how a person learns the ids. */
const LISTS: readonly (readonly [category: string, text: string])[] = [
  ['architecture', 'Lists the architectures a project can follow.'],
  ['routing', 'Lists the routing systems a project can use.'],
  ['style', 'Lists the stylesheet formats a project can use.'],
  ['rendering', 'Lists how a project renders: in the browser or on the server.'],
  ['ssr-purpose', 'Lists what the Starter SSR can be built for.'],
  ['app-shell', 'Lists the application shells with sidebar, header and breadcrumb.'],
  ['layout', 'Lists the layout modes of the application shell.'],
  ['presence', 'Lists the presence options for the application shell.'],
  ['components', 'Lists every native sa- component and the collections that group them.'],
  ['ui-system', 'Lists the UI Systems that catalog the components.'],
  ['icons', 'Lists the icon libraries a project can use.'],
  ['package-manager', 'Lists the package managers a project can install with.'],
];

/** Where the help sends to read more, until the project has a site of its own. */
const HOMEPAGE = 'https://github.com/LiriRaid/starter-angular';

const ONLY_NEW =
  'Only `sa new` decides: stylesheet format, Tailwind CSS, the purpose of the Starter SSR, the layout of the shell, package manager and selector prefix.';

export function createProgram(io: CliIo, deps: ProgramDeps): Command {
  const program = new Command();
  program
    .name('sa')
    .description('Starter Angular CLI')
    .usage('[command] [options]')
    .version(VERSION_TEXT, '-v, --version', 'Shows the CLI and Angular CLI versions.')
    .helpOption('-h, --help', 'Shows a help message for this command in the console.')
    .helpCommand('help [command]', 'Shows the help of one command, or the list of commands.')
    .configureOutput({
      writeOut: io.stdout,
      writeErr: io.stderr,
      getOutHasColors: () => io.color,
      getErrHasColors: () => io.color,
    })
    .configureHelp({
      formatHelp: (command, helper) =>
        command.parent
          ? Help.prototype.formatHelp.call(helper, command, helper)
          : formatRootHelp(command, helper, createStyler(io.color)),
    })
    .exitOverride();

  registerNewCommand(program, io, deps);
  program
    .command('init')
    .description('Prepares an Angular project you already have so the other commands work on it.')
    .option('--force', 'Read the project again and replace its starter-angular.config.json')
    .option('--dry-run', 'Show what it found without writing anything')
    .addHelpText(
      'after',
      examples([
        ['sa init', 'Record what the project already has'],
        ['sa init --dry-run', 'Only show it'],
      ]),
    )
    .action(async (flags: { force?: boolean; dryRun?: boolean }) => {
      const { initCommand } = await import('./commands/init.js');
      await initCommand(io, flags);
    });

  registerAddCommand(program, io, deps);
  registerGenerateCommand(program, io);

  program
    .command('test')
    .description('Runs the tests of the project: ng test, through its package manager.')
    .usage('[args...]')
    .argument('[args...]', 'Arguments and options that go to ng test as they are')
    .allowUnknownOption()
    .allowExcessArguments()
    .addHelpText(
      'after',
      examples([
        ['sa test', 'Run the tests as ng test does'],
        ['sa test --watch=false', 'Run once and exit, for a script or a pipeline'],
        ['sa test --include "src/app/**/*.spec.ts"', 'Only the specs that match'],
      ]),
    )
    .action(async (args: string[]) => {
      const { testCommand } = await import('./commands/test.js');
      await testCommand(io, deps, args);
    });

  program
    .command('lint')
    .description('Lints the project with ESLint: its lint script, through its package manager.')
    .usage('[--fix] [args...]')
    .argument(
      '[args...]',
      'Options that go to the script as they are (not a file: the script already has its glob); --fix runs lint:fix',
    )
    .allowUnknownOption()
    .allowExcessArguments()
    .addHelpText(
      'after',
      examples([
        ['sa lint', 'Check the code with ESLint'],
        ['sa lint --fix', 'Fix what ESLint can fix (the lint:fix script)'],
      ]),
    )
    .action(async (args: string[]) => {
      const { lintCommand } = await import('./commands/scripts.js');
      await lintCommand(io, deps, args);
    });

  program
    .command('format')
    .description(
      'Formats the project with Prettier: its format script, through its package manager.',
    )
    .usage('[--check] [args...]')
    .argument(
      '[args...]',
      'Options that go to the script as they are (not a file: the script already has its glob); --check runs format:check',
    )
    .allowUnknownOption()
    .allowExcessArguments()
    .addHelpText(
      'after',
      examples([
        ['sa format', 'Format the code with Prettier'],
        ['sa format --check', 'Only check it, for a pipeline (the format:check script)'],
      ]),
    )
    .action(async (args: string[]) => {
      const { formatCommand } = await import('./commands/scripts.js');
      await formatCommand(io, deps, args);
    });

  program
    .command('list')
    .description(
      'Lists every option with the commands that add it, what it is and its documentation.',
    )
    .argument(
      '[category]',
      'architecture, routing, style, rendering, ssrPurpose, appShell, layout, presence, components, uiSystem, icons or packageManager',
    )
    .addHelpText(
      'after',
      examples([
        ['sa list', 'Every category'],
        ['sa list rendering', 'Only the rendering strategies'],
      ]),
    )
    .action((category: string | undefined) => {
      listCommand(io, category);
    });

  program
    .command('info')
    .description('Outputs the CLI, Angular CLI and Node versions and the options of the project.')
    .action(async () => {
      await infoCommand(io, deps);
    });

  program
    .command('config')
    .description('Reads the options recorded in the project configuration file.')
    .usage('<list|get> [key]')
    .argument('[action]', 'list: every option · get <key>: one option')
    .argument('[key]', 'Option to read')
    // "sa config set ..." gets its own explanation instead of a generic usage error.
    .allowExcessArguments()
    .addHelpText(
      'after',
      `\nThe project configuration (starter-angular.config.json) is read-only: ${ONLY_NEW}\n` +
        examples([
          ['sa config list', 'Every option of the project'],
          ['sa config get architecture', 'One value, ready for a script'],
        ]),
    )
    .action(async (action: string | undefined, key: string | undefined) => {
      await configCommand(io, action, key);
    });

  program
    .command('doctor')
    .description('Diagnoses your environment and says what is missing to run the commands.')
    .action(async () => {
      await doctorCommand(io, deps);
    });

  program
    .command('update')
    .description('Updates the capabilities of a project to a newer version (not available yet).')
    .allowUnknownOption()
    .allowExcessArguments()
    .argument('[args...]')
    .action(() => {
      throw new RuntimeError(
        '"sa update" is not available yet. It is planned for a future release.',
      );
    });

  program
    .command('version')
    .description('Outputs the version of the CLI and of the Angular CLI that `sa new` runs.')
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
    .description('Creates a new Angular application, with the options you pick or the defaults.')
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
        'The defaults also use the Screaming Architecture, Starter Angular Routing, the Starter Angular App Shell and the essential components.\n' +
        'In the wizard, press Esc to go back to the previous question; the last one can change any answer.\n' +
        'Run "sa list" to see what each option is and where its documentation lives.\n' +
        examples([
          ['sa new InventorySystem', 'Ask for each option'],
          ['sa new Shop --defaults', 'The default set, no questions'],
          ['sa new Shop --style scss --rendering ssr', 'Pick some options, be asked the rest'],
          [
            'sa new Shop --defaults --architecture angular-default --routing angular',
            "Angular's own structure",
          ],
          [
            'sa new Shop --config starter.json --dry-run',
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
      'Native sa- components, tokens and theme; a collection or ids like button,modal',
    ],
    ['routing', 'Starter Angular Routing (needs the Screaming Architecture)'],
    [
      'app-shell',
      'Starter Angular App Shell: sidebar, header and breadcrumb (needs the starter routing)',
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
      'tooling',
      'ESLint with Angular rules and the lint and format scripts, for a project that does not have them',
    ],
    [
      'architecture',
      'The Screaming Architecture (core, features, shared), only on a project that is still what ng new generates',
    ],
  ];
  program
    .command('add')
    .description(
      'Adds a capability, such as components, routing, an app shell or icons, to a project.',
    )
    .usage('<capability> [value]')
    .argument('[capability]', ADDABLE_WORDS.join(', '))
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
        'Without a value, in a terminal, "sa add components" opens a checklist and "sa add rendering" a selector.\n' +
        'Run "sa list <category>" to see every value, for example "sa list components" for the ids of the components.\n' +
        examples([
          ['sa add icons lucide', 'Install Lucide Icons'],
          ['sa add routing starter', 'Navigation tree, titles and breadcrumbs'],
          ['sa add app-shell', 'Floating sidebar, header and example pages'],
          ['sa add presence', 'User status in the shell, in memory or over a WebSocket'],
          ['sa add ui-system', 'Components catalog in the UI tab of the design preferences'],
          ['sa add rendering starter-ssr', 'Angular SSR with incremental hydration'],
          ['sa add tooling', 'ESLint with Angular rules and the lint and format scripts'],
          ['sa add components all --dry-run', 'See the steps without changing anything'],
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
    .description('Generates a feature or a component that follows the architecture of the project.')
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
        'The name is the one you give to your own component. The ready-made sa- components come with "sa add components"; see "sa list components".\n' +
        examples([
          ['sa generate feature billing', 'Create features/billing (Screaming)'],
          ['sa generate component invoice-card', 'Create src/app/invoice-card (any other project)'],
          ['sa generate component invoice-card --path billing/ui', 'Below src/app/billing/ui'],
          ['sa generate component invoice-card --feature billing', 'Inside the feature'],
          [
            'sa generate component invoice-card --shared',
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
function formatRootHelp(program: Command, helper: Help, style: Styler): string {
  const descriptions = new Map(
    helper
      .visibleCommands(program)
      .map((command) => [command.name(), helper.subcommandDescription(command)] as const),
  );
  const options = helper
    .visibleOptions(program)
    .map((option) => [helper.optionTerm(option), helper.optionDescription(option)] as const);

  return [
    'Starter Angular CLI',
    '',
    'Usage: sa [command] [options]',
    '',
    style.cyan('Commands:'),
    ...formatRows(ROOT_COMMANDS.map(([name, term]) => [term, descriptions.get(name) ?? ''])),
    '',
    style.cyan('Lists:'),
    ...formatRows(LISTS.map(([category, text]) => [`sa list ${category}`, text])),
    '',
    style.cyan('Options:'),
    ...formatRows(options),
    '',
    `For more information, see ${HOMEPAGE}.`,
  ].join('\n');
}
