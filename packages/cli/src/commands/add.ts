import { join } from 'node:path';
import { CAPABILITIES, defaultOption, type CapabilityCategory } from '../config/capabilities.js';
import {
  ALL_COMPONENT_IDS,
  ESSENTIAL_COMPONENT_IDS,
  componentIdsOf,
  normalizeComponents,
} from '../config/components.js';
import { resolveOptions } from '../config/resolve.js';
import type { StarterOptions } from '../config/schema.js';
import type { ProgramDeps } from '../deps.js';
import { runPipeline, type GenerationContext, type Stage } from '../engine/pipeline.js';
import {
  addAngularSsr,
  addIconLibrary,
  applyAppShell,
  applyArchitectureToProject,
  applyComponents,
  applyDesign,
  applyPresence,
  applyRendering,
  applyRouting,
  applySharedFolders,
  applyUiSystem,
  installDependencies,
  writeStarterConfig,
} from '../engine/stages.js';
import { UsageError } from '../errors.js';
import { pathExists } from '../engine/fs.js';
import { println, type CliIo } from '../io.js';
import { describeComponent } from '../wizard/wizard.js';
import { findProject } from '../project/find.js';
import { ADDABLE, NOT_ADDABLE, addableValues } from './addable.js';
import { createStyler } from '../ui/format.js';

export { ADDABLE, addableValues };

export interface AddFlags {
  install?: boolean;
  dryRun?: boolean;
  verbose?: boolean;
}

export async function addCommand(
  io: CliIo,
  deps: ProgramDeps,
  capability: string | undefined,
  given: string | undefined,
  flags: AddFlags,
): Promise<void> {
  const category = capability === undefined ? undefined : ADDABLE[capability];
  if (capability === undefined || category === undefined) {
    throw new UsageError(
      capability === undefined
        ? 'Usage: sa add <capability> [value]'
        : `Unknown capability "${capability}".`,
      `Choose one of: ${Object.keys(ADDABLE).join(', ')}. The stylesheet format, Tailwind CSS, the package manager and the selector prefix are decided by "sa new".`,
    );
  }

  const project = await findProject(io.cwd);
  const current = project.options[category];
  // In a terminal, a capability with several options and no value asks which one instead of failing.
  const value =
    given ?? (io.interactive ? await askValue(deps, capability, project.options) : undefined);
  // Components are added to what the project has: the union is what gets recorded (ADR-0011).
  const addition =
    capability === 'components' && value !== undefined
      ? componentsAddition(project.options, value)
      : undefined;
  const choice = addition?.components ?? chooseValue(capability, value);
  if (capability !== 'components' && current === choice) {
    throw new UsageError(`"${choice}" is already in this project (${capability}).`);
  }
  if (capability === 'rendering' && current === 'starter-ssr') {
    throw new UsageError(
      `This project already has the Starter Angular SSR; "${choice}" cannot replace it.`,
    );
  }

  if (category === 'architecture') await requireNoArchitectureFolders(project.root);

  const label = CAPABILITIES[category].find((option) => option.id === choice);
  // The components and the shell draw their icons with Lucide, so adding them adds it too.
  const implied =
    category === 'components' || category === 'appShell' ? label?.requires?.icons?.[0] : undefined;
  const recorded: Partial<StarterOptions> = { ...project.options };
  delete recorded.componentList;
  const options = resolveOptions({
    file: {
      ...(capability === 'components' ? recorded : project.options),
      ...(implied ? { icons: implied as StarterOptions['icons'] } : {}),
      ...dependentChoices(category, choice),
      [category]: choice,
      ...(addition?.componentList ? { componentList: addition.componentList } : {}),
      install: flags.install !== false,
    },
  });
  const stages = stagesFor(category, current, options, project.options);
  const style = createStyler(io.color);

  // Nothing in the command says that Lucide comes along: say it, and why, before anything runs.
  if (implied && project.options.icons !== implied) {
    const icons = CAPABILITIES.icons.find((option) => option.id === implied)?.label ?? implied;
    println(
      io.stdout,
      `${icons} will be installed too: the sa- components draw their icons with sa-icon, which needs it.`,
    );
  }

  if (flags.dryRun) {
    println(io.stdout, style.bold('Dry run: nothing was changed. Planned steps:'));
    stages
      .filter((stage) => !stage.enabled || stage.enabled(contextFor(io, deps, project, options)))
      .forEach((stage, index) => println(io.stdout, `  ${index + 1}. ${stage.title}`));
    println(io.stdout, `  Adds: ${label?.label ?? choice}`);
    return;
  }

  println(io.stdout);
  await runPipeline(stages, contextFor(io, deps, project, options, flags.verbose));
  println(io.stdout);
  println(io.stdout, style.green(`${label?.label ?? choice} added.`));
  if (label?.docs) println(io.stdout, `Documentation: ${label.docs}`);
  if (category === 'icons' && project.options.components === 'none') {
    println(io.stdout, 'To draw an icon, add the sa-icon component: sa add components icon.');
  }
}

