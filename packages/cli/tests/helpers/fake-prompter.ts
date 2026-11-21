import type { Prompter } from '../../src/wizard/prompter.js';

export interface AskedQuestion {
  kind: 'input' | 'select' | 'checkbox' | 'confirm';
  name: string;
  message: string;
  default?: unknown;
  choices?: string[];
  /** What the user reads for each choice, and the line shown while it is highlighted. */
  names?: string[];
  descriptions?: (string | undefined)[];
  /** The values that are listed but cannot be chosen, with the reason shown next to them. */
  disabled?: Record<string, string>;
  /** The values of a checkbox that start ticked. */
  checked?: string[];
}

/** Answers are consumed in order; an `Error` answer is thrown, like Ctrl+C in a real prompt. */
export function createFakePrompter(answers: unknown[]): {
  prompter: Prompter;
  asked: AskedQuestion[];
} {
  const asked: AskedQuestion[] = [];
  const queue = [...answers];

  function next(question: AskedQuestion): unknown {
    asked.push(question);
    if (queue.length === 0) throw new Error(`No answer prepared for "${question.name}"`);
    const answer = queue.shift();
    if (answer instanceof Error) throw answer;
    return answer;
  }

  const prompter: Prompter = {
    input: async (question) =>
      next({
        kind: 'input',
        name: question.name,
        message: question.message,
        default: question.default,
      }) as string,
    select: async <T extends string>(
      question: Parameters<Prompter['select']>[0] & { default?: T },
    ) =>
      next({
        kind: 'select',
        name: question.name,
        message: question.message,
        default: question.default,
        choices: question.choices.map((choice) => choice.value),
        names: question.choices.map((choice) => choice.name),
        descriptions: question.choices.map((choice) => choice.description),
        disabled: Object.fromEntries(
          question.choices.flatMap((choice) =>
            choice.disabled === undefined ? [] : [[choice.value, choice.disabled]],
          ),
        ),
      }) as T,
    checkbox: async <T extends string>(question: Parameters<Prompter['checkbox']>[0] & { _?: T }) =>
      next({
        kind: 'checkbox',
        name: question.name,
        message: question.message,
        choices: question.choices.map((choice) => choice.value),
        names: question.choices.map((choice) => choice.name),
        descriptions: question.choices.map((choice) => choice.description),
        checked: question.choices.filter((choice) => choice.checked).map((choice) => choice.value),
      }) as T[],
    confirm: async (question) =>
      next({
        kind: 'confirm',
        name: question.name,
        message: question.message,
        default: question.default,
      }) as boolean,
  };
  return { prompter, asked };
}
