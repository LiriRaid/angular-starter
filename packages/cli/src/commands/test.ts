import { join } from 'node:path';
import type { ProgramDeps } from '../deps.js';
import { detectPackageManager, findWorkspace } from '../engine/detect.js';
import { pathExists } from '../engine/fs.js';
import { CliError, RuntimeError, UsageError } from '../errors.js';
import type { CliIo } from '../io.js';

type PackageManager = Awaited<ReturnType<typeof detectPackageManager>>;

/** How each package manager runs the `ng` its project has installed, before the arguments of `ng`. */
const RUN_LOCAL_BIN: Readonly<Record<PackageManager, readonly string[]>> = {
  pnpm: ['exec', 'ng'],
  npm: ['exec', '--', 'ng'],
  yarn: ['ng'],
};

/**
 * `sa test` (ADR-0027): the tests of the project, which are `ng test` whoever created it. It finds the
 * Angular workspace from any of its folders, runs the `ng` the project has installed through the package
 * manager of its lockfile, and hands over every argument and option as they were typed. The output goes to
 * the terminal as `ng test` prints it, and the command exits with the code `ng test` exits with.
 */
export async function testCommand(
  io: CliIo,
  deps: ProgramDeps,
  args: readonly string[],
): Promise<void> {
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

  try {
    await deps.run(manager, [...RUN_LOCAL_BIN[manager], 'test', ...args], {
      cwd: root,
      inherit: true,
    });
  } catch (error) {
    const code =
      error && typeof error === 'object' && 'exitCode' in error
        ? (error as { exitCode?: unknown }).exitCode
        : undefined;
    if (typeof code === 'number' && code > 0) {
      throw new CliError(`ng test finished with exit code ${code}.`, code);
    }
    throw new RuntimeError(
      `ng test could not run: ${error instanceof Error ? error.message : String(error)}`,
    );
  }
}
