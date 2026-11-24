import { join } from 'node:path';
import { BLUEPRINTS_ROOT, copyBlueprint } from '../blueprint.js';
import { planEdit, writeEdits } from '../edits/planned.js';
import { addCallArgument, addComponentImport } from '../edits/typescript.js';
import type { RenderingProfile } from './profile.js';

const APP_CONFIG = 'src/app/app.config.ts';
const HOME_TS = 'src/app/features/home/home.ts';
const HOME_HTML = 'src/app/features/home/home.html';
const PLATFORM_BROWSER = '@angular/platform-browser';

const DEFER_MARKER = '@defer (hydrate on viewport)';

const deferBlock = (prefix: string): string => `
${DEFER_MARKER} {
  <${prefix}-home-details />
} @placeholder {
  <p>This section hydrates when it scrolls into view.</p>
}
`;

/** `provideClientHydration` and `provideRouter` features of the maintainer's portfolio. */
function adaptAppConfig(source: string): string {
  const hydration = [
    ['withEventReplay()', 'withEventReplay'],
    ['withIncrementalHydration()', 'withIncrementalHydration'],
  ] as const;
  let text = source;
  for (const [expression, name] of hydration) {
    text = addCallArgument(text, 'provideClientHydration', expression, [
      { module: PLATFORM_BROWSER, names: [name] },
    ]);
  }
  return addCallArgument(
    text,
    'provideRouter',
    'withViewTransitions({ skipInitialTransition: true })',
    [{ module: '@angular/router', names: ['withViewTransitions'] }],
  );
}

/**
 * Starter Angular SSR: the default Angular SSR plus incremental hydration, event replay and view
 * transitions, with a section of the home page that hydrates when it scrolls into view.
 */
export const starterSsrProfile: RenderingProfile = {
  requiredFilesFor: (architecture) =>
    architecture === 'screaming'
      ? [
          'src/app/features/home/home-details/home-details.ts',
          'src/app/features/home/home-details/home-details.html',
        ]
      : [],

  async apply({ targetDir, prefix, architecture }) {
    // Plan every edit first: a file that does not have the expected shape stops the stage before
    // anything is written.
    const edits = [await planEdit(targetDir, APP_CONFIG, adaptAppConfig)];
    const onHomePage = architecture === 'screaming';
    if (onHomePage) {
      edits.push(
        await planEdit(targetDir, HOME_TS, (text) =>
          addComponentImport(text, 'Home', 'HomeDetails', './home-details/home-details'),
        ),
        await planEdit(targetDir, HOME_HTML, (text) =>
          text.includes(DEFER_MARKER) ? text : `${text.trimEnd()}\n${deferBlock(prefix)}`,
        ),
      );
      await copyBlueprint({
        source: join(BLUEPRINTS_ROOT, 'rendering', 'starter-ssr'),
        target: targetDir,
        variables: { PREFIX: prefix },
      });
    }
    await writeEdits(edits);
  },
};
