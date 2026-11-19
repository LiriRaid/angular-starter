import { describe, expect, it } from 'vitest';
import { RuntimeError } from '../errors.js';
import { createFakeIo } from '../../tests/helpers/fake-io.js';
import { runPipeline, type GenerationContext, type Stage } from './pipeline.js';

function contextFor(fake = createFakeIo()): GenerationContext {
  return { io: fake.io } as unknown as GenerationContext;
}

describe('runPipeline', () => {
  it('runs the stages in order and reports each one', async () => {
    const order: string[] = [];
    const fake = createFakeIo();
    const stages: Stage[] = [
      { id: 'a', title: 'First', run: async () => void order.push('a') },
      { id: 'b', title: 'Second', run: async () => void order.push('b') },
    ];
    await runPipeline(stages, contextFor(fake));
    expect(order).toEqual(['a', 'b']);
    expect(fake.out()).toMatch(/✓ First\n✓ Second\n/);
  });

  it('announces slow stages before running them', async () => {
    const fake = createFakeIo();
    let announcedBeforeRun = false;
    const stages: Stage[] = [
      {
        id: 'a',
        title: 'Slow',
        pending: 'this can take a few minutes',
        run: async () => {
          announcedBeforeRun = fake.out().includes('… Slow (this can take a few minutes)\n');
        },
      },
    ];
    await runPipeline(stages, contextFor(fake));
    expect(announcedBeforeRun).toBe(true);
    expect(fake.out()).toContain('✓ Slow');
  });

  it('skips disabled stages without reporting them', async () => {
    const fake = createFakeIo();
    const stages: Stage[] = [
      {
        id: 'a',
        title: 'Skipped',
        enabled: () => false,
        run: async () => Promise.reject(new Error('no')),
      },
      { id: 'b', title: 'Runs', run: async () => {} },
    ];
    await runPipeline(stages, contextFor(fake));
    expect(fake.out()).not.toContain('Skipped');
    expect(fake.out()).toContain('✓ Runs');
  });

  it('stops at the first failing stage and reports it', async () => {
    const order: string[] = [];
    const fake = createFakeIo();
    const stages: Stage[] = [
      { id: 'a', title: 'Fine', run: async () => void order.push('a') },
      {
        id: 'b',
        title: 'Breaks',
        run: async () => {
          throw new Error('disk full');
        },
      },
      { id: 'c', title: 'Never', run: async () => void order.push('c') },
    ];
    await expect(runPipeline(stages, contextFor(fake))).rejects.toThrow(RuntimeError);
    await expect(runPipeline(stages, contextFor(createFakeIo()))).rejects.toThrow(
      /Breaks.*disk full/,
    );
    expect(order).not.toContain('c');
    expect(fake.out()).toContain('✗ Breaks');
  });

  it('keeps the original error of a stage that already throws a CliError', async () => {
    const stages: Stage[] = [
      {
        id: 'a',
        title: 'Typed',
        run: async () => {
          throw new RuntimeError('specific message', 'a hint');
        },
      },
    ];
    await expect(runPipeline(stages, contextFor())).rejects.toMatchObject({
      message: 'specific message',
      hint: 'a hint',
    });
  });
});
