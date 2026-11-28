import { readFile, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { ALL_COMPONENT_IDS, UI_SYSTEM_COMPONENT_IDS } from '../../config/components.js';
import { RuntimeError } from '../../errors.js';
import {
  BLUEPRINTS_ROOT,
  copyBlueprint,
  listBlueprintFiles,
  renderTemplate,
} from '../blueprint.js';
import { componentsProfile } from '../components/components.js';
import { installedComponentIds } from '../components/installed.js';
import { componentsOfIds } from '../components/manifest.js';
import { pathExists } from '../fs.js';
import type { FilePlan } from '../plan.js';
import { planEdit, writeEdits } from '../edits/planned.js';
import { addUiSystemToUiTabClass, addUiSystemToUiTabTemplate } from '../edits/ui-system.js';
import { selectRegions } from './regions.js';

export { UI_SYSTEM_MARKER } from '../edits/ui-system.js';

const PAGE = 'src/app/features/preference-design';
const TAB = `${PAGE}/tabs/ui-tab`;
const CATALOG = `${PAGE}/ui-system/ui-system.catalog.ts`;
const BLUEPRINT = join(BLUEPRINTS_ROOT, 'ui-system');

export interface UiSystemProject {
  targetDir: string;
  /** The project name, as typed by the user. */
  name: string;
  /** Selector prefix of the application components. */
  prefix: string;
}

/** What `update` found and did (ADR-0024). */
export type CatalogUpdate =
  | { status: 'current' }
  | { status: 'updated'; added: string[] }
  | { status: 'edited'; missing: string[]; edited: string[] };

/** The ids of the components the catalog describes: one `id:` per entry, at the indent of the entries. */
const catalogIdsOf = (catalog: string): string[] =>
  [...catalog.matchAll(/^ {4}id: '([a-z-]+)',$/gm)].map((match) => match[1] ?? '');

/** Every file of the UI System as a project gets it, for the components in `ids`, by project path. */
async function renderFiles(
  ids: ReadonlySet<string>,
  { name, prefix }: Pick<UiSystemProject, 'name' | 'prefix'>,
): Promise<Map<string, string>> {
  const files = new Map<string, string>();
  for (const file of await listBlueprintFiles(BLUEPRINT)) {
    const text = selectRegions(await readFile(join(BLUEPRINT, file), 'utf8'), ids);
    files.set(
      file.replace(/\.tpl$/, ''),
      renderTemplate(text, { PROJECT_NAME: name, PREFIX: prefix }),
    );
  }
  return files;
}

/** The components the project has that the catalog of the UI System does not describe yet. */
async function missingEntries(targetDir: string): Promise<string[]> {
  const catalog = await readFile(join(targetDir, CATALOG), 'utf8').catch(() => undefined);
  if (catalog === undefined) return [];
  const have = new Set(catalogIdsOf(catalog));
  return (await installedComponentIds(targetDir)).filter(
    (id) => ALL_COMPONENT_IDS.includes(id) && !have.has(id),
  );
}

/**
 * The UI System (ADR-0010, ADR-0012, ADR-0024): the catalog of the installed `sa-` components, with every
 * variant of each one in a live preview, the code of the variant that is chosen and the tokens that change
 * it, inside the UI tab of the design preferences page. It is generated for the components the project has
 * (the templates mark what belongs to each one), so a project with a few components gets a catalog of those
 * few. The page of the application shell must be there already: the UI tab is edited in place, so a tab the
 * developer rewrote stops the stage before anything is written.
 */
export const uiSystemProfile = {
  /** Project files (forward slashes) that must exist once the UI System has been applied. */
  requiredFiles: [
    `${PAGE}/ui-system/ui-system.ts`,
    `${PAGE}/ui-system/ui-system.html`,
    `${PAGE}/ui-system/ui-system.catalog.ts`,
    `${PAGE}/ui-system/ui-system.code.ts`,
  ],

  missingEntries,

  async apply({ targetDir, name, prefix }: UiSystemProject): Promise<void> {
    // Plan every edit first: a tab that does not have the expected shape stops the stage before
    // anything is written.
    if (!(await pathExists(join(targetDir, `${TAB}.html`)))) {
      throw new RuntimeError(
        `The design preferences page (${PAGE}) is not in this project: the UI System goes in its UI tab.`,
        'Projects made before ADR-0010 have the preferences drawer instead; add the shell again in a new project to get the page.',
      );
    }
    const planned = [
      await planEdit(targetDir, `${TAB}.html`, (text) => addUiSystemToUiTabTemplate(text, prefix)),
      await planEdit(targetDir, `${TAB}.ts`, addUiSystemToUiTabClass),
    ];
    // Its own interface is drawn with a few components: the ones the project lacks come with it.
    const installed = await installedComponentIds(targetDir);
    const base = UI_SYSTEM_COMPONENT_IDS.filter((id) => !installed.includes(id));
    const ids = new Set([...installed, ...componentsOfIds(base).map(({ id }) => id)]);
    // The blueprint goes first: it refuses to overwrite before anything else is written.
    await copyBlueprint({
      source: BLUEPRINT,
      target: targetDir,
      variables: { PROJECT_NAME: name, PREFIX: prefix },
      transform: (text) => selectRegions(text, ids),
    });
    if (base.length > 0) await componentsProfile.apply({ targetDir, name, prefix, set: base });
    await writeEdits(planned);
  },

  /** The files `apply` would create and change, recorded in `files` without writing anything. */
  async plan(files: FilePlan): Promise<void> {
    await files.edit(`${TAB}.html`);
    await files.edit(`${TAB}.ts`);
    await files.blueprint(BLUEPRINT);
    const base: string[] = [];
    for (const id of UI_SYSTEM_COMPONENT_IDS) {
      if (!(await files.exists(componentsProfile.componentFile(id)))) base.push(id);
    }
    if (base.length > 0) await componentsProfile.plan(files, base);
  },

  /**
   * Brings the catalog up to the components the project has now, by generating the UI System again. Only
   * when its files are exactly as the CLI left them for the components they describe: a file the developer
   * edited is never rewritten, and the report names it and what is missing.
   */
  async update({ targetDir, name, prefix }: UiSystemProject): Promise<CatalogUpdate> {
    const change = await catalogChange({ targetDir, name, prefix });
    for (const [file, content] of change.files) await writeFile(join(targetDir, file), content);
    return change.report;
  },

  /** The files `update` would rewrite, recorded in `files` without writing anything. */
  async planUpdate(
    files: FilePlan,
    { name, prefix }: Omit<UiSystemProject, 'targetDir'>,
  ): Promise<void> {
    const change = await catalogChange({ targetDir: files.targetDir, name, prefix });
    for (const file of change.files.keys()) await files.edit(file);
  },
};

/** What bringing the catalog up to the components of the project would do: the report and the new text of each file. */
async function catalogChange({ targetDir, name, prefix }: UiSystemProject): Promise<{
  report: CatalogUpdate;
  files: Map<string, string>;
}> {
  const catalog = await readFile(join(targetDir, CATALOG), 'utf8').catch(() => undefined);
  if (catalog === undefined) {
    throw new RuntimeError(`The UI System catalog (${CATALOG}) is not in this project.`);
  }
  const have = catalogIdsOf(catalog);
  const missing = await missingEntries(targetDir);
  if (missing.length === 0) return { report: { status: 'current' }, files: new Map() };

  const before = await renderFiles(new Set(have), { name, prefix });
  const edited: string[] = [];
  for (const [file, expected] of before) {
    const actual = await readFile(join(targetDir, file), 'utf8').catch(() => undefined);
    if (actual !== expected) edited.push(file);
  }
  if (edited.length > 0) {
    return { report: { status: 'edited', missing, edited }, files: new Map() };
  }

  const after = await renderFiles(new Set([...have, ...missing]), { name, prefix });
  const changed = new Map([...after].filter(([file, content]) => content !== before.get(file)));
  return { report: { status: 'updated', added: missing }, files: changed };
}
