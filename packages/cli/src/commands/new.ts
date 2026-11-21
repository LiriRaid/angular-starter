import { join } from 'node:path';
import { ANGULAR_CLI_VERSION, ICON_PACKAGES } from '../compat.js';
import { CAPABILITIES, type CapabilityCategory } from '../config/capabilities.js';
import { readConfigFile } from '../config/file.js';
import { COMPONENTS as COMPONENT_CHOICES } from '../config/schema.js';
import { componentIdsOf } from '../config/components.js';
import { normalizeStyleChoice, resolveOptions } from '../config/resolve.js';
import type { StarterOptions } from '../config/schema.js';
import type { ProgramDeps } from '../deps.js';
import { buildNgCommand } from '../engine/angular-cli.js';
import { ARCHITECTURE_PROFILES } from '../engine/architectures/index.js';
import { RENDERING_PROFILES } from '../engine/rendering/index.js';
import { ROUTING_PROFILES } from '../engine/routing/index.js';
import { runPipeline, type GenerationContext } from '../engine/pipeline.js';
import { NEW_PROJECT_STAGES, validateEnvironment } from '../engine/stages.js';
import { CancelledError, CliError, UsageError } from '../errors.js';
import { println, type CliIo } from '../io.js';
import { formatRows, createStyler } from '../ui/format.js';
import { validateProjectName } from '../validation/project-name.js';
import { runWizard } from '../wizard/wizard.js';

/** Options as parsed by commander. String values are validated later, against the schema. */
export interface NewFlags {
  architecture?: string;
  routing?: string;
  style?: string;
  tailwind?: boolean;
  rendering?: string;
  ssrPurpose?: string;
  appShell?: string;
  layout?: string;
  presence?: string;
  components?: string;
  uiSystem?: string;
  icons?: string;
  packageManager?: string;
  prefix?: string;
  git?: boolean;
  install?: boolean;
  defaults?: boolean;
  config?: string;
  dryRun?: boolean;
  verbose?: boolean;
}

export async function newCommand(
  io: CliIo,
  deps: ProgramDeps,
  nameArgument: string | undefined,
  flags: NewFlags,
): Promise<void> {
  const style = createStyler(io.color);
  println(io.stdout, style.bold('Angular Starter CLI'));
  println(io.stdout, 'Create your next Angular application.');
  println(io.stdout);

  const file = flags.config === undefined ? undefined : await readConfigFile(flags.config, io.cwd);
  const interactive = io.interactive && !flags.defaults && flags.config === undefined;
  const flagOptions = optionsFromFlags(flags);

  const name = await resolveName(nameArgument, interactive, deps);

  // Validate what was already given before asking anything else.
  resolveOptions({ file, flags: flagOptions });
  const answers = interactive
    ? await runWizard({ ...file, ...flagOptions }, deps.prompter, io.env)
    : {};
  const options = resolveOptions({ file, flags: { ...flagOptions, ...answers } });

  printSummary(io, name, options);

  if (interactive) {
    const confirmed = await deps.prompter.confirm({
      name: 'confirm',
      message: 'Create project with this configuration?',
      default: true,
    });
    if (!confirmed) throw new CancelledError();
  }

  const context: GenerationContext = {
    name,
    options,
    cwd: io.cwd,
    targetDir: join(io.cwd, name),
    io,
    deps,
    verbose: flags.verbose ?? false,
    warnings: [],
    created: false,
  };

  if (flags.dryRun) {
    await runDryRun(context);
    return;
  }

  println(io.stdout);
  try {
    await runPipeline(NEW_PROJECT_STAGES, context);
  } catch (error) {
    if (context.created && error instanceof CliError && !error.hint) {
      throw new CliError(
        error.message,
        error.exitCode,
        `A partial project was left in "${context.targetDir}". Delete it before trying again.`,
      );
    }
    throw error;
  }
  printSuccess(context);
}

async function resolveName(
  argument: string | undefined,
  interactive: boolean,
  deps: ProgramDeps,
): Promise<string> {
  let name = argument?.trim();
  if (name === undefined || name === '') {
    if (!interactive) {
      throw new UsageError('Project name is required.', 'Usage: as new <name> [options]');
    }
    name = await deps.prompter.input({
      name: 'projectName',
      message: 'Project name:',
      validate: validateProjectName,
    });
  }
  const problem = validateProjectName(name);
  if (problem) throw new UsageError(`Invalid project name "${name}": ${problem}`);
  return name;
}

const OPTION_FLAGS = [
  'architecture',
  'routing',
  'style',
  'tailwind',
  'rendering',
  'ssrPurpose',
  'appShell',
  'layout',
  'presence',
  'components',
  'uiSystem',
  'icons',
  'packageManager',
  'prefix',
  'git',
  'install',
] as const;

/** Only the flags that describe the project; control flags such as --dry-run stay out. */
function optionsFromFlags(flags: NewFlags): Partial<StarterOptions> {
  const { style, tailwind } = normalizeStyleChoice(flags.style, flags.tailwind);
  const normalized: NewFlags = { ...flags, style, tailwind };
  const options = Object.fromEntries(
    OPTION_FLAGS.filter((key) => normalized[key] !== undefined).map((key) => [
      key,
      normalized[key],
    ]),
  ) as Partial<StarterOptions>;
  return { ...options, ...componentsFromFlag(flags.components) };
}

