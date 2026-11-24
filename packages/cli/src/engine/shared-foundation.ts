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
export async function applySharedFoundation(
  targetDir: string,
  aliases: Readonly<Record<string, string[]>> = ALIASES,
  needsThem = 'the components',
): Promise<string[]> {
  const own = await readTsconfig(targetDir, TSCONFIG);
  const inherited = await inheritedPaths(targetDir, own);
  const ownPaths = pathsOf(own);
  const paths: Record<string, unknown> = { ...inherited, ...ownPaths };

  const missing: Record<string, string[]> = {};
  for (const [alias, targets] of Object.entries(aliases)) {
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
        `The alias "${alias}" in ${TSCONFIG} points to ${JSON.stringify(current)}; ${needsThem} need it to point to ${targets[0]}.`,
        `Change it, or choose another place for ${needsThem} by editing their imports after adding them.`,
      );
    }
  }
  // `paths` in a file replaces the one it extends, so the inherited aliases are written along with the new ones.
  const toWrite: Record<string, string[]> = { ...missing };
  if (Object.keys(missing).length > 0) {
    for (const [alias, targets] of Object.entries(inherited)) {
      if (!(alias in ownPaths) && Array.isArray(targets)) toWrite[alias] = targets as string[];
    }
  }

  const planned =
    Object.keys(missing).length === 0
      ? []
      : [await planEdit(targetDir, TSCONFIG, (text) => addPathAliases(text, toWrite))];
  await writeEdits(planned);

  if (!(await pathExists(join(targetDir, BARREL)))) {
    await mkdir(dirname(join(targetDir, BARREL)), { recursive: true });
    await writeFile(join(targetDir, BARREL), 'export {};\n');
  }
  return Object.keys(missing);
}

type Tsconfig = { extends?: unknown; compilerOptions?: { paths?: Record<string, unknown> } };

async function readTsconfig(dir: string, file: string): Promise<Tsconfig> {
  const text = await readFile(join(dir, file), 'utf8').catch(() => undefined);
  return (parse(text ?? '{}') as Tsconfig | undefined) ?? {};
}

const pathsOf = (config: Tsconfig): Record<string, unknown> => config.compilerOptions?.paths ?? {};

/**
 * The `paths` the project gets from the files it extends, read from the ones in its own folder. A base
 * file elsewhere (a package, another folder) cannot be merged here, so it stops the stage.
 */
async function inheritedPaths(
  targetDir: string,
  config: Tsconfig,
  seen: Set<string> = new Set(),
): Promise<Record<string, unknown>> {
  const bases = Array.isArray(config.extends)
    ? config.extends
    : config.extends
      ? [config.extends]
      : [];
  let result: Record<string, unknown> = {};
  for (const base of bases) {
    if (typeof base !== 'string' || !/^\.\/[^/]+$/.test(base)) {
      throw new UsageError(
        `${TSCONFIG} extends "${String(base)}", which is not a file of the project folder, so the aliases of the components cannot be merged with its paths.`,
        'Add "@core/*": ["./src/app/core/*"] and "@shared/*": ["./src/app/shared/*"] to its paths by hand, then run the command again.',
      );
    }
    const file = base.slice(2).endsWith('.json') ? base.slice(2) : `${base.slice(2)}.json`;
    if (seen.has(file)) continue;
    seen.add(file);
    const parent = await readTsconfig(targetDir, file);
    result = { ...result, ...(await inheritedPaths(targetDir, parent, seen)), ...pathsOf(parent) };
  }
  return result;
}
