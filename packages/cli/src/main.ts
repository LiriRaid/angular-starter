import { CommanderError } from 'commander';
import { createDefaultDeps, type ProgramDeps } from './deps.js';
import { CancelledError, CliError, isPromptCancellation } from './errors.js';
import { createProcessIo, println, type CliIo } from './io.js';
import { createProgram } from './program.js';

/** Runs the CLI and returns the process exit code. It never calls `process.exit`. */
export async function run(
  argv: readonly string[],
  io: CliIo = createProcessIo(),
  overrides: Partial<ProgramDeps> = {},
): Promise<number> {
  const program = createProgram(io, { ...createDefaultDeps(), ...overrides });
  try {
    await program.parseAsync(argv.length === 0 ? ['--help'] : [...argv], { from: 'user' });
    return 0;
  } catch (error) {
    return reportError(error, io);
  }
}

function reportError(error: unknown, io: CliIo): number {
  if (error instanceof CommanderError) {
    // Commander already printed its own message (help, version or a usage error).
    return error.exitCode === 0 ? 0 : 2;
  }
  if (isPromptCancellation(error) || error instanceof CancelledError) {
    println(io.stderr, 'Cancelled.');
    return 130;
  }
  if (error instanceof CliError) {
    println(io.stderr, `error: ${error.message}`);
    if (error.hint) println(io.stderr, error.hint);
    return error.exitCode;
  }
  const message = error instanceof Error ? error.message : String(error);
  println(io.stderr, `error: unexpected failure: ${message}`);
  if (io.env['AS_DEBUG'] && error instanceof Error && error.stack) println(io.stderr, error.stack);
  return 1;
}
