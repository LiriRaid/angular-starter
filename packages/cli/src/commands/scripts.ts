import type { ProgramDeps } from '../deps.js';
import { UsageError } from '../errors.js';
import type { CliIo } from '../io.js';
import { locateProject, runInProject, scriptsOf, type PackageManager } from './project-run.js';

/** How each package manager hands arguments to a script: npm needs `--` before them, the others do not. */
function scriptArgs(manager: PackageManager, script: string, args: readonly string[]): string[] {
  return manager === 'npm' && args.length > 0
    ? ['run', script, '--', ...args]
    : ['run', script, ...args];
}

/**
 * Runs a script of the project (ADR-0028). `flag` picks `variant` instead of `script`: `sa lint --fix` is the
 * script `lint:fix` and `sa format --check` is `format:check`, and the flag is not handed over. Every other
 * argument goes to the script. The project does not need to have been made by Starter Angular; a project
 * without the script is told how to get it.
 */
async function runScript(
  io: CliIo,
  deps: ProgramDeps,
  args: readonly string[],
  { script, variant, flag }: { script: string; variant: string; flag: string },
): Promise<void> {
  const project = await locateProject(io);
  const chosen = args.includes(flag) ? variant : script;
  if ((await scriptsOf(project.root))[chosen] === undefined) {
    throw new UsageError(
      `This project has no "${chosen}" script in its package.json.`,
      'Run "sa add tooling" to add ESLint, Prettier and the lint and format scripts.',
    );
  }
  const rest = args.filter((arg) => arg !== flag);
  await runInProject(
    deps,
    project,
    scriptArgs(project.manager, chosen, rest),
    `The "${chosen}" script`,
  );
}

/** `sa lint [--fix] [args...]`: the `lint` script of the project, or `lint:fix` with `--fix`. */
export function lintCommand(io: CliIo, deps: ProgramDeps, args: readonly string[]): Promise<void> {
  return runScript(io, deps, args, { script: 'lint', variant: 'lint:fix', flag: '--fix' });
}

/** `sa format [--check] [args...]`: the `format` script of the project, or `format:check` with `--check`. */
export function formatCommand(
  io: CliIo,
  deps: ProgramDeps,
  args: readonly string[],
): Promise<void> {
  return runScript(io, deps, args, {
    script: 'format',
    variant: 'format:check',
    flag: '--check',
  });
}
