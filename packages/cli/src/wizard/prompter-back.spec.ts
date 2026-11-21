import { PassThrough } from 'node:stream';
import { describe, expect, it } from 'vitest';
import { BackRequested, createInquirerPrompter } from './prompter.js';

/** Esc alone is held by the terminal until it is clear it does not start an arrow key. */
const ESC_DELAY = 700;
const sleep = (ms: number): Promise<void> => new Promise((resolve) => setTimeout(resolve, ms));

/** A terminal made of two streams, so the real prompts can be typed into. */
function terminal(): {
  prompter: ReturnType<typeof createInquirerPrompter>;
  type: (keys: string) => Promise<void>;
  screen: () => string;
  input: PassThrough;
} {
  const input = new PassThrough();
  const output = new PassThrough();
  let screen = '';
  output.on('data', (chunk: Buffer) => (screen += chunk.toString()));
  return {
    prompter: createInquirerPrompter({ input, output }),
    type: async (keys) => {
      input.write(keys);
      await sleep(keys === '\x1b' ? ESC_DELAY : 50);
    },
    screen: () => screen,
    input,
  };
}

const CHOICES = [
  { value: 'a', name: 'Alpha' },
  { value: 'b', name: 'Beta' },
] as const;

describe('createInquirerPrompter: going back with Esc', () => {
  it('goes back from a select, and says so in its help line', async () => {
    const { prompter, type, screen, input } = terminal();
    const asked = prompter.select({
      name: 'x',
      message: 'Pick',
      choices: CHOICES,
      canGoBack: true,
    });
    const outcome = asked.catch((error: unknown) => error);
    await sleep(50);
    expect(screen()).toContain('esc back');
    const drawn = screen().split('\u001b[1A').length;
    await type('\x1b');
    expect(await outcome).toBeInstanceOf(BackRequested);
    expect(input.listenerCount('keypress')).toBe(0);
    // The question that was left is erased line by line, not left on screen.
    expect(screen().split('\u001b[1A').length).toBeGreaterThan(drawn);
  });

  it('goes back from a checkbox, and says so in its help line', async () => {
    const { prompter, type, screen } = terminal();
    const outcome = prompter
      .checkbox({ name: 'x', message: 'Tick', choices: CHOICES, canGoBack: true })
      .catch((error: unknown) => error);
    await sleep(50);
    expect(screen()).toContain('esc');
    await type('\x1b');
    expect(await outcome).toBeInstanceOf(BackRequested);
  });

  it('goes back from an input and a confirmation, with the hint after the message', async () => {
    const text = terminal();
    const input = text.prompter
      .input({ name: 'x', message: 'Name:', canGoBack: true })
      .catch((error: unknown) => error);
    await sleep(50);
    expect(text.screen()).toContain('esc to go back');
    await text.type('\x1b');
    expect(await input).toBeInstanceOf(BackRequested);

    const yes = terminal();
    const confirm = yes.prompter
      .confirm({ name: 'y', message: 'Sure?', canGoBack: true })
      .catch((error: unknown) => error);
    await sleep(50);
    expect(yes.screen()).toContain('esc to go back');
    await yes.type('\x1b');
    expect(await confirm).toBeInstanceOf(BackRequested);
  });

  it('keeps answering when the answer is given, with no hint on the answered line', async () => {
    const { prompter, type, screen } = terminal();
    const asked = prompter.input({ name: 'x', message: 'Name:', default: 'app', canGoBack: true });
    await sleep(50);
    await type('\r');
    expect(await asked).toBe('app');
    // The last frame drawn, after the line is erased once more, is the answered one.
    const answered = screen().split('[2K').at(-1) ?? '';
    expect(answered).toContain('Name: app');
    expect(answered).not.toContain('esc to go back');
  });

  it('ignores Esc when the question cannot go back, and shows no hint', async () => {
    const { prompter, type, screen } = terminal();
    const asked = prompter.select({ name: 'x', message: 'Pick', choices: CHOICES });
    await sleep(50);
    await type('\x1b');
    await type('\r');
    expect(await asked).toBe('a');
    expect(screen()).not.toContain('esc');
  });
});
