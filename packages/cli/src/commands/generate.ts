import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { BLUEPRINTS_ROOT, renderTemplate } from '../engine/blueprint.js';
import { addNavigationItem, addRoutes } from '../engine/edits/typescript.js';
import { pathExists } from '../engine/fs.js';
import { RuntimeError, UsageError } from '../errors.js';
import { println, type CliIo } from '../io.js';
import { findProject, type StarterProject } from '../project/find.js';
import { createStyler } from '../ui/format.js';
import { GENERATE_KINDS } from './generate-kinds.js';

export { GENERATE_KINDS };

export interface GenerateFlags {
  feature?: string;
  shared?: boolean;
  /** Folder below `src/app` for a component of a project that is not Screaming. */
  path?: string;
  dryRun?: boolean;
}

const NAME_PATTERN = /^[a-z][a-z0-9]*(-[a-z0-9]+)*$/;
const APP = 'src/app';

/** Everything a generation will do, worked out before anything is written. */
interface Plan {
  /** New files, by project path. */
  create: Map<string, string>;
  /** Existing files with their new text, by project path. */
  update: Map<string, string>;
}

export async function generateCommand(
  io: CliIo,
  kind: string | undefined,
  name: string | undefined,
  flags: GenerateFlags,
): Promise<void> {
  if (kind === undefined || !(GENERATE_KINDS as readonly string[]).includes(kind)) {
    throw new UsageError(
      kind === undefined ? 'Usage: as generate <kind> <name>' : `Unknown kind "${kind}".`,
      `Choose one of: ${GENERATE_KINDS.join(', ')}.`,
    );
  }
  if (name === undefined) throw new UsageError(`Usage: as generate ${kind} <name>`);
  if (!NAME_PATTERN.test(name)) {
    throw new UsageError(
      `Invalid name "${name}": use lowercase letters, numbers and hyphens, starting with a letter.`,
    );
  }

  const project = await findProject(io.cwd);
  const screaming = project.options.architecture === 'screaming';
  if (kind === 'feature' && !screaming) {
    throw new UsageError(
      `"as generate feature" works with the Screaming Architecture; this project uses "${project.options.architecture}".`,
      'Use "as generate component <name>" to make a component, or "ng generate" for other structures.',
    );
  }

  const plan =
    kind === 'feature'
      ? await planFeature(project, name)
      : screaming
        ? await planComponent(project, name, flags)
        : await planPlainComponent(project, name, flags);

  const style = createStyler(io.color);
  if (flags.dryRun) println(io.stdout, style.bold('Dry run: nothing was written. It would:'));
  const verb = flags.dryRun ? ['create', 'update'] : ['created', 'updated'];
  for (const path of plan.create.keys()) println(io.stdout, `  ${verb[0]} ${path}`);
  for (const path of plan.update.keys()) println(io.stdout, `  ${verb[1]} ${path}`);
  if (flags.dryRun) return;

  for (const [path, text] of [...plan.create, ...plan.update]) {
    await mkdir(dirname(join(project.root, path)), { recursive: true });
    await writeFile(join(project.root, path), text);
  }
}

async function planFeature(project: StarterProject, name: string): Promise<Plan> {
  const folder = `${APP}/features/${name}`;
  if (await pathExists(join(project.root, folder))) {
    throw new UsageError(`The feature "${name}" already exists (${folder}); nothing was changed.`);
  }
  const names = namesOf(name);
  const variables = { ...names, PREFIX: project.options.prefix, ROUTES_CONST: names.ROUTES };

  const create = new Map<string, string>();
  for (const [template, extension] of [
    ['feature.ts.tpl', 'ts'],
    ['feature.html.tpl', 'html'],
    ['feature.css.tpl', 'css'],
    ['feature.routes.ts.tpl', 'routes.ts'],
    ['feature.spec.ts.tpl', 'spec.ts'],
  ] as const) {
    create.set(`${folder}/${name}.${extension}`, await render('feature', template, variables));
  }

  const update = new Map<string, string>();
  await edit(project, update, `${APP}/app.routes.ts`, (text) =>
    addRoutes(text, [
      {
        path: name,
        lazy: { file: `@features/${name}/${name}.routes`, exportName: names.ROUTES },
      },
    ]),
  );
  if (project.options.routing === 'starter') {
    await edit(project, update, `${APP}/features/app-shell/navigation/navigation.data.ts`, (text) =>
      addNavigationItem(text, { id: name, title: names.TITLE, link: `/${name}` }),
    );
  }
  return { create, update };
}

