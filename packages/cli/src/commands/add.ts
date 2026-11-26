import {
  CAPABILITIES,
  defaultOption,
  unmetRequirements,
  type CapabilityCategory,
} from '../config/capabilities.js';
import {
  ALL_COMPONENT_IDS,
  ESSENTIAL_COMPONENT_IDS,
  UI_SYSTEM_COMPONENT_IDS,
  componentIdsOf,
  normalizeComponents,
} from '../config/components.js';
import { resolveOptions } from '../config/resolve.js';
import { installedComponentIds } from '../engine/components/installed.js';
import type { StarterOptions } from '../config/schema.js';
import type { ProgramDeps } from '../deps.js';
import { runPipeline, type GenerationContext, type Stage } from '../engine/pipeline.js';
import { toolingProfile } from '../engine/tooling/tooling.js';
import { uiSystemProfile } from '../engine/ui-system/ui-system.js';
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
  applyTooling,
  applyUiSystem,
  installDependencies,
  updateUiSystemCatalog,
  writeProjectReadme,
  writeStarterConfig,
} from '../engine/stages.js';
import { UsageError } from '../errors.js';
import { println, type CliIo } from '../io.js';
import { describeComponent } from '../wizard/wizard.js';
import { findProject, type StarterProject } from '../project/find.js';
import {
  ADDABLE,
  ADDABLE_WORDS,
  NOT_ADDABLE,
  TOOLING_CAPABILITY,
  addableValues,
  prerequisitesOf,
  unchosenOf,
  type AddStep,
} from './addable.js';
import { createStyler } from '../ui/format.js';

export { ADDABLE, addableValues };

