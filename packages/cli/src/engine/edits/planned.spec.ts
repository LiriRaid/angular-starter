import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { planEdit, writeEdits } from './planned.js';

let root: string;

beforeEach(async () => {
  root = await mkdtemp(join(tmpdir(), 'sa-planned-'));
  await writeFile(join(root, 'a.txt'), 'one');
});

afterEach(async () => {
  await rm(root, { recursive: true, force: true });
});

describe('planned edits', () => {
  it('computes the new text without writing it', async () => {
    const planned = await planEdit(root, 'a.txt', (text) => `${text} two`);
    expect(planned.text).toBe('one two');
    expect(await readFile(join(root, 'a.txt'), 'utf8')).toBe('one');
  });

  it('writes what was planned', async () => {
    await writeEdits([await planEdit(root, 'a.txt', () => 'three')]);
    expect(await readFile(join(root, 'a.txt'), 'utf8')).toBe('three');
  });

  it('names the file when the edit does not fit it', async () => {
    const failing = planEdit(root, 'a.txt', () => {
      throw new Error('no match');
    });
    await expect(failing).rejects.toThrow('Could not adapt a.txt: no match');
  });

  it('names the file when it does not exist', async () => {
    await expect(planEdit(root, 'missing.txt', (text) => text)).rejects.toThrow(
      /Could not adapt missing\.txt/,
    );
  });
});
