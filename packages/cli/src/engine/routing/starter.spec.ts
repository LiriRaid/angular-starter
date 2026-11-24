import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { writeGeneratedWorkspace } from '../../../tests/helpers/generated-workspace.js';
import { BLUEPRINTS_ROOT, listBlueprintFiles } from '../blueprint.js';
import { ROUTING_PROFILES } from './index.js';
import { starterRoutingProfile } from './starter.js';

let project: string;

beforeEach(async () => {
  project = await mkdtemp(join(tmpdir(), 'sa-routing-'));
  await writeGeneratedWorkspace(project);
});

afterEach(async () => {
  await rm(project, { recursive: true, force: true });
});

const read = (file: string): Promise<string> => readFile(join(project, file), 'utf8');
const apply = (name = 'demo') =>
  starterRoutingProfile.apply({ targetDir: project, name, prefix: 'app' });

describe('Starter Angular Routing profile', () => {
  it('is registered for the starter routing', () => {
    expect(ROUTING_PROFILES['starter']).toBe(starterRoutingProfile);
  });

  it('creates the navigation services in core and the tree in features/app-shell', async () => {
    await apply();
    for (const file of [
      'src/app/core/navigation/navigation.types.ts',
      'src/app/core/navigation/breadcrumb.types.ts',
      'src/app/core/navigation/navigation.utils.ts',
      'src/app/core/navigation/navigation.tokens.ts',
      'src/app/core/navigation/breadcrumb.service.ts',
      'src/app/core/navigation/navigation-title.strategy.ts',
      'src/app/core/navigation/navigation.providers.ts',
      'src/app/features/app-shell/navigation/navigation.data.ts',
    ]) {
      await expect(read(file), file).resolves.toBeTypeOf('string');
    }
  });

  it('ships a spec for every piece that has logic', async () => {
    await apply();
    for (const file of [
      'src/app/core/navigation/navigation.utils.spec.ts',
      'src/app/core/navigation/breadcrumb.service.spec.ts',
      'src/app/core/navigation/navigation-title.strategy.spec.ts',
    ]) {
      await expect(read(file), file).resolves.toContain("describe('");
    }
  });

  it('registers the tree through one provideNavigation call with the project name', async () => {
    await apply('my-shop');
    const config = await read('src/app/app.config.ts');
    expect(config).toContain("provideNavigation(APP_NAVIGATION, { appName: 'my-shop' })");
    expect(config).toContain(
      "import { provideNavigation } from '@core/navigation/navigation.providers';",
    );
    expect(config).toContain(
      "import { APP_NAVIGATION } from '@features/app-shell/navigation/navigation.data';",
    );
    expect(config).toContain('provideRouter(routes)');
  });

  it('does not import features or shared from core, and the tree only needs core', async () => {
    await apply();
    for (const file of await listBlueprintFiles(join(BLUEPRINTS_ROOT, 'routing', 'starter'))) {
      const generated = file.replace(/\.tpl$/, '');
      const text = await read(generated);
      if (generated.startsWith('src/app/core/')) {
        expect(text, generated).not.toMatch(/@features\/|@shared\//);
      }
      if (generated.startsWith('src/app/features/')) {
        expect(text, generated).not.toMatch(/@features\//);
      }
    }
  });

  it('leaves no unresolved placeholder in any generated file', async () => {
    await apply();
    for (const file of await listBlueprintFiles(join(BLUEPRINTS_ROOT, 'routing', 'starter'))) {
      const generated = file.replace(/\.tpl$/, '');
      expect(await read(generated), generated).not.toMatch(/__[A-Z_]+__/);
    }
  });

  it('writes nothing when app.config.ts does not have the expected shape', async () => {
    await writeFile(join(project, 'src/app/app.config.ts'), 'export const appConfig = {};\n');
    await expect(apply()).rejects.toThrow(/app\.config\.ts/);
    await expect(read('src/app/core/navigation/navigation.types.ts')).rejects.toThrow();
  });

  it('refuses to overwrite files that already exist', async () => {
    await apply();
    await expect(apply()).rejects.toThrow(/overwrite/);
  });

  it('lists the files the verification stage must find', () => {
    expect(starterRoutingProfile.requiredFiles).toEqual(
      expect.arrayContaining([
        'src/app/core/navigation/breadcrumb.service.ts',
        'src/app/core/navigation/navigation.providers.ts',
        'src/app/features/app-shell/navigation/navigation.data.ts',
      ]),
    );
  });
});
