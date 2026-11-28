import { createHash } from 'node:crypto';
import { readFile, readdir } from 'node:fs/promises';
import { join, relative, sep } from 'node:path';
import type { PlannedFile } from '../../src/engine/plan.js';

/** What an installed project has that is not part of what a command writes. */
const IGNORED = /^(node_modules|\.angular|dist)\//;

/** Every file of the project by path, with a hash of its content. */
export async function snapshot(root: string): Promise<Map<string, string>> {
  const files = new Map<string, string>();
  const entries = await readdir(root, { recursive: true, withFileTypes: true });
  for (const entry of entries) {
    if (!entry.isFile()) continue;
    const path = relative(root, join(entry.parentPath, entry.name)).split(sep).join('/');
    if (IGNORED.test(path)) continue;
    const text = await readFile(join(root, path));
    files.set(path, createHash('sha1').update(text).digest('hex'));
  }
  return files;
}

export const byPath = (left: PlannedFile, right: PlannedFile): number =>
  left.path.localeCompare(right.path, 'en');

/** What changed between two snapshots. */
export function difference(before: Map<string, string>, after: Map<string, string>): PlannedFile[] {
  const changes: PlannedFile[] = [];
  for (const [path, hash] of after) {
    if (!before.has(path)) changes.push({ path, action: 'create' });
    else if (before.get(path) !== hash) changes.push({ path, action: 'update' });
  }
  for (const path of before.keys()) {
    if (!after.has(path)) changes.push({ path, action: 'remove' });
  }
  return changes.sort(byPath);
}

/** Reads the files of the tree `--dry-run --verbose` draws back into paths and actions. */
export function readTree(out: string): PlannedFile[] {
  const lines = out.split('\n');
  const root = lines.indexOf('What it would write:') + 2;
  const files: PlannedFile[] = [];
  const folders: string[] = [];
  for (const line of lines.slice(root + 1)) {
    if (line === '') break;
    const match = /^((?:│ {3}| {4})*)(?:├── |└── )(?:([+~-]) )?(.+)$/.exec(line);
    if (!match) throw new Error(`Not a line of the tree: "${line}"`);
    const [, indent = '', mark, name = ''] = match;
    folders.length = indent.length / 4;
    if (mark === undefined) {
      folders.push(name.replace(/\/$/, ''));
      continue;
    }
    const action = mark === '+' ? 'create' : mark === '~' ? 'update' : 'remove';
    files.push({ path: [...folders, name].join('/'), action });
  }
  return files.sort(byPath);
}
