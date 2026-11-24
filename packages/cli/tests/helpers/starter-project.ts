import { join } from 'node:path';
import { expect } from 'vitest';
import { run } from '../../src/main.js';
import { createFakeIo } from './fake-io.js';
import { createFakeRunner, type FakeRunnerOptions } from './fake-runner.js';

/** `ng new --ssr` (Angular CLI 22.3) writes this app.config.ts. */
export const SSR_APP_CONFIG = `import { ApplicationConfig, provideBrowserGlobalErrorListeners } from '@angular/core';
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

/**
 * A project as `sa new` leaves it (with the fake Angular CLI), for the tests of the commands that
 * work on an existing project. Returns its folder.
 */
export async function createStarterProject(
  cwd: string,
  flags: readonly string[] = [],
  runner: FakeRunnerOptions = {},
): Promise<string> {
  const fake = createFakeIo({ cwd });
  const code = await run(
    ['new', 'demo', '--defaults', '--no-install', '--no-git', ...flags],
    fake.io,
    { run: createFakeRunner(runner).run },
  );
  expect(code, fake.err()).toBe(0);
  return join(cwd, 'demo');
}
