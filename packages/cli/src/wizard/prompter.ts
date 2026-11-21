import { styleText } from 'node:util';

/** Thrown by a prompter when the user presses Esc: the wizard asks the question before this one. */
export class BackRequested extends Error {
  constructor() {
    super('The user asked to go back');
    this.name = 'BackRequested';
  }
}

/** What every question can say about going back. */
interface Backable {
  /** The prompt listens to Esc, shows it and throws `BackRequested`; the first question has none before it. */
  canGoBack?: boolean;
}

export interface Choice<T extends string> {
  value: T;
  name: string;
  description?: string;
  /** Listed but not selectable; the text is shown next to the choice, for example "Under construction". */
  disabled?: string;
}

export interface CheckboxChoice<T extends string> extends Choice<T> {
  /** Ticked when the question opens. */
  checked?: boolean;
}

export interface InputQuestion extends Backable {
  /** Stable identifier of the question, used by tests and logs; never shown to the user. */
  name: string;
  message: string;
  default?: string;
  /** Returns a message when the value is invalid, or `undefined` when it is valid. */
  validate?: (value: string) => string | undefined;
}

export interface SelectQuestion<T extends string> extends Backable {
  name: string;
  message: string;
  choices: readonly Choice<T>[];
  default?: T;
}

export interface CheckboxQuestion<T extends string> extends Backable {
  name: string;
  message: string;
  choices: readonly CheckboxChoice<T>[];
}

export interface ConfirmQuestion extends Backable {
  name: string;
  message: string;
  default?: boolean;
}

/**
 * The only thing the wizard knows about the terminal, so it can be replaced in tests. A question with
 * `canGoBack` rejects with `BackRequested` when the user presses Esc.
 */
export interface Prompter {
  input(question: InputQuestion): Promise<string>;
  select<T extends string>(question: SelectQuestion<T>): Promise<T>;
  /** Several answers at once: what ends ticked, in the order of the choices. */
  checkbox<T extends string>(question: CheckboxQuestion<T>): Promise<T[]>;
  confirm(question: ConfirmQuestion): Promise<boolean>;
}

/** The terminal the prompts use: the process's own, unless a test gives others. */
export interface TerminalStreams {
  input?: NodeJS.ReadableStream;
  output?: NodeJS.WritableStream;
}

/** What `@inquirer/prompts` takes as the second argument of a prompt. */
interface PromptContext extends TerminalStreams {
  signal?: AbortSignal;
  clearPromptOnDone?: boolean;
}

type KeyHelp = [key: string, action: string][];

/** `esc back` joins the keys that the help line of a list already shows. */
const LIST_THEME = {
  style: {
    keysHelpTip: (keys: KeyHelp) =>
      [...keys, ['esc', 'back']]
        .map(([key, action]) => `${styleText('bold', key ?? '')} ${styleText('dim', action ?? '')}`)
        .join(styleText('dim', ' • ')),
  },
};

/** A question of one line has no help line: a dim hint follows its message while it is open. */
const LINE_THEME = {
  style: {
    message: (text: string, status: string) =>
      status === 'done'
        ? styleText('bold', text)
        : `${styleText('bold', text)} ${styleText('dim', '(esc to go back)')}`,
  },
};

/** Prompts rendered by `@inquirer/prompts`, loaded lazily so `as --help` stays fast. */
export function createInquirerPrompter(streams: TerminalStreams = {}): Prompter {
  const terminal = streams.input ?? process.stdin;

  /**
   * Runs a prompt that listens to Esc while it is open: the key aborts it, clears what it drew and
   * turns the abort into `BackRequested`. A question that cannot go back runs as it is.
   */
  async function ask<T>(
    canGoBack: boolean | undefined,
    prompt: (context: PromptContext) => Promise<T>,
  ): Promise<T> {
    const context: PromptContext = { ...streams };
    if (!canGoBack) return prompt(context);

    const controller = new AbortController();
    let wentBack = false;
    const onKey = (_text: unknown, key: { name?: string } | undefined): void => {
      if (key?.name !== 'escape' || wentBack) return;
      wentBack = true;
      // Read by the prompt when it settles, so the question that was left does not stay on screen.
      context.clearPromptOnDone = true;
      controller.abort();
    };
    context.signal = controller.signal;
    terminal.on('keypress', onKey);
    try {
      return await prompt(context);
    } catch (error) {
      if (wentBack) throw new BackRequested();
      throw error;
    } finally {
      terminal.off('keypress', onKey);
    }
  }

  return {
    async input(question) {
      const { input } = await import('@inquirer/prompts');
      const answer = await ask(question.canGoBack, (context) =>
        input(
          {
            message: question.message,
            default: question.default,
            validate: (value) => question.validate?.(value.trim()) ?? true,
            ...(question.canGoBack ? { theme: LINE_THEME } : {}),
          },
          context,
        ),
      );
      return answer.trim();
    },
    async select<T extends string>(question: SelectQuestion<T>) {
      const { select } = await import('@inquirer/prompts');
      return ask(question.canGoBack, (context) =>
        select<T>(
          {
            message: question.message,
            default: question.default,
            choices: question.choices.map((choice) => ({
              value: choice.value,
              name: choice.name,
              description: choice.description,
              disabled: choice.disabled,
            })),
            ...(question.canGoBack ? { theme: LIST_THEME } : {}),
          },
          context,
        ),
      );
    },
    async checkbox<T extends string>(question: CheckboxQuestion<T>) {
      const { checkbox } = await import('@inquirer/prompts');
      return ask(question.canGoBack, (context) =>
        checkbox<T>(
          {
            message: question.message,
            choices: question.choices.map((choice) => ({
              value: choice.value,
              name: choice.name,
              description: choice.description,
              checked: choice.checked ?? false,
            })),
            pageSize: 14,
            ...(question.canGoBack ? { theme: LIST_THEME } : {}),
          },
          context,
        ),
      );
    },
    async confirm(question) {
      const { confirm } = await import('@inquirer/prompts');
      return ask(question.canGoBack, (context) =>
        confirm(
          {
            message: question.message,
            default: question.default,
            ...(question.canGoBack ? { theme: LINE_THEME } : {}),
          },
          context,
        ),
      );
    },
  };
}
