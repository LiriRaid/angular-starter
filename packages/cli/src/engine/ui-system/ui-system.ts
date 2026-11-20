import { join } from 'node:path';
import { RuntimeError } from '../../errors.js';
import { BLUEPRINTS_ROOT, copyBlueprint } from '../blueprint.js';
import { pathExists } from '../fs.js';
import { planEdit, writeEdits } from '../edits/planned.js';
import { addUiSystemToUiTabClass, addUiSystemToUiTabTemplate } from '../edits/ui-system.js';

export { UI_SYSTEM_MARKER } from '../edits/ui-system.js';

const PAGE = 'src/app/features/preference-design';
const TAB = `${PAGE}/tabs/ui-tab`;

export interface UiSystemProject {
  targetDir: string;
  /** The project name, as typed by the user. */
  name: string;
  /** Selector prefix of the application components. */
  prefix: string;
}

/**
 * The UI System (ADR-0010): the catalog of the installed `as-` components, with a live preview of each
 * one, its code and the tokens that change it, inside the UI tab of the design preferences page. The
 * page of the application shell and a component collection must be there already: the UI tab is edited
 * in place, so a tab the developer rewrote stops the stage before anything is written.
 */
export const uiSystemProfile = {
  /** Project files (forward slashes) that must exist once the UI System has been applied. */
  requiredFiles: [
    `${PAGE}/ui-system/ui-system.ts`,
    `${PAGE}/ui-system/ui-system.html`,
    `${PAGE}/ui-system/ui-system.catalog.ts`,
  ],

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
    // The blueprint goes first: it refuses to overwrite before anything else is written.
    await copyBlueprint({
      source: join(BLUEPRINTS_ROOT, 'ui-system'),
      target: targetDir,
      variables: { PROJECT_NAME: name, PREFIX: prefix },
    });
    await writeEdits(planned);
  },
};
