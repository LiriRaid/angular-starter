import {
  APP_SHELL_AVAILABLE,
  CAPABILITIES,
  availableOptions,
  unmetRequirements,
  type CapabilityCategory,
  type CapabilityOption,
  type Registry,
  type RequirementContext,
} from '../config/capabilities.js';
import { DEFAULT_OPTIONS } from '../config/resolve.js';
import { PACKAGE_MANAGERS, type StarterOptions } from '../config/schema.js';
import { formatChoices } from './choices.js';
import type { Prompter } from './prompter.js';

type SelectKey = Extract<keyof StarterOptions, CapabilityCategory>;

const MESSAGES: Record<SelectKey, string> = {
  architecture: 'Which architecture would you like to use?',
  routing: 'Which routing system would you like to use?',
  style: 'Select a stylesheet format:',
  rendering: 'Select a rendering strategy:',
  components: 'Which native UI components would you like to include?',
  icons: 'Select an icon library:',
  packageManager: 'Select a package manager:',
};

/** The package manager that launched the CLI (`pnpm dlx`, `npx`, ...), or npm. */
export function detectPackageManager(env: NodeJS.ProcessEnv): StarterOptions['packageManager'] {
  const launcher = (env['npm_config_user_agent'] ?? '').split('/')[0];
  return PACKAGE_MANAGERS.find((manager) => manager === launcher) ?? 'npm';
}

/**
 * Asks only what is still unknown and what can really be generated: a category with a single
 * available option is not a question, and a choice that implies another one (components need
 * Lucide Icons) sets it instead of asking. Returns the answers given, never the known values.
 */
export async function runWizard(
  known: Partial<StarterOptions>,
  prompter: Prompter,
  env: NodeJS.ProcessEnv,
  registry: Registry = CAPABILITIES,
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
      style: style === undefined ? undefined : String(style),
      // A stylesheet format that is not Tailwind CSS means there is no Tailwind CSS.
      tailwind: tailwind ?? (style === undefined ? undefined : false),
      icons: String(known.icons ?? answers.icons ?? '') || undefined,
    };
  }

  function candidates(key: SelectKey): readonly CapabilityOption[] {
    const options = availableOptions(key, registry);
    if (key === 'architecture') {
      // Only the architectures that can take the routing or the components already chosen.
      const chosen = [find('routing', known.routing), find('components', known.components)];
      return options.filter((option) =>
        chosen.every(
          (other) => !other || unmetRequirements(other, { architecture: option.id }).length === 0,
        ),
      );
    }
    const now = context();
    const usable = options.filter((option) => unmetRequirements(option, now).length === 0);
    return key === 'style' && known.tailwind === false
      ? usable.filter((option) => option.id !== 'tailwind')
      : usable;
  }

  async function ask(key: SelectKey): Promise<string | undefined> {
    if (known[key] !== undefined || (key === 'icons' && answers.icons !== undefined)) return;
    const options = candidates(key);
    // The only architecture the choices already made accept is the answer, not a question.
    if (options.length === 1 && key === 'architecture' && options[0]) {
      answers[key] = options[0].id;
    }
    if (options.length < 2) return;

    const detected = key === 'packageManager' ? detectPackageManager(env) : undefined;
    // Only a category with one best answer starts on it; elsewhere the user chooses from the top.
    const preselected = options.find((option) => option.recommended)?.id ?? detected;
    const answer = await prompter.select({
      name: key,
      message: MESSAGES[key],
      default: preselected,
      choices: formatChoices(options, (option) =>
        detected !== undefined && option.id === detected ? 'Default' : undefined,
      ),
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

  await ask('architecture');
  await ask('routing');
  // Tailwind CSS is part of the stylesheet list, and implies the CSS format.
  if (known.tailwind !== true) await ask('style');
  await ask('rendering');

  if (APP_SHELL_AVAILABLE && known.appShell === undefined) {
    answers.appShell = await prompter.confirm({
      name: 'appShell',
      message: 'Would you like to include the Angular Starter App Shell? (Recommended)',
      default: true,
    });
  }

  const components = await ask('components');
  const needed = find('components', components ?? known.components)?.requires?.icons?.[0];
  if (needed && known.icons === undefined) answers.icons = needed;
  await ask('icons');
  await ask('packageManager');

  if (known.git === undefined) {
    answers.git = await prompter.confirm({
      name: 'git',
      message: 'Initialize a Git repository?',
      default: DEFAULT_OPTIONS.git,
    });
  }
  if (known.install === undefined) {
    answers.install = await prompter.confirm({
      name: 'install',
      message: 'Install dependencies now?',
      default: DEFAULT_OPTIONS.install,
    });
  }

  return answers as Partial<StarterOptions>;
}
