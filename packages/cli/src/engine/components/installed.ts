import { readdir } from 'node:fs/promises';
import { join } from 'node:path';

const COMPONENTS_FOLDER = 'src/app/shared/components';

/**
 * The ids of the `sa-` components that are really in a project: one folder each below
 * `shared/components`. The configuration only records what the developer chose, while the shell and
 * the components bring others with them (a custom selection gets what its components import, the
 * shell gets its search and its colour picker), so the folders are what says what the project has.
 */
export async function installedComponentIds(targetDir: string): Promise<string[]> {
  const entries = await readdir(join(targetDir, COMPONENTS_FOLDER), { withFileTypes: true }).catch(
    () => [],
  );
  return entries
    .filter((entry) => entry.isDirectory() && entry.name.startsWith('sa-'))
    .map((entry) => entry.name.slice('sa-'.length))
    .sort();
}
