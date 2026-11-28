import { join } from 'node:path';
import { COMPONENT_PACKAGES } from '../../compat.js';
import { BLUEPRINTS_ROOT, copyBlueprint } from '../blueprint.js';
import { addDependencies } from '../edits/package-json.js';
import { planEdit, writeEdits } from '../edits/planned.js';
import { addComponentStyles } from '../edits/styles.js';
import { pathExists } from '../fs.js';
import type { FilePlan } from '../plan.js';
import { planGeneratedReadmes, refreshGeneratedReadmes } from '../readme.js';
import {
  barrelLines,
  componentsOf,
  componentsOfIds,
  stylesOf,
  type ComponentSet,
} from './manifest.js';

const SHARED = 'src/app/shared/components';
const BARREL = `${SHARED}/index.ts`;
const STYLES = 'src/styles.css';
const PACKAGE_JSON = 'package.json';

export interface ComponentsProject {
  targetDir: string;
  name: string;
  prefix: string;
  /** A collection, or the ids of the components a feature of the starter needs. */
  set: ComponentSet | readonly string[];
}

const componentFile = (id: string): string => `${SHARED}/sa-${id}/sa-${id}.ts`;

const definitionsOf = (set: ComponentSet | readonly string[]) =>
  typeof set === 'string' ? componentsOf(set) : componentsOfIds(set);

/**
 * The native `sa-` components (ADR-0007): the collection's folders under `shared/components`, each
 * with its spec, their global stylesheets imported from `styles.css`, the packages they import (the
 * CDK) and their exports in the
 * `@shared/components` barrel. A component that is already in the project is left alone, so a bigger
 * collection can be added later without touching what the developer has changed.
 */
export const componentsProfile = {
  /** Project files (forward slashes) that must exist once the collection has been applied. */
  requiredFilesFor: (set: ComponentSet | readonly string[]): string[] =>
    definitionsOf(set).map(({ id }) => componentFile(id)),

  /** The main file of a component; the project has the component when it has this file. */
  componentFile,

  async apply({ targetDir, name, prefix, set }: ComponentsProject): Promise<void> {
    const definitions = definitionsOf(set);

    // Plan every edit first: a project without the barrel or the design base stops the stage
    // before anything is written.
    const planned = [
      await planEdit(targetDir, BARREL, (current) => {
        const missing = barrelLines(definitions).filter((line) => !current.includes(line));
        if (missing.length === 0) return current;
        // The generated barrel is `export {};`, which stops being needed with the first export.
        return `${current.replace(/^export \{\};\n/m, '').trimEnd()}\n${missing.join('\n')}\n`;
      }),
      await planEdit(targetDir, STYLES, (text) => addComponentStyles(text, stylesOf(definitions))),
      await planEdit(targetDir, PACKAGE_JSON, (text) => addDependencies(text, COMPONENT_PACKAGES)),
    ];

    for (const { id } of definitions) {
      if (await pathExists(join(targetDir, SHARED, `sa-${id}`))) continue;
      await copyBlueprint({
        source: join(BLUEPRINTS_ROOT, 'components', `sa-${id}`),
        target: targetDir,
        variables: { PROJECT_NAME: name, PREFIX: prefix },
        // The flags sprite is an asset the project may already serve: it is replaced, not a collision.
        overwrite: ['public/assets/flags-sprite.svg'],
      });
    }
    await writeEdits(planned);
    await refreshGeneratedReadmes(targetDir);
  },

  /** The files `apply` would create and change, recorded in `files` without writing anything. */
  async plan(files: FilePlan, set: ComponentSet | readonly string[]): Promise<void> {
    for (const { id } of definitionsOf(set)) {
      if (await files.exists(componentFile(id))) continue;
      await files.blueprint(join(BLUEPRINTS_ROOT, 'components', `sa-${id}`));
    }
    for (const file of [BARREL, STYLES, PACKAGE_JSON]) await files.edit(file);
    await planGeneratedReadmes(files, { components: true, styles: true });
  },
};
