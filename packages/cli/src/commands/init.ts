import { existsSync } from 'node:fs';
import { readFile, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { ANGULAR_CLI_VERSION } from '../compat.js';
import {
  PROJECT_CONFIG_FILE,
  createProjectConfig,
  serializeProjectConfig,
} from '../config/project-config.js';
import { detectProject, findWorkspace } from '../engine/detect.js';
import { UsageError } from '../errors.js';
import { println, type CliIo } from '../io.js';
import { createStyler, formatRows } from '../ui/format.js';
import { CLI_VERSION } from '../version.js';

export interface InitFlags {
  force?: boolean;
  dryRun?: boolean;
}

/**
 * Adopts an existing Angular project (ADR-0019): reads what it has, shows it and records it in
 * `angular-starter.config.json`, so that `as add` and `as generate` work on it. It changes no code.
 */
export async function initCommand(io: CliIo, flags: InitFlags): Promise<void> {
  const root = await findWorkspace(io.cwd);
  if (root === undefined) {
    throw new UsageError(
      `This is not an Angular workspace: angular.json was not found in ${io.cwd} or its parent folders.`,
      'Run "as init" in the folder of the project. To start a new one, use "as new".',
    );
  }
  const file = join(root, PROJECT_CONFIG_FILE);
  if (existsSync(file) && !flags.force) {
    throw new UsageError(
      `${PROJECT_CONFIG_FILE} already exists in ${root}: this project is already set up.`,
      'Use "as init --force" to read the project again and replace it.',
    );
  }

  const { options, notes } = await detectProject(root);
  const style = createStyler(io.color);
  println(
    io.stdout,
    style.bold(flags.dryRun ? 'Dry run: this is what it found.' : 'Found in the project:'),
  );
  for (const line of formatRows(
    Object.entries(options)
      .filter(([key]) => key !== 'componentList' && key !== 'git' && key !== 'install')
      .map(([key, value]) => [key, String(value)] as const),
  )) {
    println(io.stdout, `  ${line}`);
  }
  if (options.componentList)
    println(io.stdout, `  components: ${options.componentList.join(', ')}`);
  for (const note of notes) println(io.stdout, style.dim(`  Note: ${note}`));

  if (flags.dryRun) return;
  const manifest = JSON.parse(
    await readFile(join(root, 'package.json'), 'utf8').catch(() => '{}'),
  ) as {
    devDependencies?: Record<string, string>;
    dependencies?: Record<string, string>;
  };
  const installed = (
    manifest.devDependencies?.['@angular/cli'] ??
    manifest.dependencies?.['@angular/cli'] ??
    ''
  ).replace(/^[^\d]*/, '');
  const config = createProjectConfig(options, {
    cli: CLI_VERSION,
    angularCli: installed || ANGULAR_CLI_VERSION,
  });
  await writeFile(file, serializeProjectConfig(config));
  println(io.stdout);
  println(io.stdout, style.green(`${PROJECT_CONFIG_FILE} written.`));
  println(
    io.stdout,
    'Now "as add", "as generate" and "as config" work in this project. See "as list".',
  );
}
