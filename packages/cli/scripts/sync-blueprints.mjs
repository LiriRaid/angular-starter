// Copies the repository's `blueprints/` folder into the package so that it is published with the CLI
// and resolved from one place at run time. Runs before the tests and as the last step of the build.
import { cp, rm } from 'node:fs/promises';
import { URL, fileURLToPath } from 'node:url';

const source = fileURLToPath(new URL('../../../blueprints/', import.meta.url));
const target = fileURLToPath(new URL('../blueprints/', import.meta.url));

await rm(target, { recursive: true, force: true });
await cp(source, target, { recursive: true });
