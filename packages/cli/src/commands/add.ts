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
import { println, type CliIo } from '../io.js';
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
  value: string | undefined,
  flags: AddFlags,
): Promise<void> {
  const category = capability === undefined ? undefined : ADDABLE[capability];
  if (capability === undefined || category === undefined) {
    throw new UsageError(
      capability === undefined
        ? 'Usage: as add <capability> [value]'
        : `Unknown capability "${capability}".`,
      `Choose one of: ${Object.keys(ADDABLE).join(', ')}. The architecture, the stylesheet format, Tailwind CSS, the package manager and the selector prefix are decided by "as new".`,
    );
  }

  const project = await findProject(io.cwd);
  const current = project.options[category];
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
      `This project already has the Angular Starter SSR; "${choice}" cannot replace it.`,
    );
  }

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
 * What `as add components <value>` leaves in a project: the components it has plus the ones asked
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
    throw new UsageError(
      `"${unknown}" is not a component.`,
      `Choose a collection (${addableValues('components').join(', ')}) or ids from: ${ALL_COMPONENT_IDS.join(', ')}.`,
    );
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
    `Usage: as add ${capability} <value>`,
    values.length > 0 ? `Choose one of: ${values.join(', ')}.` : undefined,
  );
}

/** The steps that bring a project from `current` to the new option, then record it. */
function stagesFor(
  category: Extract<CapabilityCategory, keyof StarterOptions>,
  current: string,
  options: StarterOptions,
  before: StarterOptions,
): Stage[] {
  switch (category) {
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
