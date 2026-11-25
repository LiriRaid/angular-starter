import { mkdir, mkdtemp, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { installedComponentIds } from './installed.js';

let project: string;

beforeEach(async () => {
  project = await mkdtemp(join(tmpdir(), 'sa-installed-'));
});

afterEach(async () => {
  await rm(project, { recursive: true, force: true });
});

describe('installedComponentIds', () => {
  it('reads the sa- folders of shared/components, sorted and without the prefix', async () => {
    const shared = join(project, 'src/app/shared/components');
    for (const folder of ['sa-modal', 'sa-button', 'sa-theme-color-picker', 'my-own', 'sa-x']) {
      await mkdir(join(shared, folder), { recursive: true });
    }
    // A file is not a component, and the barrel is not a folder.
    await writeFile(join(shared, 'sa-readme.md'), '');
    await writeFile(join(shared, 'index.ts'), '');
    expect(await installedComponentIds(project)).toEqual([
      'button',
      'modal',
      'theme-color-picker',
      'x',
    ]);
  });

  it('is empty when the project has no components folder', async () => {
    expect(await installedComponentIds(project)).toEqual([]);
  });
});
