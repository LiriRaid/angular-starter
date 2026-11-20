import { readFile, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { RuntimeError } from '../../errors.js';
import { BLUEPRINTS_ROOT, copyBlueprint } from '../blueprint.js';
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
 * Angular Starter SSR: the default Angular SSR plus incremental hydration, event replay and view
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
    // Compute every edit first: a file that does not have the expected shape stops the stage
    // before anything is written.
    const edits: [path: string, text: string][] = [];
    const adapt = async (file: string, edit: (text: string) => string): Promise<void> => {
      const path = join(targetDir, file);
      try {
        edits.push([path, edit(await readFile(path, 'utf8'))]);
      } catch (error) {
        const reason = error instanceof Error ? error.message : String(error);
        throw new RuntimeError(`Could not adapt ${file}: ${reason}`);
      }
    };

    await adapt(APP_CONFIG, adaptAppConfig);
    const onHomePage = architecture === 'screaming';
    if (onHomePage) {
      await adapt(HOME_TS, (text) =>
        addComponentImport(text, 'Home', 'HomeDetails', './home-details/home-details'),
      );
      await adapt(HOME_HTML, (text) =>
        text.includes(DEFER_MARKER) ? text : `${text.trimEnd()}\n${deferBlock(prefix)}`,
      );
      await copyBlueprint({
        source: join(BLUEPRINTS_ROOT, 'rendering', 'starter-ssr'),
        target: targetDir,
        variables: { PREFIX: prefix },
      });
    }
    for (const [path, text] of edits) await writeFile(path, text);
  },
};
