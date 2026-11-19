import {
  APP_SHELL_AVAILABLE,
  availableOptions,
  type CapabilityCategory,
} from '../config/capabilities.js';
import { DEFAULT_OPTIONS } from '../config/resolve.js';
import { PACKAGE_MANAGERS, type StarterOptions } from '../config/schema.js';
import type { Prompter } from './prompter.js';

type SelectKey = Extract<keyof StarterOptions, CapabilityCategory>;

const MESSAGES: Record<SelectKey, string> = {
  architecture: 'Which architecture would you like to use?',
  routing: 'Which routing system would you like to use?',
  style: 'Select a stylesheet format:',
  rendering: 'Select a rendering strategy:',
  components: 'Would you like to include native UI components?',
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
 * available option is not a question. Returns the answers given, never the known values.
 */
export async function runWizard(
  known: Partial<StarterOptions>,
  prompter: Prompter,
  env: NodeJS.ProcessEnv,
): Promise<Partial<StarterOptions>> {
  const answers: Record<string, unknown> = {};

  async function ask(key: SelectKey): Promise<void> {
    if (known[key] !== undefined) return;
    const options = availableOptions(key);
    if (options.length < 2) return;

    const fallback = key === 'packageManager' ? detectPackageManager(env) : DEFAULT_OPTIONS[key];
    const preselected = options.find((option) => option.recommended)?.id ?? fallback;
    answers[key] = await prompter.select({
      name: key,
      message: MESSAGES[key],
      default: preselected,
      choices: options.map((option) => ({
        value: option.id,
        name: `${option.label}${option.recommended ? ' — Recommended' : ''}${key === 'packageManager' && option.id === preselected ? ' — Default' : ''}`,
      })),
    });
  }

  await ask('architecture');
  await ask('routing');
  // Tailwind needs the CSS format, so asking for another one would only end in an error.
  if (known.tailwind !== true) await ask('style');

  const style = known.style ?? answers['style'] ?? DEFAULT_OPTIONS.style;
  if (known.tailwind === undefined && style === 'css') {
    answers['tailwind'] = await prompter.confirm({
      name: 'tailwind',
      message: 'Would you like to integrate Tailwind CSS? (Recommended)',
      default: true,
    });
  }

  await ask('rendering');

  if (APP_SHELL_AVAILABLE && known.appShell === undefined) {
    answers['appShell'] = await prompter.confirm({
      name: 'appShell',
      message: 'Would you like to include the Angular Starter App Shell? (Recommended)',
      default: true,
    });
  }

  await ask('components');
  await ask('icons');
  await ask('packageManager');

  if (known.git === undefined) {
    answers['git'] = await prompter.confirm({
      name: 'git',
      message: 'Initialize a Git repository?',
      default: DEFAULT_OPTIONS.git,
    });
  }
  if (known.install === undefined) {
    answers['install'] = await prompter.confirm({
      name: 'install',
      message: 'Install dependencies now?',
      default: DEFAULT_OPTIONS.install,
    });
  }

  return answers as Partial<StarterOptions>;
}
