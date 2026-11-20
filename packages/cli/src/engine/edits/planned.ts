import { readFile, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { RuntimeError } from '../../errors.js';

/** The new text of a project file, computed and not written yet. */
export interface PlannedEdit {
  path: string;
  text: string;
}

/**
 * Reads `file` (forward slashes, below `root`) and applies `edit` to its text. A file that is
 * missing or does not have the shape the edit expects fails here, naming the file, so a stage can
 * plan every edit before it writes anything.
 */
export async function planEdit(
  root: string,
  file: string,
  edit: (text: string) => string,
): Promise<PlannedEdit> {
  const path = join(root, file);
  try {
    return { path, text: edit(await readFile(path, 'utf8')) };
  } catch (error) {
    const reason = error instanceof Error ? error.message : String(error);
    throw new RuntimeError(`Could not adapt ${file}: ${reason}`);
  }
}

export async function writeEdits(planned: readonly PlannedEdit[]): Promise<void> {
  for (const { path, text } of planned) await writeFile(path, text);
}