const TOOLING_DOCS =
  'https://github.com/LiriRaid/starter-angular/blob/main/docs/adr/0027-default-eslint-prettier-and-sa-test.md';

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
  /** True when another `sa add` runs this one to bring what it needs: it asks nothing more. */
  chained = false,
): Promise<void> {
  // Lint and format are not an option of the project (every new project has them): they have no category.
  if (capability === TOOLING_CAPABILITY) return addTooling(io, deps, flags);
  const category = capability === undefined ? undefined : ADDABLE[capability];
  if (capability === undefined || category === undefined) {
    throw new UsageError(
      capability === undefined
        ? 'Usage: sa add <capability> [value]'
        : `Unknown capability "${capability}".`,
      `Choose one of: ${ADDABLE_WORDS.join(', ')}. The stylesheet format, Tailwind CSS, the package manager and the selector prefix are decided by "sa new".`,
    );
  }

  const project = await findProject(io.cwd);
  const current = project.options[category];
  // In a terminal, a capability with several options and no value asks which one instead of failing.
  const value =
    given ??
    (io.interactive ? await askValue(deps, capability, project.options, project.root) : undefined);
  // Components are added to what the project has: the union is what gets recorded (ADR-0011).
  const addition =
    capability === 'components' && value !== undefined
      ? componentsAddition(project.options, value)
      : undefined;
  const choice = addition?.components ?? chooseValue(capability, value);
  if (capability !== 'components' && current === choice) {
    // A UI System the project has is brought up to its components instead of refused (ADR-0024).
    if (category === 'uiSystem') return completeCatalog(io, deps, project, flags);
    throw new UsageError(`"${choice}" is already in this project (${capability}).`);
  }
  if (capability === 'rendering' && current === 'starter-ssr') {
    throw new UsageError(
      `This project already has the Starter Angular SSR; "${choice}" cannot replace it.`,
    );
  }

  const label = CAPABILITIES[category].find((option) => option.id === choice);

  // Which components the project gets is the developer's choice: they are never added on their behalf.
  if (unchosenOf(category, choice, project.options).length > 0) {
    throw new UsageError(
      `${label?.label ?? choice} needs the sa- components, which this project does not have.`,
      `Add them first with "sa add components" (a collection, or the ones you pick), then run "sa add ${capability}" again.`,
    );
  }

  // What the option needs and the project lacks is added first, in order, once the developer agrees.
  const missing = prerequisitesOf(category, choice, project.options);
  if (missing.length > 0) {
    const mainValue = value ?? choice;
    await addWithPrerequisites(io, deps, {
      capability,
      value: mainValue,
      label: label?.label ?? choice,
      missing,
      flags,
      chained,
    });
    return;
  }

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
  // Every addition leaves the README of the project describing what it has now (ADR-0024).
  const stages = stagesFor(category, current, options, project.options).flatMap((stage) =>
    stage === writeStarterConfig ? [writeProjectReadme, stage] : [stage],
  );
  const style = createStyler(io.color);

  // Nothing in the command says that Lucide comes along: say it, and why, before anything runs.
  if (implied && project.options.icons !== implied) {
    const icons = CAPABILITIES.icons.find((option) => option.id === implied)?.label ?? implied;
    println(
      io.stdout,
      `${icons} will be installed too: the sa- components draw their icons with sa-icon, which needs it.`,
    );
  }

  // The UI System draws its own interface with a few components: it brings the ones the project lacks.
  if (category === 'uiSystem') {
    const have = await installedComponentIds(project.root);
    const base = UI_SYSTEM_COMPONENT_IDS.filter((id) => !have.includes(id));
    if (base.length > 0) {
      println(
        io.stdout,
        `${base.map((id) => `sa-${id}`).join(', ')} will be installed too: the UI System draws its own interface with them.`,
      );
    }
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
  const context = contextFor(io, deps, project, options, flags.verbose);
  await runPipeline(stages, context);
  println(io.stdout);
  println(io.stdout, style.green(`${label?.label ?? choice} added.`));
  if (label?.docs) println(io.stdout, `Documentation: ${label.docs}`);
  for (const note of context.notes ?? []) println(io.stdout, note);
  for (const warning of context.warnings) println(io.stdout, `${style.yellow('!')} ${warning}`);
  if (category === 'icons' && project.options.components === 'none') {
    println(io.stdout, 'To draw an icon, add the sa-icon component: sa add components icon.');
  }
  if (chained) return;
  // The structure alone is the architecture; the routing and the shell are asked, not assumed.
  if (category === 'architecture' && io.interactive && project.options.appShell === 'none') {
    const more = await deps.prompter.confirm({
      name: 'routing-and-shell',
      message: 'Add the Starter Angular routing and the app shell now?',
      default: false,
    });
    if (more) {
      println(io.stdout);
      await addCommand(io, deps, 'routing', 'starter', { ...flags, install: false }, true);
      await addCommand(io, deps, 'app-shell', undefined, flags);
    }
  } else {
    await offerUiSystem(io, deps, category, flags);
  }
}

/**
 * `sa add tooling` (ADR-0027): the ESLint configuration, its packages and the lint and format scripts, for a
 * project made before every project had them. An ESLint setup the project has stays as it is.
 */
async function addTooling(io: CliIo, deps: ProgramDeps, flags: AddFlags): Promise<void> {
  const project = await findProject(io.cwd);
  const request = {
    targetDir: project.root,
    prefix: project.options.prefix,
    style: project.options.style,
  };
  if (await toolingProfile.isComplete(request)) {
    throw new UsageError(
      'Lint and format are already in this project (tooling): it has the ESLint setup and the lint and format scripts.',
    );
  }

  const options = { ...project.options, install: flags.install !== false };
  const stages = [applyTooling, writeProjectReadme, installDependencies];
  const style = createStyler(io.color);
  const context = contextFor(io, deps, project, options, flags.verbose);

  if (flags.dryRun) {
    println(io.stdout, style.bold('Dry run: nothing was changed. Planned steps:'));
    stages
      .filter((stage) => !stage.enabled || stage.enabled(context))
      .forEach((stage, index) => println(io.stdout, `  ${index + 1}. ${stage.title}`));
    println(io.stdout, '  Adds: lint and format (ESLint, Prettier scripts)');
    return;
  }

  println(io.stdout);
  await runPipeline(stages, context);
  println(io.stdout);
  println(io.stdout, style.green('Lint and format added.'));
  println(io.stdout, `Documentation: ${TOOLING_DOCS}`);
  for (const note of context.notes ?? []) println(io.stdout, note);
  for (const warning of context.warnings) println(io.stdout, `${style.yellow('!')} ${warning}`);
}

/** Does this capability run an install after its steps? */
const installs = (capability: string): boolean =>
  capability === 'components' || capability === 'app-shell' || capability === 'icons';

interface Pending {
  capability: string;
  value: string;
  label: string;
  missing: AddStep[];
  flags: AddFlags;
  chained: boolean;
}

/**
 * The capability needs others the project does not have (the registry says which). In a terminal it says
 * what and asks once; then it adds them in order and the capability itself, installing only at the last
 * step that installs. A dry run only lists the chain, and outside a terminal the command stops and names
 * the commands to run.
 */
async function addWithPrerequisites(
  io: CliIo,
  deps: ProgramDeps,
  { capability, value, label, missing, flags, chained }: Pending,
): Promise<void> {
  const commands = missing.map((step) => `sa add ${step.capability} ${step.value}`);
  const names = missing.map((step) => {
    const category = ADDABLE[step.capability];
    const option = category && CAPABILITIES[category].find((entry) => entry.id === step.value);
    return option?.label ?? step.capability;
  });
  if (flags.dryRun) {
    const style = createStyler(io.color);
    println(io.stdout, style.bold('Dry run: nothing was changed. It would add, in this order:'));
    for (const command of [...commands, `sa add ${capability} ${value}`]) {
      println(io.stdout, `  ${command}`);
    }
    return;
  }
  if (!io.interactive || chained) {
    throw new UsageError(
      `${label} needs ${names.join(', ')}, which this project does not have.`,
      `Add them first: ${commands.join(', ')}. In a terminal, "sa add ${capability}" asks and adds them for you.`,
    );
  }
  const yes = await deps.prompter.confirm({
    name: 'prerequisites',
    message: `${label} needs ${names.join(', ')}, which this project does not have. Add ${missing.length === 1 ? 'it' : 'them'} first?`,
    default: true,
  });
  if (!yes) {
    println(io.stdout, 'Nothing was changed.');
    return;
  }
  const steps = [...missing, { capability, value }];
  for (const [index, step] of steps.entries()) {
    const later = steps.slice(index + 1).some((next) => installs(next.capability));
    const install = flags.install !== false && !(installs(step.capability) && later);
    const last = index === steps.length - 1;
    await addCommand(
      io,
      deps,
      step.capability,
      step.value,
      { ...flags, install },
      !last || chained,
    );
  }
}

const named = (ids: readonly string[]): string => ids.map((id) => `sa-${id}`).join(', ');

/**
 * `sa add ui-system` in a project that has it: the catalog shows the components the project had when it
 * was generated, so this brings it up to the ones it has now, without rewriting what the developer changed.
 */
async function completeCatalog(
  io: CliIo,
  deps: ProgramDeps,
  project: StarterProject,
  flags: AddFlags,
): Promise<void> {
  const missing = await uiSystemProfile.missingEntries(project.root);
  if (missing.length === 0) {
    throw new UsageError(
      '"starter" is already in this project (ui-system), and its catalog shows every component the project has.',
    );
  }
  const style = createStyler(io.color);
  if (flags.dryRun) {
    println(io.stdout, style.bold('Dry run: nothing was changed. Planned steps:'));
    println(io.stdout, `  1. ${updateUiSystemCatalog.title}`);
    println(io.stdout, `  Adds to the catalog: ${named(missing)}`);
    return;
  }
  println(io.stdout);
  const context = contextFor(io, deps, project, project.options, flags.verbose);
  await runPipeline([updateUiSystemCatalog], context);
  println(io.stdout);
  for (const note of context.notes ?? []) println(io.stdout, note);
  for (const warning of context.warnings) println(io.stdout, `${style.yellow('!')} ${warning}`);
}

/** The UI System is the catalog of the components in the design preferences: offered when it can be added. */
async function offerUiSystem(
  io: CliIo,
  deps: ProgramDeps,
  category: CapabilityCategory,
  flags: AddFlags,
): Promise<void> {
  if (category !== 'appShell' && category !== 'components') return;
  const fresh = await findProject(io.cwd);
  // More components than the catalog describes: offer to complete it (ADR-0024).
  if (category === 'components' && fresh.options.uiSystem === 'starter') {
    const missing = await uiSystemProfile.missingEntries(fresh.root);
    if (missing.length === 0) return;
    if (!io.interactive) {
      println(
        io.stdout,
        `Next: "sa add ui-system" completes the catalog of the UI System with ${named(missing)}.`,
      );
      return;
    }
    const yes = await deps.prompter.confirm({
      name: 'ui-system-catalog',
      message: `Complete the UI System catalog with ${named(missing)}?`,
      default: true,
    });
    if (yes) {
      println(io.stdout);
      await addCommand(io, deps, 'ui-system', undefined, flags, true);
    }
    return;
  }
  const option = CAPABILITIES.uiSystem.find((candidate) => candidate.id === 'starter');
  if (
    fresh.options.uiSystem !== 'none' ||
    !option ||
    unmetRequirements(option, fresh.options).length > 0 ||
    prerequisitesOf('uiSystem', 'starter', fresh.options).length > 0
  ) {
    return;
  }
  if (!io.interactive) {
    println(
      io.stdout,
      'Next: "sa add ui-system" adds the catalog of your components to the design preferences.',
    );
    return;
  }
  const yes = await deps.prompter.confirm({
    name: 'ui-system',
    message:
      'Add the UI System, the catalog of all your components in the UI tab of the design preferences?',
    default: true,
  });
  if (yes) {
    println(io.stdout);
    await addCommand(io, deps, 'ui-system', undefined, flags, true);
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
  root: string,
): Promise<string | undefined> {
  if (capability === 'components') return askComponents(deps, options, root);
  if (capability === 'rendering') return askRendering(deps, options);
  if (capability === 'architecture') return askArchitecture(deps, options);
  return undefined;
}

/**
 * Every component, the ones the project has shown ticked and blocked so a developer sees which are
 * missing, and the recommended ones marked. What the project has comes from its folders: the shell
 * brings components the configuration does not list.
 */
async function askComponents(
  deps: ProgramDeps,
  options: StarterOptions,
  root: string,
): Promise<string> {
  const has = new Set([...componentIdsOf(options), ...(await installedComponentIds(root))]);
  if (ALL_COMPONENT_IDS.every((id) => has.has(id))) {
    throw new UsageError('This project already has every component.');
  }
  const ticked = await deps.prompter.checkbox({
    name: 'components',
    message: 'Which components do you want to add?',
    choices: ALL_COMPONENT_IDS.map((id) => {
      const installed = has.has(id);
      return {
        value: id,
        name: `sa-${id}${ESSENTIAL_COMPONENT_IDS.includes(id) ? ' (recommended)' : ''}`,
        description: describeComponent(id, options.appShell === 'starter'),
        checked: installed || ESSENTIAL_COMPONENT_IDS.includes(id),
        ...(installed ? { disabled: '(already in the project)' } : {}),
      };
    }),
  });
  // A blocked choice never comes back from a real prompt; the filter keeps it true for any prompter.
  const added = ticked.filter((id) => !has.has(id));
  if (added.length === 0) throw new UsageError('No component was ticked: nothing to add.');
  return added.join(',');
}

/** The architectures a project can take, the ones still planned listed but not selectable. */
async function askArchitecture(
  deps: ProgramDeps,
  options: StarterOptions,
): Promise<string | undefined> {
  // A project that has one already gets the usual "already in this project" answer.
  if (options.architecture !== 'angular-default') return undefined;
  return deps.prompter.select({
    name: 'architecture',
    message: 'Which architecture do you want to add?',
    choices: CAPABILITIES.architecture
      .filter((option) => !NOT_ADDABLE['architecture']?.includes(option.id))
      .map((option) => ({
        value: option.id,
        name: option.label,
        description: option.description,
        ...(option.available ? {} : { disabled: 'planned' }),
      })),
  });
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
    notes: [],
    created: false,
  };
}
