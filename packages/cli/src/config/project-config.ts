import { CONFIG_SCHEMA_VERSION, type StarterOptions } from './schema.js';

/** Written to the root of every generated project. It never holds secrets. */
export const PROJECT_CONFIG_FILE = 'angular-starter.config.json';

export interface ProjectConfig {
  schemaVersion: typeof CONFIG_SCHEMA_VERSION;
  generator: { cli: string; angularCli: string };
  options: StarterOptions;
}

export function createProjectConfig(
  options: StarterOptions,
  generator: ProjectConfig['generator'],
): ProjectConfig {
  return { schemaVersion: CONFIG_SCHEMA_VERSION, generator, options };
}

export function serializeProjectConfig(config: ProjectConfig): string {
  return `${JSON.stringify(config, null, 2)}\n`;
}
