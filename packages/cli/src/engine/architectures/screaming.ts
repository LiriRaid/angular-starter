import { mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { BLUEPRINTS_ROOT, copyBlueprint, renderTemplate } from '../blueprint.js';
import { EditShapeError, planEdit, writeEdits, type PlannedEdit } from '../edits/planned.js';
import { addPathAliases } from '../edits/tsconfig.js';
import {
  addRouterFeature,
  addRoutes,
  inlineComponentTemplate,
  removeClassProperty,
} from '../edits/typescript.js';
import type { RouteSpec } from '../edits/typescript.js';
import { pathExists } from '../fs.js';
import { applySharedFoundation, planSharedFoundation } from '../shared-foundation.js';
import type { AdoptionReport, ArchitectureProfile } from './profile.js';

const ALIASES = {
  '@core/*': ['./src/app/core/*'],
  '@features/*': ['./src/app/features/*'],
  '@shared/*': ['./src/app/shared/*'],
};

const ROUTES: readonly RouteSpec[] = [
  { path: '', pathMatch: 'full', redirectTo: 'home' },
  { path: 'home', lazy: { file: '@features/home/home.routes', exportName: 'HOME_ROUTES' } },
];

/** The root component renders only the router outlet: the welcome page and its style are not used. */
const rootEdit = (text: string): string =>
  inlineComponentTemplate(removeClassProperty(text, 'App', 'title'), 'App', '<router-outlet />');

/** Routes can bind their data to the inputs of the components they show. */
const configEdit = (text: string): string => addRouterFeature(text, 'withComponentInputBinding');

/** Edits to files `ng new` generates, as functions from the file's text to its new text. */
const EDITS: readonly (readonly [file: string, edit: (text: string) => string])[] = [
  ['tsconfig.json', (text) => addPathAliases(text, ALIASES)],
  ['src/app/app.ts', rootEdit],
  ['src/app/app.config.ts', configEdit],
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

  async plan(files) {
    await files.blueprint(join(BLUEPRINTS_ROOT, 'architectures', 'screaming'));
    for (const [file] of EDITS) await files.edit(file);
    for (const file of REMOVED) await files.remove(file);
  },

  async planAdoption(files) {
    const read = (file: string): Promise<string | undefined> =>
      readFile(join(files.targetDir, file), 'utf8').catch(() => undefined);
    await planSharedFoundation(files, ALIASES, 'the architecture');
    for (const readme of FOLDER_READMES) {
      if (!(await files.exists(readme))) await files.write(readme);
    }

    // Mirrors `adopt`: the skeleton is adapted only while it is as `ng new` leaves it.
    const root = await tryPlan(files.targetDir, 'src/app/app.ts', rootEdit);
    const angularWelcome = (await read('src/app/app.html'))?.includes(WELCOME_TEMPLATE) === true;
    if (angularWelcome && root) await files.edit('src/app/app.ts');
    const current = await read('src/app/app.config.ts');
    const config = await tryPlan(files.targetDir, 'src/app/app.config.ts', configEdit);
    if (config && config.text !== current) await files.edit('src/app/app.config.ts');
    if (!angularWelcome || !root) return;
    await files.remove('src/app/app.html');
    if ((await read('src/app/app.css'))?.trim() === '') await files.remove('src/app/app.css');
    if ((await read('src/app/app.spec.ts'))?.includes(WELCOME_SPEC)) {
      await files.edit('src/app/app.spec.ts');
    }
  },

  async adopt({ targetDir, name, prefix }) {
    const report: AdoptionReport = { adapted: [], removed: [], review: [] };
    const path = (file: string): string => join(targetDir, file);
    const read = (file: string): Promise<string | undefined> =>
      readFile(path(file), 'utf8').catch(() => undefined);
    const variables = { PROJECT_NAME: name, PREFIX: prefix };
    const blueprint = (file: string): Promise<string> =>
      readFile(join(BLUEPRINTS_ROOT, 'architectures', 'screaming', file), 'utf8').then((text) =>
        renderTemplate(text, variables),
      );

    // An alias that points somewhere else stops here, before anything is written.
    const aliases = await applySharedFoundation(targetDir, ALIASES, 'the architecture');
    if (aliases.length > 0) {
      report.adapted.push(
        `tsconfig.json (${aliases.map((alias) => alias.slice(0, -2)).join(', ')})`,
      );
    }

    for (const readme of FOLDER_READMES) {
      if (await pathExists(path(readme))) continue;
      await mkdir(dirname(path(readme)), { recursive: true });
      await writeFile(path(readme), await blueprint(readme));
      report.adapted.push(readme);
    }

    // The files of the Angular skeleton are adapted only while they are as `ng new` leaves them.
    const planned: PlannedEdit[] = [];
    const welcome = await read('src/app/app.html');
    const root = await tryPlan(targetDir, 'src/app/app.ts', rootEdit);
    const angularWelcome = welcome?.includes(WELCOME_TEMPLATE) === true;
    if (angularWelcome && root) planned.push(root);
    else if (angularWelcome) {
      report.review.push({
        file: 'src/app/app.ts',
        reason:
          'it has changes of its own, so it was not adapted. The architecture expects the root component to render only <router-outlet />; change it by hand.',
      });
    } else if (welcome !== undefined) {
      report.review.push({
        file: 'src/app/app.html',
        reason:
          'it holds your own template, so app.ts was not adapted. The architecture expects the root component to render only <router-outlet />; move your template to a feature and change the root by hand.',
      });
    }

    const current = await read('src/app/app.config.ts');
    const config = await tryPlan(targetDir, 'src/app/app.config.ts', configEdit);
    if (!config) {
      report.review.push({
        file: 'src/app/app.config.ts',
        reason:
          'it has no provideRouter(...) call or has changes of its own, so it was not adapted. Add withComponentInputBinding() to the router by hand.',
      });
    } else if (config.text !== current) {
      planned.push(config);
      report.adapted.push('src/app/app.config.ts');
    }
    await writeEdits(planned);

    if (angularWelcome && root) {
      report.adapted.push('src/app/app.ts');
      await rm(path('src/app/app.html'), { force: true });
      report.removed.push('src/app/app.html');
      const style = await read('src/app/app.css');
      if (style === undefined) {
        // Nothing to remove.
      } else if (style.trim() === '') {
        await rm(path('src/app/app.css'), { force: true });
        report.removed.push('src/app/app.css');
      } else {
        report.review.push({
          file: 'src/app/app.css',
          reason:
            'app.ts no longer uses it; delete it or move its styles to the feature that needs them.',
        });
      }
      const spec = await read('src/app/app.spec.ts');
      if (spec?.includes(WELCOME_SPEC)) {
        await writeFile(path('src/app/app.spec.ts'), await blueprint('src/app/app.spec.ts.tpl'));
        report.adapted.push('src/app/app.spec.ts');
      } else if (spec !== undefined) {
        report.review.push({
          file: 'src/app/app.spec.ts',
          reason:
            'it no longer tests what the root component renders; adapt it to the router outlet.',
        });
      }
    }
    return report;
  },
};

/** What Angular's own welcome page says, to tell it from a template the developer wrote. */
const WELCOME_TEMPLATE = 'is only a placeholder';
/** The test `ng new` writes for that welcome page. */
const WELCOME_SPEC = 'should render title';
const FOLDER_READMES = ['core', 'features', 'shared'].map(
  (folder) => `src/app/${folder}/README.md`,
);

/** The planned edit, or nothing when the file is missing or does not have the shape the edit expects. */
async function tryPlan(
  root: string,
  file: string,
  edit: (text: string) => string,
): Promise<PlannedEdit | undefined> {
  try {
    return await planEdit(root, file, edit);
  } catch (error) {
    if (error instanceof EditShapeError) return undefined;
    throw error;
  }
}
