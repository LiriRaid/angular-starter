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
