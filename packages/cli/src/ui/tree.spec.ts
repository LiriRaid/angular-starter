import { describe, expect, it } from 'vitest';
import { renderTree, summarizeEntries, type TreeEntry } from './tree.js';

const create = (path: string): TreeEntry => ({ path, action: 'create' });
const update = (path: string): TreeEntry => ({ path, action: 'update' });

describe('renderTree', () => {
  it('draws the folders and files with connectors and a marker for what is created or updated', () => {
    const lines = renderTree(
      [create('src/main.ts'), create('src/app/app.ts'), update('package.json')],
      { root: 'demo', color: false },
    );
    expect(lines).toEqual([
      'demo/',
      '├── src/',
      '│   ├── app/',
      '│   │   └── + app.ts',
      '│   └── + main.ts',
      '└── ~ package.json',
    ]);
  });

  it('lists the folders before the files and sorts each group by name', () => {
    const lines = renderTree(
      [create('b.txt'), create('z/a.txt'), create('a.txt'), create('m/a.txt')],
      {
        color: false,
      },
    );
    expect(lines).toEqual([
      '├── m/',
      '│   └── + a.txt',
      '├── z/',
      '│   └── + a.txt',
      '├── + a.txt',
      '└── + b.txt',
    ]);
  });

  it('collapses the folders below the depth limit with how many files they hold', () => {
    const entries = [
      create('src/app/shared/components/sa-button/sa-button.ts'),
      create('src/app/shared/components/sa-button/sa-button.html'),
      create('src/app/shared/components/sa-modal/sa-modal.ts'),
      create('src/app/shared/components/index.ts'),
    ];
    expect(renderTree(entries, { color: false, maxDepth: 4 })).toEqual([
      '└── src/',
      '    └── app/',
      '        └── shared/',
      '            └── components/',
      '                ├── sa-button/ (2 files)',
      '                ├── sa-modal/ (1 file)',
      '                └── + index.ts',
    ]);
  });

  it('shows every file when verbose, whatever the depth', () => {
    const entries = [
      create('src/app/shared/components/sa-button/sa-button.ts'),
      create('src/app/shared/components/sa-button/sa-button.html'),
    ];
    const lines = renderTree(entries, { color: false, maxDepth: 4, verbose: true });
    expect(lines.at(-2)).toContain('+ sa-button.html');
    expect(lines.at(-1)).toContain('+ sa-button.ts');
    expect(lines.join('\n')).not.toContain('(2 files)');
  });

  it('says how many are new and how many updated in a collapsed folder that has both', () => {
    const entries = [
      create('a/b/c/d/e/new.ts'),
      update('a/b/c/d/e/old.ts'),
      create('a/b/c/d/e/x.ts'),
    ];
    expect(renderTree(entries, { color: false, maxDepth: 4 }).at(-1)).toContain(
      'e/ (2 new, 1 updated)',
    );
  });

  it('keeps a file that is created even when it is also listed as updated', () => {
    const lines = renderTree([update('a.ts'), create('a.ts')], { color: false });
    expect(lines).toEqual(['└── + a.ts']);
  });

  it('draws nothing when there is nothing', () => {
    expect(renderTree([], { root: 'demo', color: false })).toEqual([]);
  });

  it('paints the markers only when color is on', () => {
    const colored = renderTree([create('a.ts'), update('b.ts')], { color: true }).join('\n');
    expect(colored).toContain('\u001b[');
    expect(renderTree([create('a.ts')], { color: false }).join('\n')).not.toContain('\u001b[');
  });
});

describe('summarizeEntries', () => {
  it('counts what would be created and updated', () => {
    expect(summarizeEntries([create('a'), create('b'), update('c')])).toBe(
      'Would create 2 files and update 1 file.',
    );
  });

  it('leaves out what there is none of', () => {
    expect(summarizeEntries([create('a')])).toBe('Would create 1 file.');
    expect(summarizeEntries([update('a'), update('b')])).toBe('Would update 2 files.');
    expect(summarizeEntries([])).toBe('Would change nothing.');
  });
});
