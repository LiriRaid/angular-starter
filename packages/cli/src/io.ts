/** Everything the CLI needs from its surroundings, so commands can be tested without a terminal. */
export interface CliIo {
  stdout(text: string): void;
  stderr(text: string): void;
  readonly cwd: string;
  readonly env: NodeJS.ProcessEnv;
  /** True when prompts can be shown: stdin and stdout are terminals and this is not a CI run. */
  readonly interactive: boolean;
  readonly color: boolean;
  /** Width of the terminal; absent when the output is not one (a pipe, a file, a test). */
  readonly columns?: number;
}

export function createProcessIo(): CliIo {
  const env = process.env;
  const isTerminal = Boolean(process.stdin.isTTY && process.stdout.isTTY);
  return {
    stdout: (text) => {
      process.stdout.write(text);
    },
    stderr: (text) => {
      process.stderr.write(text);
    },
    cwd: process.cwd(),
    env,
    interactive: isTerminal && !isCi(env),
    color: Boolean(process.stdout.isTTY) && env['NO_COLOR'] === undefined && env['TERM'] !== 'dumb',
    ...(process.stdout.isTTY && process.stdout.columns ? { columns: process.stdout.columns } : {}),
  };
}

function isCi(env: NodeJS.ProcessEnv): boolean {
  const value = env['CI'];
  return value !== undefined && value !== '' && value !== '0' && value.toLowerCase() !== 'false';
}

export function println(write: (text: string) => void, text = ''): void {
  write(`${text}\n`);
}
