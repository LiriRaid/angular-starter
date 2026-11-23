import { BackRequested } from './prompter.js';

/**
 * Thrown to start the flow again: the answers before question `to` are replayed and `to` is asked
 * again. Questions are numbered in the order they were really asked, skipped ones do not count.
 */
export class Rewind extends Error {
  constructor(readonly to: number) {
    super(`Rewind to question ${to}`);
    this.name = 'Rewind';
  }
}

/** One question of the flow, with how it is asked and how its answer reads in the list of answers. */
export interface Turn<T> {
  /** Stable identifier of the question. */
  name: string;
  /** What the question is about, for the list of answers to change. */
  title: string;
  summarize(answer: T): string;
  /** `previous` is the answer given before when this question is asked again. */
  ask(previous: T | undefined, canGoBack: boolean): Promise<T>;
}

interface Entry {
  name: string;
  title: string;
  summary: string;
  answer: unknown;
}

/**
 * The answers of a linear flow, so it can be walked again from the start after going back. The flow is
 * deterministic: with the same answers it asks the same questions, so replaying the recorded ones
 * recomputes everything that depended on them and nothing has to be undone.
 */
export class History {
  private entries: Entry[] = [];
  private replayUntil = 0;
  private cursor = 0;

  /** Starts a pass of the flow. */
  begin(): void {
    this.cursor = 0;
  }

  /** The next pass replays the questions before `to` and asks `to` again with its answer. */
  rewind(to: number): void {
    this.replayUntil = Math.max(0, Math.min(to, this.entries.length));
  }

  /** The questions answered so far, in order, for the user to pick one to change. */
  get answered(): readonly { name: string; title: string; summary: string }[] {
    return this.entries.map(({ name, title, summary }) => ({ name, title, summary }));
  }

  /** Index of the question with this name, or -1. */
  indexOf(name: string): number {
    return this.entries.findIndex((entry) => entry.name === name);
  }

  get length(): number {
    return this.entries.length;
  }

  async turn<T>(turn: Turn<T>): Promise<T> {
    const index = this.cursor++;
    const saved = this.entries[index]?.name === turn.name ? this.entries[index] : undefined;
    if (saved && index < this.replayUntil) return saved.answer as T;

    let answer: T;
    try {
      answer = await turn.ask(
        saved && index === this.replayUntil ? (saved.answer as T) : undefined,
        index > 0,
      );
    } catch (error) {
      // The first question has nothing before it.
      if (error instanceof BackRequested && index > 0) throw new Rewind(index - 1);
      throw error;
    }
    // Whatever was answered after this question belongs to a flow that no longer exists.
    this.entries.length = index;
    this.entries.push({
      name: turn.name,
      title: turn.title,
      summary: turn.summarize(answer),
      answer,
    });
    return answer;
  }
}
