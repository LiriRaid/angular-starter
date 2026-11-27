import type { ProgramDeps } from '../deps.js';
import type { CliIo } from '../io.js';
import { locateProject, runInProject, type PackageManager } from './project-run.js';

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
  const project = await locateProject(io);
  await runInProject(
    deps,
    project,
    [...RUN_LOCAL_BIN[project.manager], 'test', ...args],
    'ng test',
  );
}
