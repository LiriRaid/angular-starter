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
import { toolingProfile } from './tooling/tooling.js';
import { uiSystemProfile } from './ui-system/ui-system.js';
import { buildNgAddSsrCommand, buildNgCommand } from './angular-cli.js';
import { addDependencies } from './edits/package-json.js';
import { pathExists } from './fs.js';
import { refreshProjectReadme, rewritesProjectReadme } from './project-readme.js';
import { skeletonFiles, ssrFiles } from './skeleton.js';
import { applySharedFoundation, planSharedFoundation } from './shared-foundation.js';
import { refusalOf } from './process.js';
import type { GenerationContext, Stage } from './pipeline.js';
import { RENDERING_PROFILES } from './rendering/index.js';
import { ROUTING_PROFILES } from './routing/index.js';

const PROBE_TIMEOUT_MS = 15_000;
const WORKSPACE_TIMEOUT_MS = 10 * 60_000;
const INSTALL_TIMEOUT_MS = 15 * 60_000;
const FORMAT_TIMEOUT_MS = 5 * 60_000;
/** The file each package manager records the versions it installed in. */
const LOCKFILES = { npm: 'package-lock.json', pnpm: 'pnpm-lock.yaml', yarn: 'yarn.lock' } as const;
const INITIAL_COMMIT_MESSAGE = 'chore: initial commit from Starter Angular';

