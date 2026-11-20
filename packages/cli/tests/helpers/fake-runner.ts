import { join } from 'node:path';
import type { CommandRunner } from '../../src/engine/process.js';
import { writeGeneratedWorkspace } from './generated-workspace.js';

export interface RecordedCall {
  command: string;
  args: string[];
  cwd?: string;
}

export interface FakeRunnerOptions {
  /** Return an error to make a call fail. */
  failOn?: (call: RecordedCall) => Error | undefined;
  /** Replaces (or, with null, removes) files of the workspace `ng new` writes. */
  files?: Readonly<Record<string, string | null>>;
  /** Runs after a call is recorded, to imitate what the real tool does to the project. */
  onRun?: (call: RecordedCall) => void | Promise<void>;
}

/**
 * Records every call and imitates the one side effect the engine relies on: `ng new <name>` creating
 * the workspace folder with the files the engine reads and edits.
 */
export function createFakeRunner(options: FakeRunnerOptions = {}): {
  run: CommandRunner;
  calls: RecordedCall[];
} {
  const calls: RecordedCall[] = [];
  const run: CommandRunner = async (command, args, runOptions) => {
    const call: RecordedCall = { command, args: [...args], cwd: runOptions?.cwd };
    calls.push(call);

    const failure = options.failOn?.(call);
    if (failure) throw failure;
    await options.onRun?.(call);

    const newIndex = args.indexOf('new');
    if (command === 'npx' && newIndex >= 0 && runOptions?.cwd) {
      const name = args[newIndex + 1] ?? 'unnamed';
      await writeGeneratedWorkspace(join(runOptions.cwd, name), options.files);
    }
    return { stdout: args.includes('--version') ? '1.0.0\n' : '', stderr: '' };
  };
  return { run, calls };
}
