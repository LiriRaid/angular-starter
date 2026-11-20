import { readFile } from 'node:fs/promises';
import { basename, dirname, join } from 'node:path';
import { PROJECT_CONFIG_FILE } from '../config/project-config.js';
import { formatIssues } from '../config/issues.js';
import { optionsSchema, type StarterOptions } from '../config/schema.js';
import { UsageError } from '../errors.js';

/** A project created by Angular Starter, found through its configuration file. */
export interface StarterProject {
  /** The folder that holds `angular-starter.config.json`. */
  root: string;
  /** The package name of the project, which the generated code uses as its application name. */
  name: string;
  options: StarterOptions;
}

/**
 * Walks up from `startDir` to the closest `angular-starter.config.json`, so the commands that work
 * on a project run from any of its folders.
 */
export async function findProject(startDir: string): Promise<StarterProject> {
  let directory = startDir;
  for (;;) {
    const text = await readFile(join(directory, PROJECT_CONFIG_FILE), 'utf8').catch(
      () => undefined,
    );
    if (text !== undefined) return parseProject(directory, text);
    const parent = dirname(directory);
    if (parent === directory) break;
    directory = parent;
  }
  throw new UsageError(
    `This is not an Angular Starter project: ${PROJECT_CONFIG_FILE} was not found in ${startDir} or its parent folders.`,
    'Run the command inside a project created with "as new".',
  );
}

async function parseProject(root: string, text: string): Promise<StarterProject> {
  const invalid = (reason: string): UsageError =>
    new UsageError(`${PROJECT_CONFIG_FILE} is not valid: ${reason}`);

  let json: unknown;
  try {
    json = JSON.parse(text);
  } catch {
    throw invalid('it is not JSON.');
  }
  const options = optionsSchema.safeParse((json as { options?: unknown } | null)?.options);
  if (!options.success) throw invalid(`\n${formatIssues(options.error)}`);

  const manifest = await readFile(join(root, 'package.json'), 'utf8').catch(() => '{}');
  const name = (JSON.parse(manifest) as { name?: unknown }).name;
  return {
    root,
    name: typeof name === 'string' && name !== '' ? name : basename(root),
    options: options.data,
  };
}
