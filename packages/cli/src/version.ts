import { createRequire } from 'node:module';
import { ANGULAR_CLI_VERSION } from './compat.js';

const loadJson = createRequire(import.meta.url);
const manifest = loadJson('../package.json') as { version: string };

export const CLI_VERSION: string = manifest.version;

/** The CLI and the Angular CLI that `sa new` runs, which is the tested one and not the latest. */
export const VERSION_TEXT = `starter-angular ${CLI_VERSION}\nAngular CLI ${ANGULAR_CLI_VERSION}`;
