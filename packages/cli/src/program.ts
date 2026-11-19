import { Command, Help } from 'commander';
import { availableIds, type CapabilityCategory } from './config/capabilities.js';
import { doctorCommand } from './commands/doctor.js';
import { infoCommand } from './commands/info.js';
import { listCommand } from './commands/list.js';
import { newCommand, type NewFlags } from './commands/new.js';
import type { ProgramDeps } from './deps.js';
import { RuntimeError } from './errors.js';
import { println, type CliIo } from './io.js';
import { formatRows } from './ui/format.js';
import { CLI_VERSION } from './version.js';

interface UnavailableCommand {
  name: string;
  alias?: string;
  description: string;
}

const UNAVAILABLE_COMMANDS: readonly UnavailableCommand[] = [
  { name: 'generate', alias: 'g', description: 'Generate project files' },
  { name: 'add', description: 'Add supported capabilities' },
  { name: 'config', description: 'Manage project configuration' },
];

const UNAVAILABLE_AFTER_LIST: readonly UnavailableCommand[] = [
  { name: 'update', description: 'Update supported starter capabilities' },
];

export function createProgram(io: CliIo, deps: ProgramDeps): Command {
  const program = new Command();
  program
    .name('as')
    .description('Angular Starter CLI')
    .usage('[command] [options]')
    .version(CLI_VERSION, '-v, --version', 'Display version')
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
  registerUnavailable(program, UNAVAILABLE_COMMANDS);

  program
    .command('list')
    .description('List available options')
    .argument(
      '[category]',
      'architecture, routing, style, rendering, components, icons or packageManager',
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
    .command('doctor')
    .description('Diagnose your environment')
    .action(async () => {
      await doctorCommand(io, deps);
    });

  registerUnavailable(program, UNAVAILABLE_AFTER_LIST);

  program
    .command('version')
    .description('Display CLI version')
    .action(() => {
      println(io.stdout, CLI_VERSION);
    });

  return program;
}

/** Values listed in the help are only the ones that can be generated today. */
function valuesOf(category: CapabilityCategory): string {
  return availableIds(category).join(', ');
}

function registerNewCommand(program: Command, io: CliIo, deps: ProgramDeps): void {
  program
    .command('new')
    .description('Create a new Angular application')
    .argument('[name]', 'Name of the project, also the folder that is created')
    .option('--architecture <id>', `Project architecture (${valuesOf('architecture')})`)
    .option('--routing <id>', `Routing system (${valuesOf('routing')})`)
    .option('--style <format>', `Stylesheet format (${valuesOf('style')})`)
    .option('--tailwind', 'Integrate Tailwind CSS (requires the css format)')
    .option('--no-tailwind', 'Do not integrate Tailwind CSS')
    .option('--rendering <strategy>', `Rendering strategy (${valuesOf('rendering')})`)
    .option('--components <set>', `Native UI components (${valuesOf('components')})`)
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
    .action(async (name: string | undefined, flags: NewFlags) => {
      await newCommand(io, deps, name, flags);
    });
}

function registerUnavailable(program: Command, commands: readonly UnavailableCommand[]): void {
  for (const { name, alias, description } of commands) {
    const command = program
      .command(name)
      .description(`${description} (not available yet)`)
      .allowUnknownOption()
      .allowExcessArguments()
      .argument('[args...]')
      .action(() => {
        throw new RuntimeError(
          `"as ${name}" is not available yet. It is planned for a future release.`,
        );
      });
    if (alias) command.alias(alias);
  }
}

function formatRootHelp(program: Command, helper: Help): string {
  const commands = helper
    .visibleCommands(program)
    .map((command) => [command.name(), helper.subcommandDescription(command)] as const);
  const options = helper
    .visibleOptions(program)
    .map((option) => [helper.optionTerm(option), helper.optionDescription(option)] as const);

  return [
    'Angular Starter CLI',
    '',
    'Usage: as [command] [options]',
    '',
    'Commands:',
    ...formatRows(commands),
    '',
    'Options:',
    ...formatRows(options),
    '',
    'Run "as <command> --help" for details on a command.',
    '',
  ].join('\n');
}