/** `--components` is a collection (or `custom`), or the ids of the components to generate (ADR-0011). */
function componentsFromFlag(value: string | undefined): Partial<StarterOptions> {
  if (value === undefined || (COMPONENT_CHOICES as readonly string[]).includes(value)) return {};
  return {
    components: 'custom',
    componentList: value
      .split(',')
      .map((id) => id.trim())
      .filter(Boolean),
  };
}

/** The collection's name, or "Custom selection (2: modal, toggle)". */
function componentsLabel(options: StarterOptions): string {
  const label = labelOf('components', options.components);
  if (options.components !== 'custom') return label;
  const ids = componentIdsOf(options);
  return `${label} (${ids.length}: ${ids.join(', ')})`;
}

function labelOf(category: CapabilityCategory, id: string): string {
  return CAPABILITIES[category].find((option) => option.id === id)?.label ?? id;
}

function printSummary(io: CliIo, name: string, options: StarterOptions): void {
  const toggle = (value: boolean): string => (value ? 'Enabled' : 'Disabled');
  println(io.stdout, createStyler(io.color).bold('Project configuration'));
  println(io.stdout);
  for (const line of formatRows([
    ['Project name', name],
    ['Angular CLI', ANGULAR_CLI_VERSION],
    ['Architecture', labelOf('architecture', options.architecture)],
    ['Routing', labelOf('routing', options.routing)],
    ['Stylesheet', labelOf('style', options.style)],
    ['Tailwind CSS', toggle(options.tailwind)],
    ['Rendering', labelOf('rendering', options.rendering)],
    ...(options.ssrPurpose === 'none'
      ? []
      : [['Starter SSR for', labelOf('ssrPurpose', options.ssrPurpose)] as const]),
    ['App shell', labelOf('appShell', options.appShell)],
    ['Layout', labelOf('layout', options.layout)],
    ['Presence', labelOf('presence', options.presence)],
    ['Components', componentsLabel(options)],
    ['UI System', labelOf('uiSystem', options.uiSystem)],
    ['Icons', labelOf('icons', options.icons)],
    ['Package manager', options.packageManager],
    ['Selector prefix', options.prefix],
    ['Git', toggle(options.git)],
    ['Install dependencies', options.install ? 'Yes' : 'No'],
  ])) {
    println(io.stdout, line);
  }
  println(io.stdout);
}

async function runDryRun(context: GenerationContext): Promise<void> {
  const { io, options, name } = context;
  const style = createStyler(io.color);
  await validateEnvironment.run(context);
  println(io.stdout, `${style.green('✓')} ${validateEnvironment.title}`);

  const ng = buildNgCommand(name, options);
  println(io.stdout);
  println(io.stdout, style.bold('Dry run: nothing was created. Planned steps:'));
  const steps = [
    `Create the Angular workspace: ${[ng.command, ...ng.args].join(' ')}`,
    ...(ARCHITECTURE_PROFILES[options.architecture]
      ? [`Apply the ${labelOf('architecture', options.architecture)} profile`]
      : []),
    ...(ROUTING_PROFILES[options.routing]
      ? [
          `Add the ${labelOf('routing', options.routing)} (navigation tree, page titles and breadcrumbs)`,
        ]
      : []),
    ...(RENDERING_PROFILES[options.rendering]
      ? [
          `Add incremental hydration, event replay and view transitions (${labelOf('rendering', options.rendering)})`,
        ]
      : []),
    ...(options.components === 'none' && options.appShell === 'none'
      ? []
      : ['Add the design base: tokens, theme, typography, animations, utilities and pipes']),
    ...(options.components === 'none'
      ? []
      : [`Add the ${componentsLabel(options)} (as- components)`]),
    ...(options.appShell === 'none'
      ? []
      : [
          `Add the ${labelOf('appShell', options.appShell)} (layout, sidebar, header, breadcrumb and example pages)`,
        ]),
    ...(options.presence === 'none'
      ? []
      : [
          `Add ${labelOf('presence', options.presence)} (core/presence, the status of the user menu and docs/presence.md)`,
        ]),
    ...(options.uiSystem === 'none'
      ? []
      : [
          `Add the ${labelOf('uiSystem', options.uiSystem)} (a catalog of the components with live previews in the UI tab of the design preferences)`,
        ]),
    ...(ICON_PACKAGES[options.icons]
      ? [
          `Add the ${labelOf('icons', options.icons)} package (${ICON_PACKAGES[options.icons]?.name})`,
        ]
      : []),
    'Write angular-starter.config.json',
    ...(options.install ? [`Install dependencies: ${options.packageManager} install`] : []),
    ...(options.git ? ['Initialize a Git repository with an initial commit'] : []),
  ];
  steps.forEach((step, index) => println(io.stdout, `  ${index + 1}. ${step}`));
}

function printSuccess(context: GenerationContext): void {
  const { io, options, name, warnings } = context;
  const style = createStyler(io.color);
  println(io.stdout);
  println(io.stdout, style.green('Project created successfully!'));
  for (const warning of warnings) println(io.stdout, `${style.yellow('!')} ${warning}`);
  println(io.stdout);
  println(io.stdout, `  cd ${name}`);
  if (!options.install) println(io.stdout, `  ${options.packageManager} install`);
  println(io.stdout, `  ${options.packageManager} start`);
  const icons = ICON_PACKAGES[options.icons];
  if (icons) {
    println(io.stdout);
    println(io.stdout, `${labelOf('icons', options.icons)}: ${icons.docs}`);
  }
}
