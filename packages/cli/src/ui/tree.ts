import { createStyler } from './format.js';

export type TreeAction = 'create' | 'update' | 'remove';

/** A project file (relative path, any separator) a command would create, change or delete. */
export interface TreeEntry {
  path: string;
  action: TreeAction;
}

export interface TreeOptions {
  /** Name of the folder drawn on top; without it the tree starts at the first level. */
  root?: string;
  color: boolean;
  /** Draw every file instead of collapsing the deep folders. */
  verbose?: boolean;
  /** Folders nested deeper than this (the root is level 0) are drawn as one line with their file count. */
  maxDepth?: number;
}

const DEFAULT_MAX_DEPTH = 3;

interface Folder {
  folders: Map<string, Folder>;
  files: Map<string, TreeAction>;
}

type Child = { name: string; folder: Folder } | { name: string; action: TreeAction };

interface Counts {
  create: number;
  update: number;
  remove: number;
}

const newFolder = (): Folder => ({ folders: new Map(), files: new Map() });

/** One entry per path; a file that is created and also updated is a created one. */
function uniqueEntries(entries: readonly TreeEntry[]): Map<string, TreeAction> {
  const unique = new Map<string, TreeAction>();
  for (const { path, action } of entries) {
    const key = path.replaceAll('\\', '/');
    if (unique.get(key) !== 'create') unique.set(key, action);
  }
  return unique;
}

function buildFolders(entries: Map<string, TreeAction>): Folder {
  const root = newFolder();
  for (const [path, action] of entries) {
    const segments = path.split('/').filter(Boolean);
    const file = segments.pop();
    if (file === undefined) continue;
    let folder = root;
    for (const segment of segments) {
      let next = folder.folders.get(segment);
      if (!next) {
        next = newFolder();
        folder.folders.set(segment, next);
      }
      folder = next;
    }
    folder.files.set(file, action);
  }
  return root;
}

function countIn(folder: Folder): Counts {
  const counts: Counts = { create: 0, update: 0, remove: 0 };
  for (const action of folder.files.values()) counts[action] += 1;
  for (const child of folder.folders.values()) {
    const inner = countIn(child);
    counts.create += inner.create;
    counts.update += inner.update;
    counts.remove += inner.remove;
  }
  return counts;
}

const plural = (count: number, word: string): string => `${count} ${word}${count === 1 ? '' : 's'}`;

/** `(2 files)` for a folder of new files; `(2 new, 1 updated)` when it holds other changes too. */
function describeCounts({ create, update, remove }: Counts): string {
  if (update === 0 && remove === 0) return `(${plural(create, 'file')})`;
  const parts = [
    ...(create > 0 ? [`${create} new`] : []),
    ...(update > 0 ? [`${update} updated`] : []),
    ...(remove > 0 ? [`${remove} removed`] : []),
  ];
  return `(${parts.join(', ')})`;
}

const byName = (left: string, right: string): number => left.localeCompare(right, 'en');

/**
 * Draws the files a command would create (`+`), change (`~`) or delete (`-`) as a tree, like `tree` does. Folders come
 * before files, each group sorted by name. Unless verbose, folders below `maxDepth` are one line with
 * how many files they hold, so a whole project still reads at a glance.
 */
export function renderTree(entries: readonly TreeEntry[], options: TreeOptions): string[] {
  const unique = uniqueEntries(entries);
  if (unique.size === 0) return [];
  const style = createStyler(options.color);
  const maxDepth = options.maxDepth ?? DEFAULT_MAX_DEPTH;
  const lines: string[] = [];
  if (options.root !== undefined) lines.push(style.bold(`${options.root}/`));

  const marker = (action: TreeAction): string =>
    action === 'create'
      ? style.green('+')
      : action === 'update'
        ? style.yellow('~')
        : style.red('-');

  const draw = (folder: Folder, prefix: string, depth: number): void => {
    const children: Child[] = [
      ...[...folder.folders]
        .sort(([a], [b]) => byName(a, b))
        .map(([name, inner]): Child => ({ name, folder: inner })),
      ...[...folder.files]
        .sort(([a], [b]) => byName(a, b))
        .map(([name, action]): Child => ({ name, action })),
    ];
    children.forEach((child, index) => {
      const last = index === children.length - 1;
      const branch = style.dim(last ? '└── ' : '├── ');
      if ('action' in child) {
        lines.push(`${prefix}${branch}${marker(child.action)} ${child.name}`);
        return;
      }
      if (!options.verbose && depth + 1 > maxDepth) {
        lines.push(
          `${prefix}${branch}${child.name}/ ${style.dim(describeCounts(countIn(child.folder)))}`,
        );
        return;
      }
      lines.push(`${prefix}${branch}${child.name}/`);
      draw(child.folder, `${prefix}${style.dim(last ? '    ' : '│   ')}`, depth + 1);
    });
  };
  draw(buildFolders(unique), '', 0);
  return lines;
}

/** `Would create 2 files and update 1 file.` — the line that closes a dry run. */
export function summarizeEntries(entries: readonly TreeEntry[]): string {
  const counts = countIn(buildFolders(uniqueEntries(entries)));
  const parts = [
    ...(counts.create > 0 ? [`create ${plural(counts.create, 'file')}`] : []),
    ...(counts.update > 0 ? [`update ${plural(counts.update, 'file')}`] : []),
    ...(counts.remove > 0 ? [`remove ${plural(counts.remove, 'file')}`] : []),
  ];
  if (parts.length === 0) return 'Would change nothing.';
  const last = parts.pop();
  return `Would ${parts.length > 0 ? `${parts.join(', ')} and ` : ''}${last}.`;
}
