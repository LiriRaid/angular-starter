import { rm } from 'node:fs/promises';
import { join } from 'node:path';
import { BLUEPRINTS_ROOT, copyBlueprint } from '../blueprint.js';
import { planEdit, writeEdits } from '../edits/planned.js';
import { addPathAliases } from '../edits/tsconfig.js';
import {
  addRouterFeature,
  addRoutes,
  inlineComponentTemplate,
  removeClassProperty,
} from '../edits/typescript.js';
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
  [
    'src/app/app.ts',
    (text) =>
      inlineComponentTemplate(
        removeClassProperty(text, 'App', 'title'),
        'App',
        '<router-outlet />',
      ),
  ],
  ['src/app/app.config.ts', (text) => addRouterFeature(text, 'withComponentInputBinding')],
  ['src/app/app.routes.ts', (text) => addRoutes(text, ROUTES)],
];

/** Angular's test of the welcome page; the router outlet test replaces it. */
const PLACEHOLDERS = ['src/app/app.spec.ts'];

/** The welcome page and its style: the root component composes the application inline instead. */
const REMOVED = ['src/app/app.html', 'src/app/app.css'];

export const screamingProfile: ArchitectureProfile = {
  requiredFiles: [
    'src/app/features/home/home.routes.ts',
    'src/app/features/home/home.ts',
    'src/app/shared/components/index.ts',
  ],

  async apply({ targetDir, name, prefix }) {
    // Plan every edit first: a file that does not have the expected shape stops the stage before
    // anything is written.
    const planned = [];
    for (const [file, edit] of EDITS) planned.push(await planEdit(targetDir, file, edit));

    await copyBlueprint({
      source: join(BLUEPRINTS_ROOT, 'architectures', 'screaming'),
      target: targetDir,
      variables: { PROJECT_NAME: name, PREFIX: prefix },
      overwrite: PLACEHOLDERS,
    });
    await writeEdits(planned);
    for (const file of REMOVED) await rm(join(targetDir, file), { force: true });
  },
};
