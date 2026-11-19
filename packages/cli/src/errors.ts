/** Base class for errors that are reported to the user without a stack trace. */
export class CliError extends Error {
  constructor(
    message: string,
    readonly exitCode: number,
    readonly hint?: string,
  ) {
    super(message);
    this.name = new.target.name;
  }
}

/** Invalid command line, invalid configuration or a precondition the user can fix (exit code 2). */
export class UsageError extends CliError {
  constructor(message: string, hint?: string) {
    super(message, 2, hint);
  }
}

/** An operation failed while running (exit code 1). */
export class RuntimeError extends CliError {
  constructor(message: string, hint?: string) {
    super(message, 1, hint);
  }
}

/** The user cancelled an interactive prompt (exit code 130). */
export class CancelledError extends CliError {
  constructor() {
    super('Cancelled.', 130);
  }
}

/** `@inquirer/prompts` throws an error named `ExitPromptError` on Ctrl+C. */
export function isPromptCancellation(error: unknown): boolean {
  return error instanceof Error && error.name === 'ExitPromptError';
}
