import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { parse } from 'jsonc-parser';
import { UsageError } from '../errors.js';
import { planEdit, writeEdits } from './edits/planned.js';
import { addPathAliases } from './edits/tsconfig.js';
import { pathExists } from './fs.js';

const TSCONFIG = 'tsconfig.json';
const BARREL = 'src/app/shared/components/index.ts';

/** The aliases the native components import through, and the folders they point to. */
const ALIASES: Readonly<Record<string, string[]>> = {
  '@core/*': ['./src/app/core/*'],
  '@shared/*': ['./src/app/shared/*'],
};

const normalize = (target: string): string => target.replace(/^\.\//, '').replace(/\/$/, '');

/**
 * What the native components need in a project that has no architecture of the starter (ADR-0019): the
 * `@core` and `@shared` aliases and the barrel of `shared/components`. An alias the project already
 * has is kept when it points where the components expect it, and stops the stage when it does not; a
 * barrel that exists is left as it is. Nothing the developer has is moved or replaced.
 */
export async function applySharedFoundation(targetDir: string): Promise<void> {
  const tsconfig = await readFile(join(targetDir, TSCONFIG), 'utf8').catch(() => undefined);
  const paths: Record<string, unknown> =
    (
      parse(tsconfig ?? '{}') as
        { compilerOptions?: { paths?: Record<string, unknown> } } | undefined
    )?.compilerOptions?.paths ?? {};

  const missing: Record<string, string[]> = {};
  for (const [alias, targets] of Object.entries(ALIASES)) {
    const current = paths[alias];
    if (current === undefined) {
      missing[alias] = targets;
    } else if (
      !Array.isArray(current) ||
      !current.some(
        (entry) => typeof entry === 'string' && normalize(entry) === normalize(targets[0] ?? ''),
      )
    ) {
      throw new UsageError(
        `The alias "${alias}" in ${TSCONFIG} points to ${JSON.stringify(current)}; the components need it to point to ${targets[0]}.`,
        'Change it, or choose another place for the components by editing their imports after adding them.',
      );
    }
  }

  const planned =
    Object.keys(missing).length === 0
      ? []
      : [await planEdit(targetDir, TSCONFIG, (text) => addPathAliases(text, missing))];
  await writeEdits(planned);

  if (!(await pathExists(join(targetDir, BARREL)))) {
    await mkdir(dirname(join(targetDir, BARREL)), { recursive: true });
    await writeFile(join(targetDir, BARREL), 'export {};\n');
  }
}
