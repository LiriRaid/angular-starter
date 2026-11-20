import { readFile, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { RuntimeError } from '../../errors.js';
import { BLUEPRINTS_ROOT, copyBlueprint } from '../blueprint.js';
import { addStyleEntry } from '../edits/angular-json.js';
import { addProvider } from '../edits/typescript.js';

const ANGULAR_JSON = 'angular.json';
const STYLES = 'src/styles.css';
const APP_CONFIG = 'src/app/app.config.ts';
const DESIGN_ENTRY = 'src/styles/design.css';
const TAILWIND_IMPORT = "@import './styles/tailwind.css';";

export interface DesignProject {
  targetDir: string;
  /** The project name, as typed by the user. */
  name: string;
  /** Selector prefix of the application components. */
  prefix: string;
  /** Whether the project uses Tailwind CSS, so the tokens are also mapped to its theme. */
  tailwind: boolean;
}

/**
 * The design base of ADR-0005: design tokens, light and dark theme, typography and animations as
 * plain CSS registered in `angular.json`; the theme service and the icon registration in `core`;
 * utilities and pipes in `shared`. Every file is the developer's to change.
 */
export const designProfile = {
  /** Project files (forward slashes) that must exist once the base has been applied. */
  requiredFiles: [
    DESIGN_ENTRY,
    'src/styles/tokens.css',
    'src/app/core/theme/theme.service.ts',
    'src/app/core/icons/icons.provider.ts',
    'src/app/shared/utils/slugify.ts',
    'src/app/shared/pipes/initials.pipe.ts',
  ],

  async apply({ targetDir, name, prefix, tailwind }: DesignProject): Promise<void> {
    // Compute every edit first: a file that does not have the expected shape stops the stage
    // before anything is written.
    const edited: [path: string, text: string][] = [];
    const adapt = async (file: string, edit: (text: string) => string): Promise<void> => {
      const path = join(targetDir, file);
      try {
        edited.push([path, edit(await readFile(path, 'utf8'))]);
      } catch (error) {
        const reason = error instanceof Error ? error.message : String(error);
        throw new RuntimeError(`Could not adapt ${file}: ${reason}`);
      }
    };

    await adapt(ANGULAR_JSON, (text) => addStyleEntry(text, DESIGN_ENTRY));
    await adapt(APP_CONFIG, (text) =>
      addProvider(
        addProvider(text, 'provideThemeInitializer()', [
          { module: '@core/theme/theme.initializer', names: ['provideThemeInitializer'] },
        ]),
        'provideAsIcons()',
        [{ module: '@core/icons/icons.provider', names: ['provideAsIcons'] }],
      ),
    );
    if (tailwind) {
      // Tailwind only sees what its own stylesheet imports, so the token mapping is imported there.
      await adapt(STYLES, (text) =>
        text.includes(TAILWIND_IMPORT) ? text : `${text.trimEnd()}\n${TAILWIND_IMPORT}\n`,
      );
    }

    const variables = { PROJECT_NAME: name, PREFIX: prefix };
    await copyBlueprint({ source: join(BLUEPRINTS_ROOT, 'design'), target: targetDir, variables });
    if (tailwind) {
      await copyBlueprint({
        source: join(BLUEPRINTS_ROOT, 'design-tailwind'),
        target: targetDir,
        variables,
      });
    }
    for (const [path, text] of edited) await writeFile(path, text);
  },
};
