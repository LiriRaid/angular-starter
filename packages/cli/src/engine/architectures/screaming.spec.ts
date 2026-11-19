import { mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { parse } from 'jsonc-parser';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { writeGeneratedWorkspace } from '../../../tests/helpers/generated-workspace.js';
import { BLUEPRINTS_ROOT, listBlueprintFiles } from '../blueprint.js';
import { ARCHITECTURE_PROFILES } from './index.js';
import { screamingProfile } from './screaming.js';

let project: string;

beforeEach(async () => {
  project = await mkdtemp(join(tmpdir(), 'as-screaming-'));
  await writeGeneratedWorkspace(project);
});

afterEach(async () => {
  await rm(project, { recursive: true, force: true });
});

const read = (file: string): Promise<string> => readFile(join(project, file), 'utf8');
const apply = (prefix = 'acme') =>
  screamingProfile.apply({ targetDir: project, name: 'demo', prefix });

describe('Screaming Architecture profile', () => {
  it('is registered for the screaming architecture', () => {
    expect(ARCHITECTURE_PROFILES['screaming']).toBe(screamingProfile);
  });

  it('creates the core / features / shared skeleton with a home feature', async () => {
    await apply();
    for (const file of [
      'src/app/core/README.md',
      'src/app/features/README.md',
      'src/app/features/home/home.ts',
      'src/app/features/home/home.html',
      'src/app/features/home/home.css',
      'src/app/features/home/home.routes.ts',
      'src/app/features/home/home.spec.ts',
      'src/app/shared/README.md',
      'src/app/shared/components/index.ts',
    ]) {
      await expect(read(file)).resolves.toBeTypeOf('string');
    }
    expect(await read('src/app/features/home/home.routes.ts')).toContain('HOME_ROUTES');
  });

  it('uses the project name and the selector prefix in the generated feature', async () => {
    await apply('acme');
    expect(await read('src/app/features/home/home.ts')).toContain("selector: 'acme-home'");
    expect(await read('src/app/features/home/home.ts')).toContain("signal('demo')");
    expect(await read('src/app/features/home/home.spec.ts')).toContain('Hello, demo');
  });

  it('leaves no unresolved placeholder in any generated file', async () => {
    await apply();
    for (const file of await listBlueprintFiles(join(BLUEPRINTS_ROOT, 'architectures/screaming'))) {
      const generated = file.replace(/\.tpl$/, '');
      expect(await read(generated), generated).not.toMatch(/__[A-Z_]+__/);
    }
  });

  it('adds the @core, @features and @shared aliases and keeps the rest of tsconfig.json', async () => {
    await apply();
    const text = await read('tsconfig.json');
    expect(text).toContain('/* To learn more about Typescript configuration file');
    const { compilerOptions } = parse(text);
    expect(compilerOptions.paths).toEqual({
      '@core/*': ['./src/app/core/*'],
      '@features/*': ['./src/app/features/*'],
      '@shared/*': ['./src/app/shared/*'],
    });
    expect(compilerOptions.module).toBe('preserve');
  });

  it('routes to the home feature lazily and binds route data to inputs', async () => {
    await apply();
    const routes = await read('src/app/app.routes.ts');
    expect(routes).toContain("redirectTo: 'home'");
    expect(routes).toContain("import('@features/home/home.routes').then((m) => m.HOME_ROUTES)");
    expect(await read('src/app/app.config.ts')).toContain(
      'provideRouter(routes, withComponentInputBinding())',
    );
  });

  it('turns the root component into a router outlet and drops the placeholder', async () => {
    await apply();
    expect(await read('src/app/app.html')).toBe('<router-outlet />\n');
    expect(await read('src/app/app.spec.ts')).not.toContain('Hello');
    const app = await read('src/app/app.ts');
    expect(app).not.toContain('title');
    expect(app).toContain("import { Component } from '@angular/core';");
  });

  it('writes nothing when a generated file does not have the expected shape', async () => {
    await writeFile(join(project, 'src/app/app.routes.ts'), 'export const other = 1;\n');
    await expect(apply()).rejects.toThrow(/routes/);
    await expect(read('src/app/features/home/home.ts')).rejects.toThrow();
    expect(await read('src/app/app.html')).toContain('Hello, demo');
  });

  it('refuses to overwrite a file of the project that is not an Angular placeholder', async () => {
    await mkdir(join(project, 'src/app/features/home'), { recursive: true });
    await writeFile(join(project, 'src/app/features/home/home.ts'), '// mine\n');
    await expect(apply()).rejects.toThrow(/home\.ts/);
    expect(await read('src/app/features/home/home.ts')).toBe('// mine\n');
  });

  it('lists the files the verification stage must find', () => {
    expect(screamingProfile.requiredFiles).toContain('src/app/features/home/home.routes.ts');
    expect(screamingProfile.requiredFiles).toContain('src/app/shared/components/index.ts');
  });
});
