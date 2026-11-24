import { mkdtemp, readFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { writeGeneratedWorkspace } from '../../../tests/helpers/generated-workspace.js';
import { screamingProfile } from '../architectures/screaming.js';
import { RENDERING_PROFILES } from './index.js';
import { starterSsrProfile } from './starter-ssr.js';

/** `ng new --ssr` (Angular CLI 22.3) writes this app.config.ts. */
const SSR_APP_CONFIG = `import { ApplicationConfig, provideBrowserGlobalErrorListeners } from '@angular/core';
import { provideRouter } from '@angular/router';
import { routes } from './app.routes';
import { provideClientHydration } from '@angular/platform-browser';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideRouter(routes), provideClientHydration()
  ]
};
`;

let project: string;

beforeEach(async () => {
  project = await mkdtemp(join(tmpdir(), 'sa-ssr-'));
  await writeGeneratedWorkspace(project, { 'src/app/app.config.ts': SSR_APP_CONFIG });
});

afterEach(async () => {
  await rm(project, { recursive: true, force: true });
});

const read = (file: string): Promise<string> => readFile(join(project, file), 'utf8');
const apply = (architecture: string) =>
  starterSsrProfile.apply({ targetDir: project, name: 'demo', prefix: 'acme', architecture });

describe('Starter Angular SSR profile', () => {
  it('is registered for the starter-ssr rendering strategy', () => {
    expect(RENDERING_PROFILES['starter-ssr']).toBe(starterSsrProfile);
  });

  it('turns on incremental hydration, event replay and view transitions', async () => {
    await apply('angular-default');
    const config = await read('src/app/app.config.ts');
    expect(config).toContain(
      'provideClientHydration(withEventReplay(), withIncrementalHydration())',
    );
    expect(config).toContain(
      'provideRouter(routes, withViewTransitions({ skipInitialTransition: true }))',
    );
    expect(config).toContain(
      "import { provideClientHydration, withEventReplay, withIncrementalHydration } from '@angular/platform-browser';",
    );
  });

  it('adds nothing but the configuration without the Screaming architecture', async () => {
    await apply('angular-default');
    await expect(read('src/app/features/home/home.html')).rejects.toThrow();
  });

  describe('on the Screaming architecture', () => {
    beforeEach(async () => {
      await screamingProfile.apply({ targetDir: project, name: 'demo', prefix: 'acme' });
    });

    it('shows a section that hydrates when it scrolls into view', async () => {
      await apply('screaming');
      expect(await read('src/app/features/home/home.html')).toContain(
        '@defer (hydrate on viewport)',
      );
      const home = await read('src/app/features/home/home.ts');
      expect(home).toContain('imports: [HomeDetails]');
      expect(home).toContain("from './home-details/home-details'");
      for (const file of [
        'src/app/features/home/home-details/home-details.ts',
        'src/app/features/home/home-details/home-details.html',
        'src/app/features/home/home-details/home-details.spec.ts',
      ]) {
        await expect(read(file), file).resolves.toBeTypeOf('string');
      }
      expect(await read('src/app/features/home/home-details/home-details.ts')).toContain(
        "selector: 'acme-home-details'",
      );
    });

    it('declares files that exist once it has been applied', async () => {
      await apply('screaming');
      for (const file of starterSsrProfile.requiredFilesFor('screaming')) {
        await expect(read(file), file).resolves.toBeTypeOf('string');
      }
    });
  });

  it('fails clearly, before writing anything, when the project has no SSR configuration', async () => {
    await writeGeneratedWorkspace(project, {
      'src/app/app.config.ts': SSR_APP_CONFIG.replace(', provideClientHydration()', ''),
    });
    await expect(apply('angular-default')).rejects.toThrow(
      /Could not adapt src\/app\/app\.config\.ts/,
    );
  });
});
