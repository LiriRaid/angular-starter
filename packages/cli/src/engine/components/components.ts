import { readFile, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { RuntimeError } from '../../errors.js';
import { BLUEPRINTS_ROOT, copyBlueprint } from '../blueprint.js';
import { pathExists } from '../fs.js';
import { barrelLines, componentsOf, type ComponentSet } from './manifest.js';

const SHARED = 'src/app/shared/components';
const BARREL = `${SHARED}/index.ts`;

export interface ComponentsProject {
  targetDir: string;
  name: string;
  prefix: string;
  set: ComponentSet;
}

/**
 * The native `as-` components of ADR-0005: the collection's folders under `shared/components`, each
 * with its spec, and their exports in the `@shared/components` barrel. A component that is already
 * in the project is left alone, so a bigger collection can be added later without touching what
 * the developer has changed.
 */
export const componentsProfile = {
  /** Project files (forward slashes) that must exist once the collection has been applied. */
  requiredFilesFor: (set: ComponentSet): string[] =>
    componentsOf(set).map(({ id }) => `${SHARED}/as-${id}/as-${id}.ts`),

  async apply({ targetDir, name, prefix, set }: ComponentsProject): Promise<void> {
    const definitions = componentsOf(set);

    // Compute the barrel first: a project without it stops the stage before anything is written.
    const barrelPath = join(targetDir, BARREL);
    let barrel: string;
    try {
      const current = await readFile(barrelPath, 'utf8');
      const missing = barrelLines(definitions).filter((line) => !current.includes(line));
      // The generated barrel is `export {};`, which stops being needed with the first export.
      barrel = `${current.replace(/^export \{\};\n/m, '').trimEnd()}\n${missing.join('\n')}\n`;
      if (missing.length === 0) barrel = current;
    } catch (error) {
      const reason = error instanceof Error ? error.message : String(error);
      throw new RuntimeError(`Could not adapt ${BARREL}: ${reason}`);
    }

    for (const { id } of definitions) {
      if (await pathExists(join(targetDir, SHARED, `as-${id}`))) continue;
      await copyBlueprint({
        source: join(BLUEPRINTS_ROOT, 'components', `as-${id}`),
        target: targetDir,
        variables: { PROJECT_NAME: name, PREFIX: prefix },
      });
    }
    await writeFile(barrelPath, barrel);
  },
};
