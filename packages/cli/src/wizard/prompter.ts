export interface Choice<T extends string> {
  value: T;
  name: string;
  description?: string;
}

export interface InputQuestion {
  /** Stable identifier of the question, used by tests and logs; never shown to the user. */
  name: string;
  message: string;
  default?: string;
  /** Returns a message when the value is invalid, or `undefined` when it is valid. */
  validate?: (value: string) => string | undefined;
}

export interface SelectQuestion<T extends string> {
  name: string;
  message: string;
  choices: readonly Choice<T>[];
  default?: T;
}

export interface ConfirmQuestion {
  name: string;
  message: string;
  default?: boolean;
}

/** The only thing the wizard knows about the terminal, so it can be replaced in tests. */
export interface Prompter {
  input(question: InputQuestion): Promise<string>;
  select<T extends string>(question: SelectQuestion<T>): Promise<T>;
  confirm(question: ConfirmQuestion): Promise<boolean>;
}

/** Prompts rendered by `@inquirer/prompts`, loaded lazily so `as --help` stays fast. */
export function createInquirerPrompter(): Prompter {
  return {
    async input(question) {
      const { input } = await import('@inquirer/prompts');
      const answer = await input({
        message: question.message,
        default: question.default,
        validate: (value) => question.validate?.(value.trim()) ?? true,
      });
      return answer.trim();
    },
    async select<T extends string>(question: SelectQuestion<T>) {
      const { select } = await import('@inquirer/prompts');
      return select<T>({
        message: question.message,
        default: question.default,
        choices: question.choices.map((choice) => ({
          value: choice.value,
          name: choice.name,
          description: choice.description,
        })),
      });
    },
    async confirm(question) {
      const { confirm } = await import('@inquirer/prompts');
      return confirm({ message: question.message, default: question.default });
    },
  };
}
