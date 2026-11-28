import { join } from 'node:path';
import { BLUEPRINTS_ROOT, copyBlueprint } from '../blueprint.js';
import { addPresenceToUserMenuClass, addPresenceToUserMenuTemplate } from '../edits/presence.js';
import { planEdit, writeEdits, type PlannedEdit } from '../edits/planned.js';
import { addFeatureStyles } from '../edits/styles.js';
import { addProvider } from '../edits/typescript.js';
import { addWelcomeCard } from '../edits/welcome.js';
import { pathExists } from '../fs.js';
import type { FilePlan } from '../plan.js';
import { planGeneratedReadmes, refreshGeneratedReadmes } from '../readme.js';

const APP_CONFIG = 'src/app/app.config.ts';
const STYLES = 'src/styles.css';
const MENU = 'src/app/features/app-shell/layout/sidebar/user-menu';
const WELCOME_DATA = 'src/app/features/home/home.data.ts';

export interface PresenceProject {
  targetDir: string;
  /** The project name, as typed by the user. */
  name: string;
  /** Selector prefix of the application components. */
  prefix: string;
}

/**
 * Presence (ADR-0009): `core/presence` (the service, the transport contract and its two transports),
 * the status row of the user menu of the application shell, its stylesheet, `docs/presence.md` and the
 * `providePresence()` of the application config. The shell must be there already: the menu is edited
 * in place, so a file the developer reshaped stops the stage before anything is written.
 */
export const presenceProfile = {
  /** Project files (forward slashes) that must exist once presence has been applied. */
  requiredFiles: [
    'src/app/core/presence/presence.service.ts',
    'src/app/core/presence/presence.transport.ts',
    'src/app/core/presence/presence.providers.ts',
    'src/app/core/presence/live-presence.service.ts',
    `${MENU}/user-status.ts`,
    'src/styles/features/presence-styles.css',
    'docs/presence.md',
  ],

  async apply({ targetDir, name, prefix }: PresenceProject): Promise<void> {
    // Plan every edit first: a file that does not have the expected shape stops the stage before
    // anything is written.
    const planned: PlannedEdit[] = [
      await planEdit(targetDir, APP_CONFIG, (text) =>
        addProvider(text, 'providePresence()', [
          { module: '@core/presence/presence.providers', names: ['providePresence'] },
        ]),
      ),
      await planEdit(targetDir, STYLES, (text) => addFeatureStyles(text, ['presence-styles'])),
      await planEdit(targetDir, `${MENU}/user-menu.html`, addPresenceToUserMenuTemplate),
      await planEdit(targetDir, `${MENU}/user-menu.ts`, addPresenceToUserMenuClass),
    ];
    // The welcome page is a nicety: a project that replaced it just does not get the card.
    if (await pathExists(join(targetDir, WELCOME_DATA))) {
      const card = await planEdit(targetDir, WELCOME_DATA, (text) =>
        addWelcomeCard(text, {
          id: 'presence',
          title: 'Presence',
          description:
            'The status of the user and of the rest of the team in real time: the menu of the sidebar, the dots of the avatars and a guide to connect your server.',
          icon: 'Plug',
          docs: 'docs/presence.md',
        }),
      ).catch(() => undefined);
      if (card) planned.push(card);
    }

    // The blueprint goes first: it refuses to overwrite before anything else is written.
    await copyBlueprint({
      source: join(BLUEPRINTS_ROOT, 'presence'),
      target: targetDir,
      variables: { PROJECT_NAME: name, PREFIX: prefix },
    });
    await writeEdits(planned);
    await refreshGeneratedReadmes(targetDir);
  },

  /** The files `apply` would create and change, recorded in `files` without writing anything. */
  async plan(files: FilePlan): Promise<void> {
    for (const file of [APP_CONFIG, STYLES, `${MENU}/user-menu.html`, `${MENU}/user-menu.ts`]) {
      await files.edit(file);
    }
    if (await files.exists(WELCOME_DATA)) await files.edit(WELCOME_DATA);
    await files.blueprint(join(BLUEPRINTS_ROOT, 'presence'));
    await planGeneratedReadmes(files, { styles: true });
  },
};
