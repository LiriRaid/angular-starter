import { createRequire } from 'node:module';

const loadJson = createRequire(import.meta.url);
const manifest = loadJson('../package.json') as { version: string };

export const CLI_VERSION: string = manifest.version;