async function planComponent(
  project: StarterProject,
  name: string,
  flags: GenerateFlags,
): Promise<Plan> {
  if (flags.path !== undefined) {
    throw new UsageError(
      '--path is for projects that are not Screaming; here --feature <name> or --shared decide where the component lives.',
    );
  }
  if (flags.shared && flags.feature !== undefined) {
    throw new UsageError('Use either --feature <name> or --shared, not both.');
  }
  if (!flags.shared && flags.feature === undefined) {
    throw new UsageError('Choose where the component lives with --feature <name> or --shared.');
  }

  let folder: string;
  if (flags.feature === undefined) {
    folder = `${APP}/shared/components/${name}`;
  } else {
    if (!(await pathExists(join(project.root, `${APP}/features/${flags.feature}`)))) {
      throw new UsageError(
        `The feature "${flags.feature}" does not exist; create it with "as generate feature ${flags.feature}".`,
      );
    }
    folder = `${APP}/features/${flags.feature}/${name}`;
  }
  return componentPlan(project, name, folder, flags.shared === true);
}

/** The files of a component in `folder`, and the barrel line when it is a shared one. */
async function componentPlan(
  project: StarterProject,
  name: string,
  folder: string,
  shared: boolean,
): Promise<Plan> {
  if (await pathExists(join(project.root, folder))) {
    throw new UsageError(
      `The component "${name}" already exists (${folder}); nothing was changed.`,
    );
  }

  const names = namesOf(name);
  const variables = { ...names, PREFIX: project.options.prefix };
  const create = new Map<string, string>();
  for (const [template, extension] of [
    ['component.ts.tpl', 'ts'],
    ['component.html.tpl', 'html'],
    ['component.css.tpl', 'css'],
    ['component.spec.ts.tpl', 'spec.ts'],
  ] as const) {
    create.set(`${folder}/${name}.${extension}`, await render('component', template, variables));
  }

  const update = new Map<string, string>();
  if (shared) {
    const barrel = `${APP}/shared/components/index.ts`;
    const line = `export { ${names.CLASS} } from './${name}/${name}';`;
    // The generated barrel starts as `export {};`, which stops being needed with the first export.
    await edit(project, update, barrel, (text) =>
      text.includes(line) ? text : `${text.replace(/^export \{\};\n/m, '').trimEnd()}\n${line}\n`,
    );
  }
  return { create, update };
}

/**
 * A component in a project that is not Screaming, like `ng generate component`: its folder below
 * `src/app`, or below the `--path` folder (ADR-0019).
 */
async function planPlainComponent(
  project: StarterProject,
  name: string,
  flags: GenerateFlags,
): Promise<Plan> {
  if (flags.shared || flags.feature !== undefined) {
    throw new UsageError(
      '--feature and --shared are places of the Screaming Architecture.',
      `This project uses "${project.options.architecture}": use "as generate component ${name}" or --path <folder> below src/app.`,
    );
  }
  const parent = flags.path === undefined ? APP : `${APP}/${plainPathOf(flags.path)}`;
  return componentPlan(project, name, `${parent}/${name}`, false);
}

/** A folder below src/app: relative, without `..` and without a leading slash. */
function plainPathOf(path: string): string {
  const segments = path
    .replaceAll('\\', '/')
    .split('/')
    .filter((segment) => segment !== '' && segment !== '.');
  if (
    path.startsWith('/') ||
    /^[a-zA-Z]:/.test(path) ||
    segments.includes('..') ||
    segments.length === 0
  ) {
    throw new UsageError(`Invalid --path "${path}": use a folder below src/app, like billing/ui.`);
  }
  return segments.join('/');
}

/** The forms of a kebab-case name the templates use. */
function namesOf(name: string): Record<'NAME' | 'CLASS' | 'TITLE' | 'ROUTES', string> {
  const words = name.split('-');
  const sentence = words.join(' ');
  return {
    NAME: name,
    CLASS: words.map((word) => word.charAt(0).toUpperCase() + word.slice(1)).join(''),
    TITLE: sentence.charAt(0).toUpperCase() + sentence.slice(1),
    ROUTES: `${words.join('_').toUpperCase()}_ROUTES`,
  };
}

async function render(
  folder: string,
  template: string,
  variables: Readonly<Record<string, string>>,
): Promise<string> {
  const text = await readFile(join(BLUEPRINTS_ROOT, 'generate', folder, template), 'utf8');
  return renderTemplate(text, variables);
}

/** Computes the new text of an existing file; a file that does not have the expected shape fails. */
async function edit(
  project: StarterProject,
  update: Map<string, string>,
  path: string,
  change: (text: string) => string,
): Promise<void> {
  try {
    update.set(path, change(await readFile(join(project.root, path), 'utf8')));
  } catch (error) {
    const reason = error instanceof Error ? error.message : String(error);
    throw new RuntimeError(`Could not adapt ${path}: ${reason}`);
  }
}
