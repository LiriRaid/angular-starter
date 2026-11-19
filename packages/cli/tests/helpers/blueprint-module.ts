import { cp, mkdtemp, readdir, rename } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';
import { BLUEPRINTS_ROOT } from '../../src/engine/blueprint.js';

/**
 * Loads a framework-free TypeScript file of a blueprint so that its logic can be unit tested here.
 * The folder is copied with the `.tpl` suffix removed; the file must not use placeholders.
 */
export async function loadBlueprintModule<T>(
  blueprint: string,
  folder: string,
  file: string,
): Promise<{ module: T; directory: string }> {
  const directory = await mkdtemp(join(tmpdir(), 'as-blueprint-'));
  await cp(join(BLUEPRINTS_ROOT, blueprint, folder), directory, { recursive: true });
  for (const entry of await readdir(directory)) {
    if (entry.endsWith('.tpl')) {
      await rename(join(directory, entry), join(directory, entry.slice(0, -'.tpl'.length)));
    }
  }
  return { module: (await import(pathToFileURL(join(directory, file)).href)) as T, directory };
}
