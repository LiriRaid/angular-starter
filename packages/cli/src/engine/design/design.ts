import { join } from 'node:path';
import { BLUEPRINTS_ROOT, copyBlueprint } from '../blueprint.js';
import { addTestSetupFile } from '../edits/angular-json.js';
import { planEdit, writeEdits } from '../edits/planned.js';
import { addInterFont } from '../edits/html.js';
import { addDesignStyles } from '../edits/styles.js';
import { addProvider } from '../edits/typescript.js';
import { refreshGeneratedReadmes } from '../readme.js';

const ANGULAR_JSON = 'angular.json';
const TEST_SETUP = 'src/test-setup.ts';
const STYLES = 'src/styles.css';
const INDEX_HTML = 'src/index.html';
const APP_CONFIG = 'src/app/app.config.ts';

export interface DesignProject {
  targetDir: string;
  /** The project name, as typed by the user. */
  name: string;
  /** Selector prefix of the application components. */
  prefix: string;
}

/**
 * The design base (ADR-0007), laid out like the reference application: the stylesheets of
 * `src/styles/` imported from `src/styles.css` (Tailwind CSS, the `dark` variant, the cascade
 * layers), the animations in `shared/animations`, the theme service in `core/theme`, the Lucide
 * registration in `core/common/icons` (with the test setup that provides it to the specs), and the
 * generic utilities and data in `shared`. Every file is
 * the developer's to change.
 */
export const designProfile = {
  /** Project files (forward slashes) that must exist once the base has been applied. */
  requiredFiles: [
    'src/styles/theme/theme-styles.css',
    'src/styles/typography/typography-styles.css',
    'src/app/shared/animations/animations.css',
    'src/app/core/theme/theme.service.ts',
    'src/app/core/common/icons/sa-icons.ts',
    'src/app/shared/utils/slugify.ts',
  ],

  async apply({ targetDir, name, prefix }: DesignProject): Promise<void> {
    // Plan every edit first: a file that does not have the expected shape stops the stage before
    // anything is written.
    const planned = [
      await planEdit(targetDir, STYLES, addDesignStyles),
      await planEdit(targetDir, INDEX_HTML, addInterFont),
      await planEdit(targetDir, ANGULAR_JSON, (text) => addTestSetupFile(text, TEST_SETUP)),
      await planEdit(targetDir, APP_CONFIG, (text) =>
        addProvider(
          addProvider(text, 'provideThemeInitializer()', [
            { module: '@core/theme/theme.initializer', names: ['provideThemeInitializer'] },
          ]),
          '{ provide: LUCIDE_ICONS, useExisting: SA_LUCIDE_ICONS }',
          [
            { module: '@lucide/angular', names: ['LUCIDE_ICONS'] },
            { module: '@core/common/icons/lucide-icons.provider', names: ['SA_LUCIDE_ICONS'] },
          ],
        ),
      ),
    ];

    await copyBlueprint({
      source: join(BLUEPRINTS_ROOT, 'design'),
      target: targetDir,
      variables: { PROJECT_NAME: name, PREFIX: prefix },
    });
    await writeEdits(planned);
    await refreshGeneratedReadmes(targetDir);
  },
};
