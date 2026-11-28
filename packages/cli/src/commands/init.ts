import { existsSync } from 'node:fs';
import { readFile, writeFile } from 'node:fs/promises';
import { basename, join } from 'node:path';
import { ANGULAR_CLI_VERSION } from '../compat.js';
import type { StarterOptions } from '../config/schema.js';
import {
  PROJECT_CONFIG_FILE,
  createProjectConfig,
  serializeProjectConfig,
} from '../config/project-config.js';
import { detectProject, findWorkspace } from '../engine/detect.js';
import { UsageError } from '../errors.js';
import { println, type CliIo } from '../io.js';
import { printDryRun } from '../ui/dry-run.js';
import { createStyler, formatRows } from '../ui/format.js';
import { CLI_VERSION } from '../version.js';

export interface InitFlags {
  force?: boolean;
  dryRun?: boolean;
}

/**
 * Adopts an existing Angular project (ADR-0019): reads what it has, shows it and records it in
 * `starter-angular.config.json`, so that `sa add` and `sa generate` work on it. It changes no code.
 */
export async function initCommand(io: CliIo, flags: InitFlags): Promise<void> {
  const root = await findWorkspace(io.cwd);
  if (root === undefined) {
    throw new UsageError(
      `This is not an Angular workspace: angular.json was not found in ${io.cwd} or its parent folders.`,
      'Run "sa init" in the folder of the project. To start a new one, use "sa new".',
    );
  }
  const file = join(root, PROJECT_CONFIG_FILE);
  if (existsSync(file) && !flags.force) {
    throw new UsageError(
      `${PROJECT_CONFIG_FILE} already exists in ${root}: this project is already set up.`,
      'Use "sa init --force" to read the project again and replace it.',
    );
  }

  const detected = await detectProject(root);
  const options = flags.force ? await keepRecorded(file, detected.options) : detected.options;
  const notes = detected.notes;
  const style = createStyler(io.color);
  println(io.stdout, style.bold('Found in the project:'));
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

  if (flags.dryRun) {
    println(io.stdout);
    printDryRun(io, {
      title: 'Dry run: nothing was written. It would write:',
      root: basename(root),
      entries: [{ path: PROJECT_CONFIG_FILE, action: existsSync(file) ? 'update' : 'create' }],
    });
    return;
  }
  const manifest = await readManifest(root);
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
    'Now "sa add", "sa generate" and "sa config" work in this project. See "sa list".',
  );
}

/** The package.json as an object; one that is not valid JSON is treated as having nothing in it. */
async function readManifest(root: string): Promise<{
  devDependencies?: Record<string, string>;
  dependencies?: Record<string, string>;
}> {
  try {
    return JSON.parse(await readFile(join(root, 'package.json'), 'utf8')) as object;
  } catch {
    return {};
  }
}

/**
 * What detection can only assume (the layout of the shell, the purpose of the Starter SSR) and what is
 * not in the project's files (Git, install) stay as `sa new` recorded them when there is a file.
 */
async function keepRecorded(file: string, detected: StarterOptions): Promise<StarterOptions> {
  let recorded: Partial<StarterOptions>;
  try {
    recorded =
      (JSON.parse(await readFile(file, 'utf8')) as { options?: Partial<StarterOptions> }).options ??
      {};
  } catch {
    return detected;
  }
  return {
    ...detected,
    layout:
      detected.appShell === 'starter' ? (recorded.layout ?? detected.layout) : detected.layout,
    ssrPurpose:
      detected.rendering === 'starter-ssr'
        ? (recorded.ssrPurpose ?? detected.ssrPurpose)
        : detected.ssrPurpose,
    git: recorded.git ?? detected.git,
    install: recorded.install ?? detected.install,
  };
}