/** What the new choice settles for the options that only mean something next to it (ADR-0010). */
function dependentChoices(category: CapabilityCategory, choice: string): Partial<StarterOptions> {
  if (category === 'appShell') {
    const layout = defaultOption('layout', { appShell: choice })?.id;
    return layout ? { layout: layout as StarterOptions['layout'] } : {};
  }
  if (category === 'rendering') {
    const ssrPurpose = defaultOption('ssrPurpose', { rendering: choice })?.id;
    return ssrPurpose ? { ssrPurpose: ssrPurpose as StarterOptions['ssrPurpose'] } : {};
  }
  return {};
}

/**
 * What `sa add components <value>` leaves in a project: the components it has plus the ones asked
 * for (a collection or a comma list of ids), recorded as the collection or custom selection that
 * union equals. Asking for what the project already has stops with that said.
 */
function componentsAddition(
  recorded: StarterOptions,
  value: string,
): ReturnType<typeof normalizeComponents> | undefined {
  if (NOT_ADDABLE['components']?.includes(value)) return undefined;
  const requested =
    value === 'recommended'
      ? ESSENTIAL_COMPONENT_IDS
      : value === 'all'
        ? ALL_COMPONENT_IDS
        : value
            .split(',')
            .map((id) => id.trim())
            .filter(Boolean);
  const unknown = requested.find((entry) => !ALL_COMPONENT_IDS.includes(entry));
  if (unknown !== undefined) {
    throw new UsageError(`"${unknown}" is not a component.`, componentsHint());
  }
  const has = componentIdsOf(recorded);
  if (requested.every((id) => has.includes(id))) {
    throw new UsageError(
      recorded.components === 'all'
        ? 'This project already has all the components; a smaller collection cannot replace them.'
        : `"${value}" is already in this project (components).`,
    );
  }
  return normalizeComponents([...has, ...requested]);
}

/** The folders of the architecture belong to the developer when they exist: nothing is written over them. */
async function requireNoArchitectureFolders(root: string): Promise<void> {
  for (const folder of ['src/app/core', 'src/app/features', 'src/app/shared']) {
    if (await pathExists(join(root, folder))) {
      throw new UsageError(
        `${folder} already exists, and the architecture would write into it.`,
        'The architecture is applied to a project that still is what "ng new" generates; nothing was changed.',
      );
    }
  }
}

function chooseValue(capability: string, value: string | undefined): string {
  const values = addableValues(capability);
  if (value !== undefined) {
    if (NOT_ADDABLE[capability]?.includes(value)) {
      throw new UsageError(
        `"${value}" cannot be added: it is what a project has when the ${capability} capability is not in use.`,
        values.length > 0 ? `Choose one of: ${values.join(', ')}.` : undefined,
      );
    }
    return value;
  }
  if (values.length === 1 && values[0]) return values[0];
  throw new UsageError(
    `Usage: sa add ${capability} <value>`,
    capability === 'components'
      ? componentsHint()
      : values.length > 0
        ? `Choose one of: ${values.join(', ')}.`
        : undefined,
  );
}