export const validateEnvironment: Stage = {
  id: 'validate-environment',
  title: 'Validating environment',
  async run({ name, options, cwd, targetDir, deps }) {
    if (await pathExists(targetDir)) {
      throw new UsageError(
        `"${name}" already exists in ${cwd}.`,
        'Choose another name or remove the existing folder; Starter Angular never overwrites a project.',
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
  async plan({ options }, files) {
    for (const file of skeletonFiles(options)) await files.write(file);
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
  async plan({ options }, files) {
    await ARCHITECTURE_PROFILES[options.architecture]?.plan(files);
  },
};

/**
 * The architecture of `sa add` (ADR-0022): the structure added to what the project has. It creates what
 * is missing, adapts the files of the Angular skeleton that are still as `ng new` leaves them and leaves
 * every other file alone; what it did and what the developer should review is said after the steps.
 */
export const applyArchitectureToProject: Stage = {
  id: 'apply-architecture',
  title: 'Applying architecture profile',
  async run({ name, options, targetDir, warnings, notes }) {
    const report = await ARCHITECTURE_PROFILES[options.architecture]?.adopt({
      targetDir,
      name,
      prefix: options.prefix,
    });
    if (!report) return;
    if (report.adapted.length > 0) notes?.push(`Adapted: ${report.adapted.join(', ')}.`);
    if (report.removed.length > 0) {
      notes?.push(
        `Removed (Angular's welcome page, no longer used): ${report.removed.join(', ')}.`,
      );
    }
    for (const { file, reason } of report.review) warnings.push(`Review ${file}: ${reason}`);
    notes?.push(
      'Next: "sa generate feature <name>" creates a feature; "sa add routing starter" and "sa add app-shell" add the navigation and the shell.',
    );
  },
  async plan({ options }, files) {
    await ARCHITECTURE_PROFILES[options.architecture]?.planAdoption(files);
  },
};

export const applyRouting: Stage = {
  id: 'apply-routing',
  title: 'Adding Starter Angular routing',
  enabled: ({ options }) => ROUTING_PROFILES[options.routing] !== undefined,
  async run({ name, options, targetDir }) {
    await ROUTING_PROFILES[options.routing]?.apply({ targetDir, name, prefix: options.prefix });
  },
  async plan({ options }, files) {
    await ROUTING_PROFILES[options.routing]?.plan(files);
  },
};

export const addAngularSsr: Stage = {
  id: 'add-angular-ssr',
  title: 'Adding Angular SSR',
  pending: 'runs ng add @angular/ssr and installs its packages',
  async run({ targetDir, deps, verbose }) {
    try {
      const { command, args } = await buildNgAddSsrCommand(targetDir);
      await deps.run(command, args, {
        cwd: targetDir,
        inherit: verbose,
        timeoutMs: INSTALL_TIMEOUT_MS,
      });
    } catch (error) {
      throw new RuntimeError(`ng add @angular/ssr failed: ${describe(error)}`);
    }
  },
  async plan(_context, files) {
    const { created, changed } = ssrFiles();
    for (const file of created) await files.write(file);
    for (const file of changed) await files.edit(file);
  },
};

export const applyRendering: Stage = {
  id: 'apply-rendering',
  title: 'Applying Starter Angular SSR',
  enabled: ({ options }) => RENDERING_PROFILES[options.rendering] !== undefined,
  async run({ name, options, targetDir }) {
    await RENDERING_PROFILES[options.rendering]?.apply({
      targetDir,
      name,
      prefix: options.prefix,
      architecture: options.architecture,
    });
  },
  async plan({ options }, files) {
    await RENDERING_PROFILES[options.rendering]?.plan(files, options.architecture);
  },
};

export const applySharedFolders: Stage = {
  id: 'apply-shared-folders',
  title: 'Preparing shared and core for the components',
  // A project with an architecture of the starter has them already.
  enabled: ({ options }) =>
    ARCHITECTURE_PROFILES[options.architecture] === undefined && options.components !== 'none',
  async run({ targetDir }) {
    await applySharedFoundation(targetDir);
  },
  async plan(_context, files) {
    await planSharedFoundation(files);
  },
};

export const applyDesign: Stage = {
  id: 'apply-design',
  title: 'Adding the design base',
  enabled: ({ options }) => options.components !== 'none' || options.appShell === 'starter',
  async run({ name, options, targetDir }) {
    await designProfile.apply({ targetDir, name, prefix: options.prefix });
  },
  async plan(_context, files) {
    await designProfile.plan(files);
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
  async plan({ options }, files) {
    await componentsProfile.plan(files, componentSetOf(options));
  },
};

export const applyAppShell: Stage = {
  id: 'apply-app-shell',
  title: 'Adding the application shell',
  enabled: ({ options }) => options.appShell === 'starter',
  async run({ name, options, targetDir }) {
    await appShellProfile.apply({ targetDir, name, prefix: options.prefix });
  },
  async plan({ options }, files) {
    await appShellProfile.plan(files, options.prefix);
  },
};

export const applyPresence: Stage = {
  id: 'apply-presence',
  title: 'Adding presence',
  enabled: ({ options }) => options.presence === 'starter',
  async run({ name, options, targetDir }) {
    await presenceProfile.apply({ targetDir, name, prefix: options.prefix });
  },
  async plan(_context, files) {
    await presenceProfile.plan(files);
  },
};

export const applyUiSystem: Stage = {
  id: 'apply-ui-system',
  title: 'Adding the UI System',
  enabled: ({ options }) => options.uiSystem === 'starter',
  async run({ name, options, targetDir }) {
    await uiSystemProfile.apply({ targetDir, name, prefix: options.prefix });
  },
  async plan(_context, files) {
    await uiSystemProfile.plan(files);
  },
};

/**
 * The catalog of a UI System that is already in the project, brought up to the components it has now
 * (ADR-0024): rewritten when its files are as the CLI left them, and only named when the developer edited
 * them.
 */
export const updateUiSystemCatalog: Stage = {
  id: 'update-ui-system-catalog',
  title: 'Completing the UI System catalog',
  async run({ name, options, targetDir, warnings, notes }) {
    const report = await uiSystemProfile.update({ targetDir, name, prefix: options.prefix });
    if (report.status === 'updated') {
      notes?.push(
        `The UI System catalog now shows ${report.added.map((id) => `sa-${id}`).join(', ')}.`,
      );
    } else if (report.status === 'edited') {
      warnings.push(
        `The UI System catalog was not changed: ${report.edited.join(', ')} ${report.edited.length === 1 ? 'was' : 'were'} edited. It lacks ${report.missing.map((id) => `sa-${id}`).join(', ')}: add their entries by hand, or restore ${report.edited.length === 1 ? 'that file' : 'those files'} and run "sa add ui-system" again.`,
      );
    }
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
  async plan(_context, files) {
    await files.edit('package.json');
  },
};

/**
 * Lint and format for every project (ADR-0027): the ESLint configuration with Angular's rules, its
 * packages and the lint and format scripts. A project that has an ESLint setup of its own keeps it.
 */
export const applyTooling: Stage = {
  id: 'apply-tooling',
  title: 'Adding ESLint and the lint and format scripts',
  async run({ options, targetDir, notes, created }) {
    const report = await toolingProfile.apply({
      targetDir,
      prefix: options.prefix,
      style: options.style,
    });
    if (report.eslint === 'kept') {
      notes?.push(
        `Kept your ESLint setup (${report.found}): no ESLint packages and no lint scripts were added; the format scripts were.`,
      );
    }
    if (!options.install) {
      const manager = options.packageManager;
      // A new project is formatted once its packages are there; tooling added to a project leaves its code alone.
      notes?.push(
        created
          ? `Prettier is not installed yet: after "${manager} install", run "${manager} run format" so the generated code follows the Prettier configuration.`
          : `Run "${manager} install" to install the new packages.`,
      );
    }
  },
  async plan(_context, files) {
    await toolingProfile.plan(files);
  },
};

/**
 * The code the stages wrote does not follow the Prettier configuration of `ng new` (its width and trailing
 * commas), so the project is formatted once, right after its dependencies are installed and before the
 * first commit: `format:check` starts green. A failure is a warning, the project is complete without it.
 */
export const formatProject: Stage = {
  id: 'format-project',
  title: 'Formatting the generated code',
  enabled: ({ options }) => options.install,
  async run({ options, targetDir, deps, verbose, warnings }) {
    try {
      await deps.run(options.packageManager, ['run', 'format'], {
        cwd: targetDir,
        inherit: verbose,
        timeoutMs: FORMAT_TIMEOUT_MS,
      });
    } catch (error) {
      warnings.push(
        `The generated code could not be formatted (${describe(error)}). Run "${options.packageManager} run format" inside the project.`,
      );
    }
  },
};

/**
 * The README of the project says what it has (ADR-0024): the one `ng new` writes becomes a Starter Angular
 * one, a README with the block gets only the block rewritten, and the developer's own README is left alone.
 */
export const writeProjectReadme: Stage = {
  id: 'write-project-readme',
  title: 'Describing the project in its README',
  async run({ name, options, targetDir }) {
    await refreshProjectReadme({ targetDir, name, options });
  },
  async plan({ targetDir }, files) {
    if (!(await files.exists('README.md'))) return;
    // The one `ng new` writes is a planned file; a README of the project is rewritten only when it is the starter's.
    const current = await readFile(join(targetDir, 'README.md'), 'utf8').catch(() => undefined);
    if (current === undefined || rewritesProjectReadme(current)) await files.edit('README.md');
  },
};

export const writeStarterConfig: Stage = {
  id: 'write-starter-config',
  title: 'Writing Starter Angular configuration',
  async run({ options, targetDir }) {
    const config = createProjectConfig(options, {
      cli: CLI_VERSION,
      angularCli: ANGULAR_CLI_VERSION,
    });
    await writeFile(join(targetDir, PROJECT_CONFIG_FILE), serializeProjectConfig(config));
  },
  async plan(_context, files) {
    await files.write(PROJECT_CONFIG_FILE);
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
  async plan({ options }, files) {
    await files.write(LOCKFILES[options.packageManager]);
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
      ...toolingProfile.requiredFiles,
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

/** Every stage of `sa new`, in execution order. */
export const NEW_PROJECT_STAGES: readonly Stage[] = [
  validateEnvironment,
  createWorkspace,
  applyArchitecture,
  applyRouting,
  applyRendering,
  applySharedFolders,
  applyDesign,
  applyComponents,
  applyAppShell,
  applyPresence,
  applyUiSystem,
  addIconLibrary,
  applyTooling,
  writeProjectReadme,
  writeStarterConfig,
  installDependencies,
  formatProject,
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
  } catch (error) {
    const refusal = refusalOf(error);
    throw new UsageError(
      refusal ? `"${tool}" could not run: ${refusal}` : message,
      refusal ? 'Fix that, or choose another tool with --package-manager.' : undefined,
    );
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
