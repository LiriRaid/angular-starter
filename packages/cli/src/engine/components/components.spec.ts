import { mkdtemp, readFile, readdir, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { writeGeneratedWorkspace } from '../../../tests/helpers/generated-workspace.js';
import { screamingProfile } from '../architectures/screaming.js';
import { BLUEPRINTS_ROOT, listBlueprintFiles } from '../blueprint.js';
import { designProfile } from '../design/design.js';
import { COMPONENTS, EXTRA_COMPONENTS, RECOMMENDED_COMPONENTS, componentsOf } from './manifest.js';
import { componentsProfile } from './components.js';

const COMPONENTS_ROOT = join(BLUEPRINTS_ROOT, 'components');
const SHARED = 'src/app/shared/components';

describe('component manifest', () => {
  it('has the 16 components of the recommended collection', () => {
    expect(RECOMMENDED_COMPONENTS).toEqual([
      'icon',
      'button',
      'input',
      'textarea',
      'checkbox',
      'toggle',
      'select',
      'avatar',
      'divider',
      'skeleton',
      'tooltip',
      'modal',
      'drawer',
      'toast',
      'tabs',
      'popover',
    ]);
  });

  it('adds what each component needs to the collection, without repeating it', () => {
    const ids = componentsOf('recommended').map((component) => component.id);
    expect(new Set(ids).size).toBe(ids.length);
    expect(ids).toContain('form-control');
    expect(ids).toContain('icon');
    expect(ids.length).toBe(17);
  });

  it('keeps the "all" collection a superset of the recommended one', () => {
    const recommended = componentsOf('recommended').map((component) => component.id);
    const all = componentsOf('all').map((component) => component.id);
    expect(all).toEqual(expect.arrayContaining(recommended));
    expect(EXTRA_COMPONENTS).toHaveLength(10);
    expect(all).toEqual(expect.arrayContaining([...EXTRA_COMPONENTS]));
  });

  it.each(COMPONENTS.map((component) => [component.id, component] as const))(
    '%s has its blueprint, spec and barrel exports',
    async (_id, component) => {
      const folder = join(COMPONENTS_ROOT, `as-${component.id}`, 'src/app/shared/components');
      const files = await listBlueprintFiles(folder);
      const own = files.filter((file) => file.startsWith(`as-${component.id}/`));
      expect(
        own.some((file) => file.endsWith('.spec.ts.tpl')),
        'spec',
      ).toBe(true);
      expect(
        own.some((file) => file.endsWith('.ts.tpl') && !file.includes('.spec.')),
        'class',
      ).toBe(true);

      for (const entry of component.exports) {
        const source = await readFile(join(folder, `${entry.from}.ts.tpl`), 'utf8');
        for (const name of entry.names) {
          const bare = name.replace(/^type /, '');
          expect(source, `${entry.from} exports ${bare}`).toMatch(
            new RegExp(`export (abstract )?(class|interface|type|const|function) ${bare}\\b`),
          );
        }
      }
    },
  );
});

describe('component blueprints follow the rules of the starter', () => {
  async function sources(): Promise<{ file: string; text: string }[]> {
    const entries = await readdir(COMPONENTS_ROOT, { recursive: true, withFileTypes: true });
    const found: { file: string; text: string }[] = [];
    for (const entry of entries.filter((item) => item.isFile())) {
      const path = join(entry.parentPath, entry.name);
      if (entry.name.endsWith('.ts.tpl'))
        found.push({ file: path, text: await readFile(path, 'utf8') });
    }
    return found;
  }

  it('never import from features and only from core outside their own folder', async () => {
    for (const { file, text } of await sources()) {
      for (const match of text.matchAll(/from '(@[^']+)'/g)) {
        const module = match[1] ?? '';
        if (module.startsWith('@angular/') || module.startsWith('@lucide/')) continue;
        expect(module, file).toMatch(/^@core\//);
      }
    }
  });

  it('are OnPush, standalone and prefixed with as-', async () => {
    for (const { file, text } of await sources()) {
      if (file.includes('.spec.') || !text.includes('@Component(')) continue;
      expect(text, file).toContain('ChangeDetectionStrategy.OnPush');
      expect(text, file).toMatch(/selector: 'as-[a-z-]+'/);
      expect(text, file).not.toContain('standalone:');
      expect(text, file).not.toContain('NgModule');
    }
  });

  it('render icons only through as-icon', async () => {
    for (const { file, text } of await sources()) {
      if (file.includes('as-icon')) continue;
      expect(text, file).not.toContain('lucideIcon');
      expect(text, file).not.toContain('@lucide/angular');
    }
  });

  it('do not depend on Tailwind', async () => {
    const entries = await readdir(COMPONENTS_ROOT, { recursive: true, withFileTypes: true });
    for (const entry of entries.filter((item) => item.isFile())) {
      const text = await readFile(join(entry.parentPath, entry.name), 'utf8');
      expect(text, entry.name).not.toMatch(/@apply|@tailwind|tailwindcss/);
    }
  });
});

describe('components profile', () => {
  let project: string;

  beforeEach(async () => {
    project = await mkdtemp(join(tmpdir(), 'as-components-'));
    await writeGeneratedWorkspace(project, {
      'angular.json':
        '{ "projects": { "demo": { "architect": { "build": { "options": { "styles": ["src/styles.css"] } } } } } }\n',
      'src/styles.css': '@import "tailwindcss";\n',
    });
    await screamingProfile.apply({ targetDir: project, name: 'demo', prefix: 'app' });
    await designProfile.apply({ targetDir: project, name: 'demo', prefix: 'app', tailwind: true });
  });

  afterEach(async () => {
    await rm(project, { recursive: true, force: true });
  });

  const read = (file: string): Promise<string> => readFile(join(project, file), 'utf8');
  const apply = (set: 'recommended' | 'all') =>
    componentsProfile.apply({ targetDir: project, name: 'demo', prefix: 'app', set });

  it('writes every component of the collection with its spec', async () => {
    await apply('recommended');
    for (const component of componentsOf('recommended')) {
      const folder = `${SHARED}/as-${component.id}`;
      const files = await readdir(join(project, folder));
      expect(
        files.some((file) => file.endsWith('.spec.ts')),
        component.id,
      ).toBe(true);
    }
  });

  it('exports every component from the @shared/components barrel', async () => {
    await apply('recommended');
    const barrel = await read(`${SHARED}/index.ts`);
    expect(barrel).not.toContain('export {};');
    for (const name of [
      'AsButton',
      'AsIcon',
      'AsInput',
      'AsSelect',
      'AsModal',
      'AsToastService',
      'AsTabs',
    ]) {
      expect(barrel, name).toContain(name);
    }
    expect(barrel).toContain("from './as-button/as-button';");
  });

  it('leaves no unresolved placeholder in a generated file', async () => {
    await apply('recommended');
    for (const component of componentsOf('recommended')) {
      const folder = join(COMPONENTS_ROOT, `as-${component.id}`, 'src/app/shared/components');
      for (const file of await listBlueprintFiles(folder)) {
        const generated = file.replace(/\.tpl$/, '');
        expect(await read(`${SHARED}/${generated}`), generated).not.toMatch(/__[A-Z_]+__/);
      }
    }
  });

  it('adds only what is missing when the collection grows', async () => {
    await apply('recommended');
    await expect(apply('all')).resolves.toBeUndefined();
    const barrel = await read(`${SHARED}/index.ts`);
    expect(barrel.match(/AsButton\b/g)?.length).toBe(1);
  });

  it('never overwrites a file the developer changed', async () => {
    await apply('recommended');
    const { writeFile } = await import('node:fs/promises');
    await writeFile(join(project, `${SHARED}/as-button/as-button.css`), '/* mine */');
    await apply('all');
    expect(await read(`${SHARED}/as-button/as-button.css`)).toBe('/* mine */');
  });

  it('declares the files the verification stage must find', async () => {
    await apply('recommended');
    for (const file of componentsProfile.requiredFilesFor('recommended')) {
      await expect(read(file), file).resolves.toBeTypeOf('string');
    }
  });

  it('writes nothing when the barrel of shared/components is missing', async () => {
    await rm(join(project, `${SHARED}/index.ts`));
    await expect(apply('recommended')).rejects.toThrow(/Could not adapt/);
    await expect(read(`${SHARED}/as-button/as-button.ts`)).rejects.toThrow();
  });
});
