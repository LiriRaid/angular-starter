import { readFile, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { RuntimeError } from '../../errors.js';
import { BLUEPRINTS_ROOT, copyBlueprint } from '../blueprint.js';
import { addProvider, quote } from '../edits/typescript.js';
import type { RoutingProfile } from './profile.js';

const APP_CONFIG = 'src/app/app.config.ts';

/** Angular Starter Routing: the navigation tree with its title strategy and breadcrumb service. */
export const starterRoutingProfile: RoutingProfile = {
  requiredFiles: [
    'src/app/core/navigation/breadcrumb.service.ts',
    'src/app/core/navigation/navigation.providers.ts',
    'src/app/features/app-shell/navigation/navigation.data.ts',
  ],

  async apply({ targetDir, name, prefix }) {
    // Compute the edit first: a file that does not have the expected shape stops the stage before
    // anything is written.
    const path = join(targetDir, APP_CONFIG);
    let edited: string;
    try {
      edited = addProvider(
        await readFile(path, 'utf8'),
        `provideNavigation(APP_NAVIGATION, { appName: ${quote(name)} })`,
        [
          { module: '@core/navigation/navigation.providers', names: ['provideNavigation'] },
          { module: '@features/app-shell/navigation/navigation.data', names: ['APP_NAVIGATION'] },
        ],
      );
    } catch (error) {
      const reason = error instanceof Error ? error.message : String(error);
      throw new RuntimeError(`Could not adapt ${APP_CONFIG}: ${reason}`);
    }

    await copyBlueprint({
      source: join(BLUEPRINTS_ROOT, 'routing', 'starter'),
      target: targetDir,
      variables: { PROJECT_NAME: name, PREFIX: prefix },
    });
    await writeFile(path, edited);
  },
};
