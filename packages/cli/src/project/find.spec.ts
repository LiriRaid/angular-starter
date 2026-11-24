import { mkdir, mkdtemp, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { UsageError } from '../errors.js';
import { findProject } from './find.js';

/** The options of a project made before presence, the purpose, the layout and the UI System existed. */
const OLD_OPTIONS = {
  architecture: 'screaming',
  routing: 'starter',
  style: 'css',
  tailwind: true,
  rendering: 'csr',
  appShell: 'starter',
  components: 'recommended',
  icons: 'lucide',
  packageManager: 'npm',
  prefix: 'app',
  git: true,
  install: true,
};

let root: string;

beforeEach(async () => {
  root = await mkdtemp(join(tmpdir(), 'sa-find-'));
});

afterEach(async () => {
  await rm(root, { recursive: true, force: true });
});

async function project(options: Record<string, unknown>): Promise<string> {
  await writeFile(
    join(root, 'starter-angular.config.json'),
    JSON.stringify({ schemaVersion: 1, options }),
  );
  await writeFile(join(root, 'package.json'), JSON.stringify({ name: 'shop' }));
  return root;
}

describe('findProject', () => {
  it('reads a project made before the purpose, the layout and the UI System existed', async () => {
    const found = await findProject(await project(OLD_OPTIONS));
    expect(found.options).toMatchObject({
      presence: 'none',
      ssrPurpose: 'none',
      layout: 'floating-wide',
      uiSystem: 'none',
    });
  });

  it('derives what an old project had from what it already chose', async () => {
    const noShell = await findProject(await project({ ...OLD_OPTIONS, appShell: 'none' }));
    expect(noShell.options).toMatchObject({ layout: 'none', ssrPurpose: 'none' });

    const server = await findProject(
      await project({ ...OLD_OPTIONS, appShell: 'none', rendering: 'starter-ssr' }),
    );
    expect(server.options.ssrPurpose).toBe('backoffice');
  });

  it('keeps what the project recorded', async () => {
    const found = await findProject(
      await project({
        ...OLD_OPTIONS,
        layout: 'floating-wide',
        uiSystem: 'none',
        ssrPurpose: 'none',
      }),
    );
    expect(found.options.layout).toBe('floating-wide');
  });

  it('walks up from a folder of the project', async () => {
    await project(OLD_OPTIONS);
    const inner = join(root, 'src', 'app');
    await mkdir(inner, { recursive: true });
    expect((await findProject(inner)).root).toBe(root);
  });

  it('refuses a configuration with an unknown value', async () => {
    await expect(findProject(await project({ ...OLD_OPTIONS, layout: 'wide' }))).rejects.toThrow(
      UsageError,
    );
  });
});
