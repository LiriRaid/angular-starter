import { mkdir, readFile, readdir, writeFile } from 'node:fs/promises';
import { dirname, join, relative, sep } from 'node:path';
import { fileURLToPath } from 'node:url';
import { RuntimeError } from '../errors.js';
import { pathExists } from './fs.js';

/**
 * Template files shipped with the CLI. `pnpm build` and the test run copy the repository's
 * `blueprints/` folder here, so this one path is valid from `src/` and from `dist/`.
 */
export const BLUEPRINTS_ROOT = fileURLToPath(new URL('../../blueprints/', import.meta.url));

const TEMPLATE_SUFFIX = '.tpl';
const PLACEHOLDER = /__([A-Z][A-Z_]*)__/g;

export type BlueprintVariables = Readonly<Record<string, string>>;

export interface CopyBlueprintOptions {
  /** Folder that mirrors the project tree. */
  source: string;
  /** The generated project. */
  target: string;
  variables: BlueprintVariables;
  /** Project files (forward slashes) that may be replaced; any other collision is an error. */
  overwrite?: readonly string[];
}

/**
 * Replaces `__NAME__` placeholders. Angular's `{{ }}` interpolation is untouched, and a placeholder
 * without a value fails instead of leaking into a generated project.
 */
export function renderTemplate(text: string, variables: BlueprintVariables): string {
  return text.replace(PLACEHOLDER, (placeholder, key: string) => {
    const value = variables[key];
    if (value === undefined) {
      throw new RuntimeError(
        `The blueprint uses the placeholder ${placeholder} but it has no value.`,
      );
    }
    return value;
  });
}

/** Every file below `directory`, relative to it, with forward slashes, sorted. */
export async function listBlueprintFiles(directory: string): Promise<string[]> {
  const entries = await readdir(directory, { recursive: true, withFileTypes: true });
  return entries
    .filter((entry) => entry.isFile())
    .map((entry) => relative(directory, join(entry.parentPath, entry.name)).split(sep).join('/'))
    .sort();
}

/**
 * Copies a blueprint into a project and returns the project paths it wrote. Nothing is written
 * when any destination already exists and is not in `overwrite`.
 */
export async function copyBlueprint(options: CopyBlueprintOptions): Promise<string[]> {
  const { source, target, variables, overwrite = [] } = options;
  const files = (await listBlueprintFiles(source)).map((file) => ({
    from: file,
    to: file.endsWith(TEMPLATE_SUFFIX) ? file.slice(0, -TEMPLATE_SUFFIX.length) : file,
  }));

  const collisions: string[] = [];
  for (const { to } of files) {
    if (!overwrite.includes(to) && (await pathExists(join(target, to)))) collisions.push(to);
  }
  if (collisions.length > 0) {
    throw new RuntimeError(
      `The blueprint would overwrite existing files: ${collisions.join(', ')}.`,
    );
  }

  for (const { from, to } of files) {
    const content = renderTemplate(await readFile(join(source, from), 'utf8'), variables);
    await mkdir(dirname(join(target, to)), { recursive: true });
    await writeFile(join(target, to), content);
  }
  return files.map(({ to }) => to).sort();
}
