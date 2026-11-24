import { readFile, readdir } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { normalizeComponents } from '../config/components.js';
import { RESERVED_PREFIX, type StarterOptions } from '../config/schema.js';
import { UsageError } from '../errors.js';
import { pathExists } from './fs.js';

export interface Detection {
  options: StarterOptions;
  /** What the detection assumed or could not tell, for the developer to read. */
  notes: string[];
}

const DEFAULT_PREFIX = 'app';
const SHARED_COMPONENTS = 'src/app/shared/components';

/**
 * What an existing Angular project already has, as the options `sa new` would have recorded for it
 * (ADR-0019). What cannot be told is recorded as the option that adds nothing, so `sa add` can still
 * offer it. It reads files and never changes anything.
 */
export async function detectProject(root: string): Promise<Detection> {
  const angularJson = await readText(root, 'angular.json');
  if (angularJson === undefined) {
    throw new UsageError(
      `This is not an Angular workspace: angular.json was not found in ${root}.`,
      'Run the command in the folder of the project, next to angular.json.',
    );
  }
  const notes: string[] = [];
  const manifest = parseJson(await readText(root, 'package.json'));
  const dependencies = {
    ...asRecord(manifest['dependencies']),
    ...asRecord(manifest['devDependencies']),
  };
  const appConfig = (await readText(root, 'src/app/app.config.ts')) ?? '';
  const has = (path: string): Promise<boolean> => pathExists(join(root, path));

  const folders =
    (await has('src/app/core')) && (await has('src/app/features')) && (await has('src/app/shared'));
  const aliased = ((await readText(root, 'tsconfig.json')) ?? '').includes('"@features/*"');
  const screaming = folders && aliased;
  const starterSsr =
    '@angular/ssr' in dependencies && appConfig.includes('withIncrementalHydration');
  const shell = await has('src/app/features/app-shell/layout/main/main.ts');
  const componentIds = await componentsIn(root);

  const options: StarterOptions = {
    architecture: screaming ? 'screaming' : 'angular-default',
    routing: (await has('src/app/features/app-shell/navigation/navigation.data.ts'))
      ? 'starter'
      : 'angular',
    style: await styleOf(root),
    tailwind: 'tailwindcss' in dependencies,
    rendering: starterSsr ? 'starter-ssr' : '@angular/ssr' in dependencies ? 'ssr' : 'csr',
    ssrPurpose: starterSsr ? 'backoffice' : 'none',
    appShell: shell ? 'starter' : 'none',
    layout: shell ? 'floating-wide' : 'none',
    presence: (await has('src/app/core/presence/presence.service.ts')) ? 'starter' : 'none',
    ...normalizeComponents(componentIds),
    uiSystem: (await has('src/app/features/preference-design/ui-system/ui-system.ts'))
      ? 'starter'
      : 'none',
    icons: '@lucide/angular' in dependencies ? 'lucide' : 'none',
    packageManager: await packageManagerOf(root, manifest),
    prefix: prefixOf(angularJson, notes),
    git: await has('.git'),
    install: true,
  };

  if (starterSsr)
    notes.push(
      'Starter SSR recognised by its incremental hydration; its purpose is assumed to be the backoffice.',
    );
  if (shell) notes.push('The application shell is assumed to use the floating wide layout.');
  if (folders && !aliased) {
    notes.push(
      'The project has core, features and shared but not the @features alias of the Screaming Architecture; it is recorded as angular-default.',
    );
  }
  return { options, notes };
}

async function readText(root: string, path: string): Promise<string | undefined> {
  return readFile(join(root, path), 'utf8').catch(() => undefined);
}

function parseJson(text: string | undefined): Record<string, unknown> {
  try {
    return asRecord(text === undefined ? undefined : JSON.parse(text));
  } catch {
    return {};
  }
}

function asRecord(value: unknown): Record<string, unknown> {
  return value && typeof value === 'object' && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : {};
}

async function styleOf(root: string): Promise<StarterOptions['style']> {
  for (const style of ['scss', 'sass', 'less'] as const) {
    if (await pathExists(join(root, `src/styles.${style}`))) return style;
  }
  return 'css';
}

async function packageManagerOf(
  root: string,
  manifest: Record<string, unknown>,
): Promise<StarterOptions['packageManager']> {
  if (await pathExists(join(root, 'pnpm-lock.yaml'))) return 'pnpm';
  if (await pathExists(join(root, 'yarn.lock'))) return 'yarn';
  if (await pathExists(join(root, 'package-lock.json'))) return 'npm';
  const field = String(manifest['packageManager'] ?? '');
  if (field.startsWith('pnpm@')) return 'pnpm';
  if (field.startsWith('yarn@')) return 'yarn';
  return 'npm';
}

/** The selector prefix of the first application; the reserved one is replaced, with a note. */
function prefixOf(angularJson: string, notes: string[]): string {
  const projects = asRecord(parseJson(angularJson)['projects']);
  const first = asRecord(Object.values(projects)[0]);
  const prefix =
    typeof first['prefix'] === 'string' && first['prefix'] !== ''
      ? first['prefix']
      : DEFAULT_PREFIX;
  if (prefix === RESERVED_PREFIX) {
    notes.push(
      `The prefix "${RESERVED_PREFIX}" is reserved for Starter Angular components; "${DEFAULT_PREFIX}" is recorded instead.`,
    );
    return DEFAULT_PREFIX;
  }
  return prefix;
}

/** The ids of the `sa-` components that are in `shared/components`. */
async function componentsIn(root: string): Promise<string[]> {
  const entries = await readdir(join(root, SHARED_COMPONENTS), { withFileTypes: true }).catch(
    () => [],
  );
  return entries
    .filter((entry) => entry.isDirectory() && entry.name.startsWith('sa-'))
    .map((entry) => entry.name.slice('sa-'.length));
}

/** The closest folder, from `startDir` upwards, that holds an `angular.json`. */
export async function findWorkspace(startDir: string): Promise<string | undefined> {
  let directory = startDir;
  for (;;) {
    if (await pathExists(join(directory, 'angular.json'))) return directory;
    const parent = dirname(directory);
    if (parent === directory) return undefined;
    directory = parent;
  }
}
