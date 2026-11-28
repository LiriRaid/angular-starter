import { describe, expect, it } from 'vitest';
import { createFakeIo } from '../../tests/helpers/fake-io.js';
import { printDryRun } from './dry-run.js';

describe('printDryRun', () => {
  it('prints the title, the tree, what it would do and a legend of the marks it used', () => {
    const fake = createFakeIo();
    printDryRun(fake.io, {
      title: 'Dry run: nothing was written.',
      root: 'demo',
      entries: [
        { path: 'src/main.ts', action: 'create' },
        { path: 'package.json', action: 'update' },
      ],
    });
    expect(fake.out().split('\n')).toEqual([
      'Dry run: nothing was written.',
      '',
      'demo/',
      '├── src/',
      '│   └── + main.ts',
      '└── ~ package.json',
      '',
      'Would create 1 file and update 1 file.',
      '+ created   ~ updated',
      '',
    ]);
  });

  it('names only the marks that appear in the tree', () => {
    const only = (action: 'create' | 'remove'): string => {
      const fake = createFakeIo();
      printDryRun(fake.io, { title: 'T', root: 'demo', entries: [{ path: 'a.ts', action }] });
      return fake.out().trimEnd().split('\n').at(-1) ?? '';
    };
    expect(only('create')).toBe('+ created');
    expect(only('remove')).toBe('- removed');
  });

  it('draws every file when verbose and the folders as one line when not', () => {
    const entries = [
      { path: 'a/b/c/d/one.ts', action: 'create' as const },
      { path: 'a/b/c/d/two.ts', action: 'create' as const },
    ];
    const summary = createFakeIo();
    printDryRun(summary.io, { title: 'T', root: 'demo', entries });
    expect(summary.out()).toContain('d/ (2 files)');
    const verbose = createFakeIo();
    printDryRun(verbose.io, { title: 'T', root: 'demo', entries, verbose: true });
    expect(verbose.out()).toContain('+ one.ts');
    expect(verbose.out()).not.toContain('(2 files)');
  });
});
