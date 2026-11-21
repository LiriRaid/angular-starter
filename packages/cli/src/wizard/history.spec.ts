import { describe, expect, it } from 'vitest';
import { History, Rewind } from './history.js';
import { BackRequested } from './prompter.js';

/** A flow of three questions that records what is really asked, like a pass of the wizard. */
function flowOf(history: History, answers: Record<string, string[]>) {
  const asked: { name: string; previous: unknown; canGoBack: boolean }[] = [];
  async function pass(): Promise<string[]> {
    history.begin();
    const result: string[] = [];
    for (const name of ['one', 'two', 'three']) {
      result.push(
        await history.turn<string>({
          name,
          title: name.toUpperCase(),
          summarize: (answer) => `<${answer}>`,
          ask: async (previous, canGoBack) => {
            asked.push({ name, previous, canGoBack });
            const next = answers[name]?.shift();
            if (next === 'BACK') throw new BackRequested();
            return next ?? `${name}!`;
          },
        }),
      );
    }
    return result;
  }
  return { asked, pass };
}

describe('History', () => {
  it('asks each question once, and only the first one cannot go back', async () => {
    const history = new History();
    const { asked, pass } = flowOf(history, {});
    expect(await pass()).toEqual(['one!', 'two!', 'three!']);
    expect(asked.map((question) => question.canGoBack)).toEqual([false, true, true]);
    expect(history.answered).toEqual([
      { name: 'one', title: 'ONE', summary: '<one!>' },
      { name: 'two', title: 'TWO', summary: '<two!>' },
      { name: 'three', title: 'THREE', summary: '<three!>' },
    ]);
  });

  it('turns going back into a rewind to the question before', async () => {
    const history = new History();
    const { pass } = flowOf(history, { three: ['BACK'] });
    const failure = await pass().catch((error: unknown) => error);
    expect(failure).toBeInstanceOf(Rewind);
    expect(failure).toMatchObject({ to: 1 });
  });

  it('replays the answers before the rewind and asks again the one it stopped on, with its answer', async () => {
    const history = new History();
    const { asked, pass } = flowOf(history, { three: ['BACK'], two: ['two!', 'again'] });
    await pass().catch((error: unknown) => {
      expect(error).toBeInstanceOf(Rewind);
      history.rewind((error as Rewind).to);
    });
    asked.length = 0;

    expect(await pass()).toEqual(['one!', 'again', 'three!']);
    // Question one answered itself from the history; two came back with what it said before.
    expect(asked).toEqual([
      { name: 'two', previous: 'two!', canGoBack: true },
      { name: 'three', previous: undefined, canGoBack: true },
    ]);
  });

  it('does not rewind from the first question', async () => {
    const history = new History();
    const { pass } = flowOf(history, { one: ['BACK'] });
    await expect(pass()).rejects.toBeInstanceOf(BackRequested);
  });

  it('rewinds to a question of the history to change it', async () => {
    const history = new History();
    const { asked, pass } = flowOf(history, { two: ['first', 'second'] });
    await pass();
    history.rewind(1);
    asked.length = 0;
    expect(await pass()).toEqual(['one!', 'second', 'three!']);
    expect(asked.map((question) => question.name)).toEqual(['two', 'three']);
    expect(asked[0]?.previous).toBe('first');
  });
});
