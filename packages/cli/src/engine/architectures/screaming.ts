import { readFile, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { RuntimeError } from '../../errors.js';
import { BLUEPRINTS_ROOT, copyBlueprint } from '../blueprint.js';
import { addPathAliases } from '../edits/tsconfig.js';
import { addRouterFeature, addRoutes, removeClassProperty } from '../edits/typescript.js';
import type { RouteSpec } from '../edits/typescript.js';
import type { ArchitectureProfile } from './profile.js';

const ALIASES = {
  '@core/*': ['./src/app/core/*'],
  '@features/*': ['./src/app/features/*'],
  '@shared/*': ['./src/app/shared/*'],
};

const ROUTES: readonly RouteSpec[] = [
  { path: '', pathMatch: 'full', redirectTo: 'home' },
  { path: 'home', lazy: { file: '@features/home/home.routes', exportName: 'HOME_ROUTES' } },
];

/** Edits to files `ng new` generates, as functions from the file's text to its new text. */
const EDITS: readonly (readonly [file: string, edit: (text: string) => string])[] = [
  ['tsconfig.json', (text) => addPathAliases(text, ALIASES)],
  ['src/app/app.ts', (text) => removeClassProperty(text, 'App', 'title')],
  ['src/app/app.config.ts', (text) => addRouterFeature(text, 'withComponentInputBinding')],
  ['src/app/app.routes.ts', (text) => addRoutes(text, ROUTES)],
];

/** Angular's welcome page and its test; the home feature replaces them. */
const PLACEHOLDERS = ['src/app/app.html', 'src/app/app.spec.ts'];

export const screamingProfile: ArchitectureProfile = {
  requiredFiles: [
    'src/app/features/home/home.routes.ts',
    'src/app/features/home/home.ts',
    'src/app/shared/components/index.ts',
  ],

  async apply({ targetDir, name, prefix }) {
    // Compute every edit first: a file that does not have the expected shape stops the stage
    // before anything is written.
    const edited: [path: string, text: string][] = [];
    for (const [file, edit] of EDITS) {
      const path = join(targetDir, file);
      try {
        edited.push([path, edit(await readFile(path, 'utf8'))]);
      } catch (error) {
        const reason = error instanceof Error ? error.message : String(error);
        throw new RuntimeError(`Could not adapt ${file}: ${reason}`);
      }
    }

    await copyBlueprint({
      source: join(BLUEPRINTS_ROOT, 'architectures', 'screaming'),
      target: targetDir,
      variables: { PROJECT_NAME: name, PREFIX: prefix },
      overwrite: PLACEHOLDERS,
    });
    for (const [path, text] of edited) await writeFile(path, text);
  },
};