/** The value a person picks in the terminal, for the capabilities that have more than one option. */
async function askValue(
  deps: ProgramDeps,
  capability: string,
  options: StarterOptions,
): Promise<string | undefined> {
  if (capability === 'components') return askComponents(deps, options);
  if (capability === 'rendering') return askRendering(deps, options);
  return undefined;
}

/** The components the project lacks, with the essential ones ticked, like the wizard's list. */
async function askComponents(deps: ProgramDeps, options: StarterOptions): Promise<string> {
  const has = componentIdsOf(options);
  const missing = ALL_COMPONENT_IDS.filter((id) => !has.includes(id));
  if (missing.length === 0) throw new UsageError('This project already has every component.');
  const ticked = await deps.prompter.checkbox({
    name: 'components',
    message: 'Which components do you want to add?',
    choices: missing.map((id) => ({
      value: id,
      name: `sa-${id}`,
      description: describeComponent(id, options.appShell === 'starter'),
      checked: ESSENTIAL_COMPONENT_IDS.includes(id),
    })),
  });
  if (ticked.length === 0) throw new UsageError('No component was ticked: nothing to add.');
  return ticked.join(',');
}

/** Default Angular SSR or the Starter SSR, each with what it is. */
async function askRendering(deps: ProgramDeps, options: StarterOptions): Promise<string> {
  const choices = addableValues('rendering')
    .filter((id) => id !== options.rendering)
    .map((id) => {
      const option = CAPABILITIES.rendering.find((candidate) => candidate.id === id);
      return { value: id, name: option?.label ?? id, description: option?.description ?? '' };
    });
  if (choices.length === 0)
    throw new UsageError('This project already has every rendering option.');
  return deps.prompter.select({
    name: 'rendering',
    message: 'Which server rendering do you want to add?',
    choices,
  });
}

/** What `sa add components` accepts: a collection, or the ids of the components one by one. */
function componentsHint(): string {
  return `Choose a collection (${addableValues('components').join(', ')}) or ids from: ${ALL_COMPONENT_IDS.join(', ')}.`;
}

/** The steps that bring a project from `current` to the new option, then record it. */
function stagesFor(
  category: Extract<CapabilityCategory, keyof StarterOptions>,
  current: string,
  options: StarterOptions,
  before: StarterOptions,
): Stage[] {
  switch (category) {
    case 'architecture':
      return [applyArchitectureToProject, writeStarterConfig];
    case 'icons':
      return [addIconLibrary, writeStarterConfig, installDependencies];
    case 'routing':
      return [applyRouting, writeStarterConfig];
    case 'rendering':
      // `ng add @angular/ssr` installs what it needs; the starter edits come on top of its result.
      return [
        ...(current === 'csr' ? [addAngularSsr] : []),
        ...(options.rendering === 'starter-ssr' ? [applyRendering] : []),
        writeStarterConfig,
      ];
    case 'components':
      return [
        applySharedFolders,
        ...(before.icons === options.icons ? [] : [addIconLibrary]),
        // The design base arrives with the first collection or the shell; a bigger collection only
        // adds components.
        ...(before.components === 'none' && before.appShell === 'none' ? [applyDesign] : []),
        applyComponents,
        writeStarterConfig,
        installDependencies,
      ];
    case 'appShell':
      return [
        ...(before.icons === options.icons ? [] : [addIconLibrary]),
        ...(before.components === 'none' ? [applyDesign] : []),
        applyAppShell,
        writeStarterConfig,
        installDependencies,
      ];
    case 'presence':
      return [applyPresence, writeStarterConfig];
    case 'uiSystem':
      return [applyUiSystem, writeStarterConfig];
    default:
      return [writeStarterConfig];
  }
}

function contextFor(
  io: CliIo,
  deps: ProgramDeps,
  project: { root: string; name: string },
  options: StarterOptions,
  verbose = false,
): GenerationContext {
  return {
    name: project.name,
    options,
    cwd: project.root,
    targetDir: project.root,
    io,
    deps,
    verbose,
    warnings: [],
    created: false,
  };
}
