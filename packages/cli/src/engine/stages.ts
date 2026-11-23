import { constants } from 'node:fs';
import { access, readFile, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import {
  ANGULAR_CLI_VERSION,
  ICON_PACKAGES,
  SUPPORTED_NODE_RANGE,
  isSupportedNode,
} from '../compat.js';
import {
  PROJECT_CONFIG_FILE,
  createProjectConfig,
  serializeProjectConfig,
} from '../config/project-config.js';
import { RuntimeError, UsageError } from '../errors.js';
import { CLI_VERSION } from '../version.js';
import { ARCHITECTURE_PROFILES } from './architectures/index.js';
import { componentSetOf } from '../config/components.js';
import { componentsProfile } from './components/components.js';
import { designProfile } from './design/design.js';
import { appShellProfile } from './app-shell/app-shell.js';
import { presenceProfile } from './presence/presence.js';
import { uiSystemProfile } from './ui-system/ui-system.js';
import { buildNgCommand } from './angular-cli.js';
import { addDependencies } from './edits/package-json.js';
import { pathExists } from './fs.js';
import type { GenerationContext, Stage } from './pipeline.js';
import { RENDERING_PROFILES } from './rendering/index.js';
import { ROUTING_PROFILES } from './routing/index.js';

const PROBE_TIMEOUT_MS = 15_000;
const WORKSPACE_TIMEOUT_MS = 10 * 60_000;
const INSTALL_TIMEOUT_MS = 15 * 60_000;
const INITIAL_COMMIT_MESSAGE = 'chore: initial commit from Angular Starter';

export const validateEnvironment: Stage = {
  id: 'validate-environment',
  title: 'Validating environment',
  async run({ name, options, cwd, targetDir, deps }) {
    if (await pathExists(targetDir)) {
      throw new UsageError(
        `"${name}" already exists in ${cwd}.`,
        'Choose another name or remove the existing folder; Angular Starter never overwrites a project.',
      );
    }
    if (!isSupportedNode(deps.nodeVersion)) {
      throw new UsageError(
        `Node.js v${deps.nodeVersion} is not supported.`,
        `Use a Node.js version that satisfies ${SUPPORTED_NODE_RANGE}.`,
      );
    }
    try {
      await access(cwd, constants.W_OK);
    } catch {
      throw new UsageError(`No write permission in ${cwd}.`);
    }

    await requireTool(
      deps,
      'npx',
      'npx was not found. It ships with npm and is needed to run the Angular CLI.',
    );
    if (options.install) {
      await requireTool(
        deps,
        options.packageManager,
        `The package manager "${options.packageManager}" was not found. Install it or choose another with --package-manager.`,
      );
    }
    if (options.git) {
      await requireTool(deps, 'git', 'git was not found. Install it or use --no-git.');
    }
  },
};

export const createWorkspace: Stage = {
  id: 'create-workspace',
  title: 'Creating Angular workspace',
  pending: 'the Angular CLI is downloaded on first use',
  async run(context) {
    const { command, args } = buildNgCommand(context.name, context.options);
    context.created = true;
    try {
      await context.deps.run(command, args, {
        cwd: context.cwd,
        inherit: context.verbose,
        timeoutMs: WORKSPACE_TIMEOUT_MS,
      });
    } catch (error) {
      throw new RuntimeError(`The Angular CLI could not create the workspace: ${describe(error)}`);
    }
  },
};

export const applyArchitecture: Stage = {
  id: 'apply-architecture',
  title: 'Applying architecture profile',
  enabled: ({ options }) => ARCHITECTURE_PROFILES[options.architecture] !== undefined,
  async run({ name, options, targetDir }) {
    await ARCHITECTURE_PROFILES[options.architecture]?.apply({
      targetDir,
      name,
      prefix: options.prefix,
    });
  },
};

export const applyRouting: Stage = {
  id: 'apply-routing',
  title: 'Adding Angular Starter routing',
  enabled: ({ options }) => ROUTING_PROFILES[options.routing] !== undefined,
  async run({ name, options, targetDir }) {
    await ROUTING_PROFILES[options.routing]?.apply({ targetDir, name, prefix: options.prefix });
  },
};

export const addAngularSsr: Stage = {
  id: 'add-angular-ssr',
  title: 'Adding Angular SSR',
  pending: 'runs ng add @angular/ssr and installs its packages',
  async run({ targetDir, deps, verbose }) {
    try {
      await deps.run(
        'npx',
        [
          '--yes',
          `@angular/cli@${ANGULAR_CLI_VERSION}`,
          'add',
          '@angular/ssr',
          '--skip-confirmation',
        ],
        { cwd: targetDir, inherit: verbose, timeoutMs: INSTALL_TIMEOUT_MS },
      );
    } catch (error) {
      throw new RuntimeError(`ng add @angular/ssr failed: ${describe(error)}`);
    }
  },
};

export const applyRendering: Stage = {
  id: 'apply-rendering',
  title: 'Applying Angular Starter SSR',
  enabled: ({ options }) => RENDERING_PROFILES[options.rendering] !== undefined,
  async run({ name, options, targetDir }) {
    await RENDERING_PROFILES[options.rendering]?.apply({
      targetDir,
      name,
      prefix: options.prefix,
      architecture: options.architecture,
    });
  },
};

export const applyDesign: Stage = {
  id: 'apply-design',
  title: 'Adding the design base',
  enabled: ({ options }) => options.components !== 'none' || options.appShell === 'starter',
  async run({ name, options, targetDir }) {
    await designProfile.apply({ targetDir, name, prefix: options.prefix });
  },
};

export const applyComponents: Stage = {
  id: 'apply-components',
  title: 'Adding native components',
  enabled: ({ options }) => options.components !== 'none',
  async run({ name, options, targetDir }) {
    await componentsProfile.apply({
      targetDir,
      name,
      prefix: options.prefix,
      set: componentSetOf(options),
    });
  },
};

export const applyAppShell: Stage = {
  id: 'apply-app-shell',
  title: 'Adding the application shell',
  enabled: ({ options }) => options.appShell === 'starter',
  async run({ name, options, targetDir }) {
    await appShellProfile.apply({ targetDir, name, prefix: options.prefix });
  },
};

export const applyPresence: Stage = {
  id: 'apply-presence',
  title: 'Adding presence',
  enabled: ({ options }) => options.presence === 'starter',
  async run({ name, options, targetDir }) {
    await presenceProfile.apply({ targetDir, name, prefix: options.prefix });
  },
};

export const applyUiSystem: Stage = {
  id: 'apply-ui-system',
  title: 'Adding the UI System',
  enabled: ({ options }) => options.uiSystem === 'starter',
  async run({ name, options, targetDir }) {
    await uiSystemProfile.apply({ targetDir, name, prefix: options.prefix });
  },
};

export const addIconLibrary: Stage = {
  id: 'add-icon-library',
  title: 'Adding icon library',
  enabled: ({ options }) => ICON_PACKAGES[options.icons] !== undefined,
  async run({ options, targetDir }) {
    const icons = ICON_PACKAGES[options.icons];
    if (!icons) return;
    const manifest = join(targetDir, 'package.json');
    const updated = addDependencies(await readFile(manifest, 'utf8'), {
      [icons.name]: icons.version,
    });
    await writeFile(manifest, updated);
  },
};

export const writeStarterConfig: Stage = {
  id: 'write-starter-config',
  title: 'Writing Angular Starter configuration',
  async run({ options, targetDir }) {
    const config = createProjectConfig(options, {
      cli: CLI_VERSION,
      angularCli: ANGULAR_CLI_VERSION,
    });
    await writeFile(join(targetDir, PROJECT_CONFIG_FILE), serializeProjectConfig(config));
  },
};

/**
 * The arguments of the install. npm and pnpm reach for their local cache before the network, and npm
 * skips the audit and funding requests it would otherwise make after every install (ADR-0016). pnpm never
 * freezes its lockfile: the CLI has just changed `package.json`, and a CI environment turns the freeze on
 * by default. Yarn stays plain: its modern versions reject `--prefer-offline`.
 */
export function installArgsOf(packageManager: string): string[] {
  if (packageManager === 'npm') return ['install', '--no-audit', '--no-fund', '--prefer-offline'];
  if (packageManager === 'pnpm') return ['install', '--prefer-offline', '--no-frozen-lockfile'];
  return ['install'];
}

export const installDependencies: Stage = {
  id: 'install-dependencies',
  title: 'Installing dependencies',
  pending: 'this can take a few minutes',
  enabled: ({ options }) => options.install,
  async run({ options, targetDir, deps, verbose }) {
    try {
      await deps.run(options.packageManager, installArgsOf(options.packageManager), {
        cwd: targetDir,
        inherit: verbose,
        timeoutMs: INSTALL_TIMEOUT_MS,
      });
    } catch (error) {
      throw new RuntimeError(
        `Dependency installation failed: ${describe(error)}`,
        `The project was created. Run "${options.packageManager} install" inside it to try again.`,
      );
    }
  },
};

export const initGit: Stage = {
  id: 'init-git',
  title: 'Initializing Git repository',
  enabled: ({ options }) => options.git,
  async run({ targetDir, deps, warnings }) {
    await deps.run('git', ['init'], { cwd: targetDir });
    await deps.run('git', ['add', '-A'], { cwd: targetDir });
    try {
      await deps.run('git', ['commit', '-m', INITIAL_COMMIT_MESSAGE], { cwd: targetDir });
    } catch (error) {
      warnings.push(
        `The initial commit could not be created (${describe(error)}). Fix the cause and commit manually.`,
      );
    }
  },
};

export const verifyProject: Stage = {
  id: 'verify-project',
  title: 'Validating generated application',
  async run({ options, targetDir }) {
    const required = [
      'package.json',
      'angular.json',
      join('src', 'main.ts'),
      PROJECT_CONFIG_FILE,
      ...(ARCHITECTURE_PROFILES[options.architecture]?.requiredFiles ?? []),
      ...(ROUTING_PROFILES[options.routing]?.requiredFiles ?? []),
      ...(RENDERING_PROFILES[options.rendering]?.requiredFilesFor(options.architecture) ?? []),
      ...(options.components === 'none' && options.appShell === 'none'
        ? []
        : designProfile.requiredFiles),
      ...(options.appShell === 'starter' ? appShellProfile.requiredFiles : []),
      ...(options.presence === 'starter' ? presenceProfile.requiredFiles : []),
      ...(options.uiSystem === 'starter' ? uiSystemProfile.requiredFiles : []),
      ...(options.components === 'none'
        ? []
        : componentsProfile.requiredFilesFor(componentSetOf(options))),
    ];
    const missing: string[] = [];
    for (const file of required) {
      if (!(await pathExists(join(targetDir, file)))) missing.push(file);
    }
    if (missing.length > 0) {
      throw new RuntimeError(
        `The generated project is incomplete (missing: ${missing.join(', ')}).`,
      );
    }
  },
};

/** Every stage of `as new`, in execution order. */
export const NEW_PROJECT_STAGES: readonly Stage[] = [
  validateEnvironment,
  createWorkspace,
  applyArchitecture,
  applyRouting,
  applyRendering,
  applyDesign,
  applyComponents,
  applyAppShell,
  applyPresence,
  applyUiSystem,
  addIconLibrary,
  writeStarterConfig,
  installDependencies,
  initGit,
  verifyProject,
];

async function requireTool(
  deps: GenerationContext['deps'],
  tool: string,
  message: string,
): Promise<void> {
  try {
    await deps.run(tool, ['--version'], { timeoutMs: PROBE_TIMEOUT_MS });
  } catch {
    throw new UsageError(message);
  }
}

/** The last lines of the child's stderr when there are any, otherwise the error message. */
function describe(error: unknown): string {
  if (error && typeof error === 'object' && 'stderr' in error) {
    const stderr = String((error as { stderr?: unknown }).stderr ?? '').trim();
    if (stderr) return stderr.split('\n').slice(-20).join('\n');
  }
  return error instanceof Error ? error.message : String(error);
}
