import {
  CAPABILITIES,
  availableOptions,
  offeredOptions,
  plannedOptions,
  unmetRequirements,
  type CapabilityCategory,
  type CapabilityOption,
  type Registry,
  type RequirementContext,
} from '../config/capabilities.js';
import {
  ALL_COMPONENT_IDS,
  ESSENTIAL_COMPONENT_IDS,
  normalizeComponents,
} from '../config/components.js';
import { DEFAULT_OPTIONS } from '../config/resolve.js';
import { CancelledError } from '../errors.js';
import { COMPONENT_DESCRIPTIONS } from '../engine/components/descriptions.js';
import { SHELL_COMPONENTS } from '../engine/app-shell/app-shell.js';
import { COMPONENTS } from '../engine/components/manifest.js';
import { PACKAGE_MANAGERS, type StarterOptions } from '../config/schema.js';
import { formatChoices } from './choices.js';
import { History, Rewind } from './history.js';
import { BackRequested, type Prompter } from './prompter.js';

type SelectKey = Extract<keyof StarterOptions, CapabilityCategory>;

const MESSAGES: Record<SelectKey, string> = {
  architecture: 'Which architecture would you like to use?',
  routing: 'Which routing system would you like to use?',
  style: 'Select a stylesheet format:',
  rendering: 'Select a rendering strategy:',
  ssrPurpose: 'What is the Starter SSR for?',
  appShell: 'Which application shell would you like to use?',
  layout: 'Which layout mode would you like for the application shell?',
  presence: 'Which real-time presence would you like to use?',
  components: 'Which native UI components would you like to include?',
  uiSystem: 'Which UI System would you like to use?',
  icons: 'Select an icon library:',
  packageManager: 'Select a package manager:',
};

/** What each question is called in the list of answers to change. */
const TITLES: Record<SelectKey | 'componentList' | 'git' | 'install', string> = {
  architecture: 'Architecture',
  routing: 'Routing',
  style: 'Stylesheet',
  rendering: 'Rendering',
  ssrPurpose: 'Starter SSR purpose',
  appShell: 'App shell',
  layout: 'Layout',
  presence: 'Presence',
  components: 'Components',
  componentList: 'Component list',
  uiSystem: 'UI System',
  icons: 'Icons',
  packageManager: 'Package manager',
  git: 'Git',
  install: 'Install dependencies',
};

const yesNo = (value: boolean): string => (value ? 'Yes' : 'No');

/** What a component is, what it brings with it and the global stylesheet it adds. */
function describeComponent(id: string, shellBrings: boolean): string {
  const definition = COMPONENTS.find((component) => component.id === id);
  const brings = definition?.uses.length ? ` Also brings: ${definition.uses.join(', ')}.` : '';
  const styles = definition?.styles.length
    ? ` Adds: ${definition.styles.map((style) => `${style}.css`).join(', ')}.`
    : '';
  const shell =
    shellBrings && SHELL_COMPONENTS.includes(id) ? ' The app shell brings it anyway.' : '';
  return `${COMPONENT_DESCRIPTIONS[id] ?? id}${brings}${styles}${shell}`;
}

/** The package manager that launched the CLI (`pnpm dlx`, `npx`, ...), or npm. */
export function detectPackageManager(env: NodeJS.ProcessEnv): StarterOptions['packageManager'] {
  const launcher = (env['npm_config_user_agent'] ?? '').split('/')[0];
  return PACKAGE_MANAGERS.find((manager) => manager === launcher) ?? 'npm';
}

/** The reason shown next to a choice that is listed but cannot be generated yet. */
const UNDER_CONSTRUCTION = 'Under construction';

/**
 * Asks only what is still unknown and what can really be generated, in the order of the flow
 * (ADR-0010): each answer decides which questions come next. A category with a single option is not
 * a question, except the layout and the purpose of the Starter SSR, which also list what is under
 * construction, disabled. A choice that implies another one (components need Lucide Icons) sets it
 * instead of asking. Returns the answers given, never the known values.
 *
 * Esc goes back to the question before (ADR-0013): the answers are kept in a history and the flow runs
 * again from the start, replaying them, so what each answer decided is recomputed. With a `review`,
 * the wizard also ends by asking to create the project, change an answer or cancel.
 */
export async function runWizard(
  known: Partial<StarterOptions>,
  prompter: Prompter,
  env: NodeJS.ProcessEnv,
  registry: Registry = CAPABILITIES,
  review?: WizardReview,
): Promise<Partial<StarterOptions>> {
  const history = new History();
  for (;;) {
    try {
      history.begin();
      const answers = await runFlow(known, prompter, env, registry, history);
      if (review) await confirmAnswers(answers, prompter, history, review);
      return answers;
    } catch (error) {
      if (!(error instanceof Rewind)) throw error;
      history.rewind(error.to);
    }
  }
}

