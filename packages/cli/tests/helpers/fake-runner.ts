import { mkdir, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import type { CommandRunner } from '../../src/engine/process.js';

export interface RecordedCall {
  command: string;
  args: string[];
  cwd?: string;
}

export interface FakeRunnerOptions {
  /** Return an error to make a call fail. */
  failOn?: (call: RecordedCall) => Error | undefined;
}

/**
 * Records every call and imitates the one side effect the engine relies on: `ng new <name>` creating
 * the workspace folder with the files the final verification looks for.
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

    const newIndex = args.indexOf('new');
    if (command === 'npx' && newIndex >= 0 && runOptions?.cwd) {
      const name = args[newIndex + 1] ?? 'unnamed';
      const dir = join(runOptions.cwd, name);
      await mkdir(join(dir, 'src'), { recursive: true });
      await writeFile(join(dir, 'package.json'), '{}\n');
      await writeFile(join(dir, 'angular.json'), '{}\n');
      await writeFile(join(dir, 'src', 'main.ts'), '\n');
    }
    return { stdout: args.includes('--version') ? '1.0.0\n' : '', stderr: '' };
  };
  return { run, calls };
}
