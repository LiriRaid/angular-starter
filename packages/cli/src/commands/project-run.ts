import { readFile } from 'node:fs/promises';
import { join } from 'node:path';
import type { ProgramDeps } from '../deps.js';
import { detectPackageManager, findWorkspace } from '../engine/detect.js';
import { pathExists } from '../engine/fs.js';
import { CliError, RuntimeError, UsageError } from '../errors.js';
import type { CliIo } from '../io.js';

export type PackageManager = Awaited<ReturnType<typeof detectPackageManager>>;

/** An Angular workspace that is ready to run the tools of its project: where it is and how it runs them. */
export interface RunnableProject {
  root: string;
  manager: PackageManager;
}

/**
 * The Angular workspace of the folder the command runs in, found from any of its folders, with the package
 * manager of its lockfile. The project does not need to have been created or prepared by Starter Angular,
 * but its dependencies must be installed.
 */
export async function locateProject(io: CliIo): Promise<RunnableProject> {
  const root = await findWorkspace(io.cwd);
  if (root === undefined) {
    throw new UsageError(
      `This is not an Angular workspace: angular.json was not found in ${io.cwd} or its parent folders.`,
      'Run the command inside an Angular project.',
    );
  }
  const manager = await detectPackageManager(root);
  // Yarn Plug'n'Play keeps the packages in a cache and has no node_modules folder.
  const installed =
    (await pathExists(join(root, 'node_modules'))) || (await pathExists(join(root, '.pnp.cjs')));
  if (!installed) {
    throw new UsageError(
      'The dependencies of the project are not installed.',
      `Run "${manager} install" in ${root} and try again.`,
    );
  }
  return { root, manager };
}

/** The scripts of the package.json of the project; none when it has no readable one. */
export async function scriptsOf(root: string): Promise<Readonly<Record<string, unknown>>> {
  const text = await readFile(join(root, 'package.json'), 'utf8').catch(() => undefined);
  try {
    const scripts: unknown = text === undefined ? undefined : JSON.parse(text).scripts;
    return scripts && typeof scripts === 'object' ? (scripts as Record<string, unknown>) : {};
  } catch {
    return {};
  }
}

/**
 * Runs a program of the project through its package manager in the terminal, as that program prints it, and
 * exits with the code it exits with, so a failing test, lint or format check fails a script or a pipeline.
 * `what` names it in the message ("ng test", 'The "lint" script').
 */
export async function runInProject(
  deps: ProgramDeps,
  { root, manager }: RunnableProject,
  args: readonly string[],
  what: string,
): Promise<void> {
  try {
    await deps.run(manager, args, { cwd: root, inherit: true });
  } catch (error) {
    const code =
      error && typeof error === 'object' && 'exitCode' in error
        ? (error as { exitCode?: unknown }).exitCode
        : undefined;
    if (typeof code === 'number' && code > 0) {
      throw new CliError(`${what} finished with exit code ${code}.`, code);
    }
    throw new RuntimeError(
      `${what} could not run: ${error instanceof Error ? error.message : String(error)}`,
    );
  }
}