/** What the wizard needs from the command to end with a confirmation. */
export interface WizardReview {
  /** Shows what the answers add up to, each time before asking whether to create the project. */
  show(answers: Partial<StarterOptions>): void;
}

/** The answer to a question, or `undefined` when the user pressed Esc to leave it. */
async function unlessBack<T>(question: Promise<T>): Promise<T | undefined> {
  try {
    return await question;
  } catch (error) {
    if (error instanceof BackRequested) return undefined;
    throw error;
  }
}

/** The last question: create, change an answer (which one is asked next) or cancel. */
async function confirmAnswers(
  answers: Partial<StarterOptions>,
  prompter: Prompter,
  history: History,
  review: WizardReview,
): Promise<void> {
  const last = history.length - 1;
  for (;;) {
    review.show(answers);
    const verdict = await unlessBack(
      prompter.select({
        name: 'confirm',
        message: 'Create project with this configuration?',
        default: 'create',
        canGoBack: last >= 0,
        choices: [
          { value: 'create', name: 'Create the project' },
          // With nothing asked there is nothing to change: everything came from flags.
          ...(last >= 0 ? [{ value: 'change', name: 'Change an answer' }] : []),
          { value: 'cancel', name: 'Cancel' },
        ],
      }),
    );
    // Esc on the confirmation goes back to the last question.
    if (verdict === undefined) throw new Rewind(last);
    if (verdict === 'create') return;
    if (verdict === 'cancel') throw new CancelledError();

    const name = await unlessBack(
      prompter.select({
        name: 'changeAnswer',
        message: 'Which answer would you like to change?',
        canGoBack: true,
        choices: history.answered.map((entry) => ({
          value: entry.name,
          name: `${entry.title}: ${entry.summary}`,
        })),
      }),
    );
    // Esc on the list returns to the confirmation.
    if (name === undefined) continue;
    const index = history.indexOf(name);
    if (index < 0) throw new Error(`"${name}" is not an answered question`);
    throw new Rewind(index);
  }
}

