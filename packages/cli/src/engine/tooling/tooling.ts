import { readFile } from 'node:fs/promises';
import { join } from 'node:path';
import { parse } from 'jsonc-parser';
import { TOOLING_PACKAGES } from '../../compat.js';
import type { StarterOptions } from '../../config/schema.js';
import { BLUEPRINTS_ROOT, copyBlueprint } from '../blueprint.js';
import { addDevDependencies, addScripts } from '../edits/package-json.js';
import { planEdit, writeEdits, type PlannedEdit } from '../edits/planned.js';
import { pathExists } from '../fs.js';

const CONFIG_FILE = 'eslint.config.mjs';

/** Every file ESLint reads its configuration from (flat and legacy), in the order they are looked for. */
const ESLINT_CONFIG_FILES = [
  'eslint.config.js',
  'eslint.config.mjs',
  'eslint.config.cjs',
  'eslint.config.ts',
  'eslint.config.mts',
  'eslint.config.cts',
  '.eslintrc',
  '.eslintrc.js',
  '.eslintrc.cjs',
  '.eslintrc.json',
  '.eslintrc.yml',
  '.eslintrc.yaml',
];

const ESLINT_PACKAGES = ['@eslint/js', 'angular-eslint', 'eslint', 'typescript-eslint'] as const;

/** The stylesheet extension Prettier formats for each format; indented Sass has no parser in it. */
const STYLE_EXTENSION: Readonly<Record<StarterOptions['style'], string | undefined>> = {
  css: 'css',
  scss: 'scss',
  sass: undefined,
  less: 'less',
};

export interface ToolingProject {
  targetDir: string;
  /** Selector prefix of the application components. */
  prefix: string;
  style: StarterOptions['style'];
}

export interface ToolingReport {
  /** `added` when this run wrote the ESLint setup; `kept` when the project had one already. */
  eslint: 'added' | 'kept';
  /** What the project already had, when `eslint` is `kept`. */
  found?: string;
}

/**
 * Lint and format for every project, whatever its architecture (ADR-0027): the ESLint configuration
 * with Angular's rules, the packages it needs at the versions the CLI was tested with, and the
 * `lint`, `lint:fix`, `format` and `format:check` scripts. Prettier and its `.prettierrc` come from
 * `ng new`. What the developer already has is never replaced: an ESLint setup of their own is kept
 * (and its packages and the lint scripts are left to it), and a script that exists keeps its command.
 */
export const toolingProfile = {
  /** Project files (forward slashes) that must exist once the tooling has been applied to a new project. */
  requiredFiles: [CONFIG_FILE],

  /** True when the project has every piece already, so there is nothing to add. Writes nothing. */
  async isComplete(project: ToolingProject): Promise<boolean> {
    const { manifest, writesConfig } = await plan(project);
    const current = await readFile(manifest.path, 'utf8');
    return !writesConfig && manifest.text === current;
  },

  async apply(project: ToolingProject): Promise<ToolingReport> {
    // The edit is planned first: a package.json that is not valid stops the stage before anything is written.
    const { found, manifest, writesConfig } = await plan(project);
    if (writesConfig) {
      await copyBlueprint({
        source: join(BLUEPRINTS_ROOT, 'tooling'),
        target: project.targetDir,
        variables: { PREFIX: project.prefix },
      });
    }
    await writeEdits([manifest]);
    return found ? { eslint: 'kept', found } : { eslint: 'added' };
  },
};

interface Plan {
  found: string | undefined;
  manifest: PlannedEdit;
  writesConfig: boolean;
}

async function plan({ targetDir, style }: ToolingProject): Promise<Plan> {
  const found = await existingEslintSetup(targetDir);
  const formats = ['ts', 'html', STYLE_EXTENSION[style]].filter(Boolean).join(',');
  const sources = 'src/**/*.{ts,html}';
  const formatted = `src/**/*.{${formats}}`;

  const manifest = await planEdit(targetDir, 'package.json', (text) =>
    addScripts(
      addDevDependencies(text, {
        ...(found ? {} : pick(TOOLING_PACKAGES, ESLINT_PACKAGES)),
        prettier: TOOLING_PACKAGES['prettier'] ?? '',
      }),
      {
        'test:watch': 'ng test --watch',
        ...(found ? {} : { lint: `eslint "${sources}"`, 'lint:fix': `eslint "${sources}" --fix` }),
        format: `prettier --write "${formatted}"`,
        'format:check': `prettier --check "${formatted}"`,
      },
    ),
  );
  return { found, manifest, writesConfig: found === undefined };
}

function pick(
  all: Readonly<Record<string, string>>,
  names: readonly string[],
): Record<string, string> {
  return Object.fromEntries(names.flatMap((name) => (all[name] ? [[name, all[name]]] : [])));
}

/** What the project has to configure ESLint, named as the developer knows it; nothing when it has none. */
async function existingEslintSetup(targetDir: string): Promise<string | undefined> {
  for (const file of ESLINT_CONFIG_FILES) {
    if (await pathExists(join(targetDir, file))) return file;
  }
  const manifest = await readManifest(targetDir);
  return manifest && 'eslintConfig' in manifest ? 'package.json (eslintConfig)' : undefined;
}

async function readManifest(targetDir: string): Promise<Record<string, unknown> | undefined> {
  const text = await readFile(join(targetDir, 'package.json'), 'utf8').catch(() => undefined);
  const manifest: unknown = text === undefined ? undefined : parse(text);
  return manifest && typeof manifest === 'object'
    ? (manifest as Record<string, unknown>)
    : undefined;
}
