import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { UsageError } from '../errors.js';
import { formatIssues } from './issues.js';
import { configFileSchema, type StarterOptions } from './schema.js';

/** Reads and validates a `--config` file, returning the options it sets. */
export async function readConfigFile(path: string, cwd: string): Promise<Partial<StarterOptions>> {
  let text: string;
  try {
    text = await readFile(resolve(cwd, path), 'utf8');
  } catch (error) {
    const reason = error instanceof Error ? error.message : String(error);
    throw new UsageError(`Cannot read the configuration file "${path}": ${reason}`);
  }

  let json: unknown;
  try {
    json = JSON.parse(text);
  } catch {
    throw new UsageError(`The configuration file "${path}" is not valid JSON.`);
  }

  const parsed = configFileSchema.safeParse(json);
  if (!parsed.success) {
    throw new UsageError(`Invalid configuration file "${path}":\n${formatIssues(parsed.error)}`);
  }
  return parsed.data.options ?? {};
}