/** One pass of the flow: every question of the wizard, in order, asked only when it still matters. */
async function runFlow(
  known: Partial<StarterOptions>,
  prompter: Prompter,
  env: NodeJS.ProcessEnv,
  registry: Registry,
  history: History,
): Promise<Partial<StarterOptions>> {
  const answers: Partial<Record<keyof StarterOptions, unknown>> = {};
  const find = (
    category: CapabilityCategory,
    id: string | undefined,
  ): CapabilityOption | undefined => registry[category].find((option) => option.id === id);

  /** What the choices made so far say about the project, for the requirements of the options. */
  function context(): RequirementContext {
    const tailwind = known.tailwind ?? (answers.tailwind as boolean | undefined);
    const style = known.style ?? answers.style ?? (tailwind ? 'css' : undefined);
    return {
      architecture: String(
        known.architecture ?? answers.architecture ?? DEFAULT_OPTIONS.architecture,
      ),
      routing: String(known.routing ?? answers.routing ?? '') || undefined,
      rendering: String(known.rendering ?? answers.rendering ?? '') || undefined,
      // Asked before the layout and presence: a shell that was not chosen (or cannot be) is no shell.
      appShell: String(known.appShell ?? answers.appShell ?? 'none'),
      components: String(known.components ?? answers.components ?? '') || undefined,
      style: style === undefined ? undefined : String(style),
      // A stylesheet format that is not Tailwind CSS means there is no Tailwind CSS.
      tailwind: tailwind ?? (style === undefined ? undefined : false),
      icons: String(known.icons ?? answers.icons ?? '') || undefined,
    };
  }

  /** What can be chosen now, and what is listed next to it as under construction. */
  function candidates(key: SelectKey): {
    options: readonly CapabilityOption[];
    planned: readonly CapabilityOption[];
  } {
    if (key === 'architecture') {
      // Only the architectures that can take the routing or the components already chosen.
      const chosen = [find('routing', known.routing), find('components', known.components)];
      const options = availableOptions(key, registry).filter((option) =>
        chosen.every(
          (other) => !other || unmetRequirements(other, { architecture: option.id }).length === 0,
        ),
      );
      return { options, planned: [] };
    }
    const now = context();
    // A custom selection comes from ticking the list that follows, never from this question.
    const offered = offeredOptions(key, now, registry).filter(
      (option) => !(key === 'components' && option.id === 'custom'),
    );
    return {
      options:
        key === 'style' && known.tailwind === false
          ? offered.filter((option) => option.id !== 'tailwind')
          : offered,
      planned: plannedOptions(key, now, registry),
    };
  }

  async function ask(key: SelectKey): Promise<string | undefined> {
    if (known[key] !== undefined || (key === 'icons' && answers.icons !== undefined)) return;
    const { options, planned } = candidates(key);
    // The only architecture the choices already made accept is the answer, not a question.
    if (options.length === 1 && key === 'architecture' && options[0]) {
      answers[key] = options[0].id;
    }
    const listed = registry[key].filter(
      (option) => options.includes(option) || planned.includes(option),
    );
    if (listed.length < 2) return;

    const detected = key === 'packageManager' ? detectPackageManager(env) : undefined;
    // Only a category with one best answer starts on it; elsewhere the user chooses from the top.
    const preselected = options.find((option) => option.recommended)?.id ?? detected;
    const choices = formatChoices(listed, (option) =>
      detected !== undefined && option.id === detected ? 'Default' : undefined,
    ).map((choice) =>
      planned.some((option) => option.id === choice.value)
        ? { ...choice, disabled: UNDER_CONSTRUCTION }
        : choice,
    );
    const answer = await history.turn<string>({
      name: key,
      title: TITLES[key],
      summarize: (value) => find(key, value)?.label ?? value,
      ask: (previous, canGoBack) =>
        prompter.select({
          name: key,
          message: MESSAGES[key],
          default: previous ?? preselected,
          choices,
          canGoBack,
        }),
    });
    if (key === 'style') {
      // "Tailwind CSS" is the CSS format with Tailwind enabled.
      answers.style = answer === 'tailwind' ? 'css' : answer;
      answers.tailwind = answer === 'tailwind';
    } else {
      answers[key] = answer;
    }
    return answer;
  }

  /**
   * The list of every component with the chosen collection ticked (ADR-0011), like the last question
   * of `ng new`. What ends ticked is recorded as the collection it equals, or as a custom selection.
   */
  async function askComponentList(collection: string): Promise<void> {
    const preset = collection === 'all' ? ALL_COMPONENT_IDS : ESSENTIAL_COMPONENT_IDS;
    const ticked = await history.turn<string[]>({
      name: 'componentList',
      title: TITLES.componentList,
      summarize: (ids) => `${ids.length} of ${ALL_COMPONENT_IDS.length}`,
      ask: (previous, canGoBack) =>
        prompter.checkbox({
          name: 'componentList',
          message: 'Which components do you want to generate?',
          canGoBack,
          choices: ALL_COMPONENT_IDS.map((id) => ({
            value: id,
            name: `as-${id}`,
            description: describeComponent(id, context().appShell === 'starter'),
            checked: (previous ?? preset).includes(id),
          })),
        }),
    });
    const choice = normalizeComponents(ticked);
    answers.components = choice.components;
    if (choice.componentList) answers.componentList = choice.componentList;
    else delete answers.componentList;
  }

  await ask('architecture');
  await ask('routing');
  // Tailwind CSS is part of the stylesheet list, and implies the CSS format.
  if (known.tailwind !== true) await ask('style');
  await ask('rendering');
  await ask('ssrPurpose');

  // The shell and the components draw with Lucide Icons, so choosing either one sets it.
  const impliedIcons = (category: 'appShell' | 'components', id: string | undefined): void => {
    const needed = find(category, id)?.requires?.icons?.[0];
    if (needed && known.icons === undefined) answers.icons = needed;
  };
  const shell = await ask('appShell');
  impliedIcons('appShell', shell ?? known.appShell);
  await ask('layout');
  await ask('presence');

  const collection = await ask('components');
  if (collection !== undefined && collection !== 'none') await askComponentList(collection);
  impliedIcons('components', answers.components ? String(answers.components) : known.components);
  await ask('uiSystem');
  await ask('icons');
  await ask('packageManager');

  const yesNoQuestion = async (
    key: 'git' | 'install',
    message: string,
    fallback: boolean,
  ): Promise<boolean> =>
    history.turn<boolean>({
      name: key,
      title: TITLES[key],
      summarize: yesNo,
      ask: (previous, canGoBack) =>
        prompter.confirm({ name: key, message, default: previous ?? fallback, canGoBack }),
    });
  if (known.git === undefined) {
    answers.git = await yesNoQuestion('git', 'Initialize a Git repository?', DEFAULT_OPTIONS.git);
  }
  if (known.install === undefined) {
    answers.install = await yesNoQuestion(
      'install',
      'Install dependencies now?',
      DEFAULT_OPTIONS.install,
    );
  }

  return answers as Partial<StarterOptions>;
}
