import { join } from 'node:path';
import { BLUEPRINTS_ROOT, copyBlueprint } from '../blueprint.js';
import { planEdit, writeEdits } from '../edits/planned.js';
import { addProvider, quote } from '../edits/typescript.js';
import type { RoutingProfile } from './profile.js';

const APP_CONFIG = 'src/app/app.config.ts';

/** Starter Angular Routing: the navigation tree with its title strategy and breadcrumb service. */
export const starterRoutingProfile: RoutingProfile = {
  requiredFiles: [
    'src/app/core/navigation/breadcrumb.service.ts',
    'src/app/core/navigation/navigation.providers.ts',
    'src/app/features/app-shell/navigation/navigation.data.ts',
  ],

  async apply({ targetDir, name, prefix }) {
    // Plan the edit first: a file that does not have the expected shape stops the stage before
    // anything is written.
    const planned = await planEdit(targetDir, APP_CONFIG, (text) =>
      addProvider(text, `provideNavigation(APP_NAVIGATION, { appName: ${quote(name)} })`, [
        { module: '@core/navigation/navigation.providers', names: ['provideNavigation'] },
        { module: '@features/app-shell/navigation/navigation.data', names: ['APP_NAVIGATION'] },
      ]),
    );

    await copyBlueprint({
      source: join(BLUEPRINTS_ROOT, 'routing', 'starter'),
      target: targetDir,
      variables: { PROJECT_NAME: name, PREFIX: prefix },
    });
    await writeEdits([planned]);
  },

  async plan(files) {
    await files.blueprint(join(BLUEPRINTS_ROOT, 'routing', 'starter'));
    await files.edit(APP_CONFIG);
  },
};
