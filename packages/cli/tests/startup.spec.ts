import { describe, expect, it, vi } from 'vitest';
import { run } from '../src/main.js';
import { createFakeIo } from './helpers/fake-io.js';

/** The heavy dependencies each take hundreds of milliseconds to load. */
const loaded = vi.hoisted(() => [] as string[]);

vi.mock('ts-morph', async (importOriginal) => {
  loaded.push('ts-morph');
  return importOriginal();
});

vi.mock('execa', async (importOriginal) => {
  loaded.push('execa');
  return importOriginal();
});

describe('startup of the CLI', () => {
  it.each([
    ['--version'],
    ['--help'],
    ['list'],
    ['new', '--help'],
    ['add', '--help'],
    ['generate', '--help'],
  ])('does not load ts-morph or execa for "%s"', async (...argv) => {
    const fake = createFakeIo();
    await run(argv, fake.io);
    expect(fake.out().length).toBeGreaterThan(0);
    expect(loaded).toEqual([]);
  });
});
