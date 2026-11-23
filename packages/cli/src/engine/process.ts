import { execa } from 'execa';

export interface CommandResult {
  stdout: string;
  stderr: string;
}

export interface RunOptions {
  cwd?: string;
  timeoutMs?: number;
  /** Connect the child process to this terminal instead of capturing its output. */
  inherit?: boolean;
}

export type CommandRunner = (
  command: string,
  args: readonly string[],
  options?: RunOptions,
) => Promise<CommandResult>;

/**
 * The first line a program printed to stderr when it started and then failed, or undefined when it
 * could not be started at all (a program that is not installed prints nothing). It tells "yarn is not
 * installed" from "yarn is installed and refuses to run" (corepack does so inside a folder whose
 * package.json names another package manager).
 */
export function refusalOf(error: unknown): string | undefined {
  if (error && typeof error === 'object' && 'stderr' in error) {
    const stderr = String((error as { stderr?: unknown }).stderr ?? '').trim();
    return stderr.split('\n')[0]?.trim() || undefined;
  }
  return undefined;
}

/** Runs a program on any operating system (`.cmd` shims on Windows included). */
export const runCommand: CommandRunner = async (command, args, options = {}) => {
  const result = await execa(command, [...args], {
    cwd: options.cwd,
    timeout: options.timeoutMs,
    stdio: options.inherit ? 'inherit' : ['ignore', 'pipe', 'pipe'],
    windowsHide: true,
  });
  return { stdout: String(result.stdout ?? ''), stderr: String(result.stderr ?? '') };
};
