import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { writeGeneratedWorkspace } from '../../../tests/helpers/generated-workspace.js';
import { appShellProfile } from '../app-shell/app-shell.js';
import { screamingProfile } from '../architectures/screaming.js';
import { BLUEPRINTS_ROOT, listBlueprintFiles } from '../blueprint.js';
import { componentsProfile } from '../components/components.js';
import { installedComponentIds } from '../components/installed.js';
import { COMPONENTS, RECOMMENDED_COMPONENTS, componentsOfIds } from '../components/manifest.js';
import { designProfile } from '../design/design.js';
import { starterRoutingProfile } from '../routing/starter.js';
import { UI_SYSTEM_MARKER, uiSystemProfile } from './ui-system.js';

const UI_SYSTEM_BLUEPRINT = join(BLUEPRINTS_ROOT, 'ui-system');
const PAGE = 'src/app/features/preference-design';
const SYSTEM = `${PAGE}/ui-system`;

let project: string;

beforeEach(async () => {
  project = await mkdtemp(join(tmpdir(), 'sa-ui-system-'));
  await writeGeneratedWorkspace(project);
  const base = { targetDir: project, name: 'demo', prefix: 'app' };
  await screamingProfile.apply(base);
  await starterRoutingProfile.apply(base);
  await designProfile.apply(base);
  await componentsProfile.apply({ ...base, set: 'recommended' });
  await appShellProfile.apply(base);
});

afterEach(async () => {
  await rm(project, { recursive: true, force: true });
});

const read = (file: string): Promise<string> => readFile(join(project, file), 'utf8');
const apply = (prefix = 'app') =>
  uiSystemProfile.apply({ targetDir: project, name: 'demo', prefix });

describe('UI System profile (ADR-0010)', () => {
  it('creates the catalog, its page section and the spec', async () => {
    await apply();
    for (const file of [
      'ui-system.ts',
      'ui-system.html',
      'ui-system.catalog.ts',
      'ui-system.code.ts',
      'ui-system.spec.ts',
      'ui-system.code.spec.ts',
    ]) {
      await expect(read(`${SYSTEM}/${file}`), file).resolves.toBeTypeOf('string');
    }
    expect(await read(`${SYSTEM}/ui-system.ts`)).toContain("selector: 'app-ui-system'");
  });

  it('describes every essential component: selector, what it affects and its code', async () => {
    await apply();
    const catalog = await read(`${SYSTEM}/ui-system.catalog.ts`);
    for (const component of componentsOfIds(RECOMMENDED_COMPONENTS)) {
      expect(catalog, component.id).toContain(`id: '${component.id}'`);
    }
    expect(catalog).toContain('affects:');
    expect(catalog).toContain('code:');
  });

  it('gives every essential component its variants, each with its own code (ADR-0012)', async () => {
    await apply();
    const catalog = await read(`${SYSTEM}/ui-system.catalog.ts`);
    expect(catalog).toContain('variants:');
    for (const variant of [
      'xsmall',
      'type-tags',
      'icon-only',
      'preview',
      'phone-country',
      'draggable',
    ]) {
      expect(catalog, variant).toContain(variant);
    }
    // Every tabs example keeps its own active tab (ADR-0015).
    expect(catalog).not.toContain('sharedGroups');
    // The variants are for the catalog only: they never touch the design preferences service.
    expect(catalog).not.toContain('DesignPreferences');
    expect(await read(`${SYSTEM}/ui-system.ts`)).not.toContain('DesignPreferences');
  });

  it('puts the catalog in the UI tab, in place of its marker', async () => {
    expect(await read(`${PAGE}/tabs/ui-tab.html`)).toContain(UI_SYSTEM_MARKER);
    await apply();
    const html = await read(`${PAGE}/tabs/ui-tab.html`);
    expect(html).not.toContain(UI_SYSTEM_MARKER);
    expect(html).toContain('<app-ui-system />');
    const ts = await read(`${PAGE}/tabs/ui-tab.ts`);
    expect(ts).toContain("import { UiSystem } from '../ui-system/ui-system';");
    expect(ts).toMatch(/imports: \[[^\]]*UiSystem/);
  });

  it('uses the selector prefix of the project', async () => {
    await apply('shop');
    expect(await read(`${SYSTEM}/ui-system.ts`)).toContain("selector: 'shop-ui-system'");
    expect(await read(`${PAGE}/tabs/ui-tab.html`)).toContain('<shop-ui-system />');
  });

  it('only imports components that the project has', async () => {
    await apply();
    const installed = await installedComponentIds(project);
    const allowed = new Set(
      COMPONENTS.filter((component) => installed.includes(component.id)).flatMap((component) =>
        component.exports.flatMap(({ names }) => names.map((name) => name.replace(/^type /, ''))),
      ),
    );
    for (const file of await listBlueprintFiles(UI_SYSTEM_BLUEPRINT)) {
      const generated = file.replace(/\.tpl$/, '');
      if (!generated.endsWith('.ts')) continue;
      const text = await read(generated);
      for (const [, names] of text.matchAll(
        /import \{([^}]*)\} from '@shared\/(?:components|services)'/g,
      )) {
        for (const name of (names ?? '')
          .split(',')
          .map((entry) => entry.trim().replace(/^type /, ''))) {
          if (name)
            expect(allowed.has(name) || name === 'AlertService', `${generated}: ${name}`).toBe(
              true,
            );
        }
      }
    }
  });

  it('keeps the layer rules: core and shared only, never another feature', async () => {
    await apply();
    for (const file of await listBlueprintFiles(UI_SYSTEM_BLUEPRINT)) {
      expect(await read(file.replace(/\.tpl$/, '')), file).not.toMatch(/from '@features\//);
    }
  });

  it('leaves no unresolved placeholder in any generated file', async () => {
    await apply();
    for (const file of await listBlueprintFiles(UI_SYSTEM_BLUEPRINT)) {
      const generated = file.replace(/\.tpl$/, '');
      expect(await read(generated), generated).not.toMatch(/__[A-Z_]+__/);
    }
  });

  it('writes nothing when the UI tab does not have the marker', async () => {
    await writeFile(join(project, `${PAGE}/tabs/ui-tab.html`), '<p>my own tab</p>\n');
    await expect(apply()).rejects.toThrow(/ui-tab\.html/);
    await expect(read(`${SYSTEM}/ui-system.ts`)).rejects.toThrow();
    expect(await read(`${PAGE}/tabs/ui-tab.html`)).toBe('<p>my own tab</p>\n');
  });

  it('needs the design preferences page: the shell comes first', async () => {
    await rm(join(project, PAGE), { recursive: true, force: true });
    await expect(apply()).rejects.toThrow(/design preferences page/);
  });

  it('refuses to overwrite files that already exist', async () => {
    await apply();
    await expect(apply()).rejects.toThrow();
  });

  it('lists the files the verification stage must find', () => {
    expect(uiSystemProfile.requiredFiles).toEqual(
      expect.arrayContaining([
        `${SYSTEM}/ui-system.ts`,
        `${SYSTEM}/ui-system.html`,
        `${SYSTEM}/ui-system.catalog.ts`,
        `${SYSTEM}/ui-system.code.ts`,
      ]),
    );
  });
});

/** The catalog is built from the components the project has (ADR-0024). */
describe('UI System catalog by installed components', () => {
  const catalogIds = async (): Promise<string[]> =>
    [...(await read(`${SYSTEM}/ui-system.catalog.ts`)).matchAll(/^ {4}id: '([a-z-]+)',$/gm)].map(
      (match) => match[1] ?? '',
    );

  /** A project with the shell and these components (the shell brings its own). */
  async function build(set: 'recommended' | 'all' | readonly string[]): Promise<void> {
    await rm(project, { recursive: true, force: true });
    project = await mkdtemp(join(tmpdir(), 'sa-ui-system-'));
    await writeGeneratedWorkspace(project);
    const base = { targetDir: project, name: 'demo', prefix: 'app' };
    await screamingProfile.apply(base);
    await starterRoutingProfile.apply(base);
    await designProfile.apply(base);
    await componentsProfile.apply({ ...base, set });
    await appShellProfile.apply(base);
  }

  it('shows every component the project has, the two of the shell included', async () => {
    await apply();
    const ids = await catalogIds();
    expect([...ids].sort()).toEqual(await installedComponentIds(project));
    expect(ids).toEqual(expect.arrayContaining(['search', 'theme-color-picker']));
    expect(ids).toHaveLength(18);
  });

  it('shows only the components the project has when it chose a few', async () => {
    await build(['modal']);
    await apply();
    const installed = await installedComponentIds(project);
    expect([...(await catalogIds())].sort()).toEqual(installed);
    expect(installed).not.toContain('table');
    const code = await read(`${SYSTEM}/ui-system.ts`);
    expect(code).toContain('SaModal');
    expect(code).not.toContain('SaTable');
    expect(await read(`${SYSTEM}/ui-system.catalog.ts`)).not.toContain("id: 'datepicker'");
  });

  it('shows the 26 components of the collection "all", the ones with no preview as usage cards', async () => {
    await build('all');
    await apply();
    const ids = await catalogIds();
    expect(ids).toHaveLength(26);
    const catalog = await read(`${SYSTEM}/ui-system.catalog.ts`);
    expect(catalog.match(/noPreview: true/g)).toHaveLength(8);
    expect(await read(`${SYSTEM}/ui-system.html`)).toContain('entry.noPreview');
  });

  it('brings sa-button and sa-toggle, which it draws its own interface with, when they are missing', async () => {
    await build(['modal']);
    const shared = join(project, 'src/app/shared/components');
    await rm(join(shared, 'sa-toggle'), { recursive: true });
    await apply();
    await expect(read('src/app/shared/components/sa-toggle/sa-toggle.ts')).resolves.toBeTypeOf(
      'string',
    );
    expect(await read('src/app/shared/components/index.ts')).toContain('SaToggle');
  });

  describe('completing the catalog when more components arrive', () => {
    const catalog = (): Promise<string> => read(`${SYSTEM}/ui-system.catalog.ts`);

    it('says what the catalog lacks of what the project has', async () => {
      await build(['modal']);
      await apply();
      expect(await uiSystemProfile.missingEntries(project)).toEqual([]);
      await componentsProfile.apply({
        targetDir: project,
        name: 'demo',
        prefix: 'app',
        set: ['table', 'datepicker'],
      });
      // What they import comes with them, so more than the two asked for is missing.
      expect(await uiSystemProfile.missingEntries(project)).toEqual(
        expect.arrayContaining(['datepicker', 'table']),
      );
    });

    it('regenerates the catalog when it is as the CLI left it, and then equals a fresh one', async () => {
      await build(['modal']);
      await apply();
      await componentsProfile.apply({
        targetDir: project,
        name: 'demo',
        prefix: 'app',
        set: ['table'],
      });
      const report = await uiSystemProfile.update({
        targetDir: project,
        name: 'demo',
        prefix: 'app',
      });
      expect(report).toMatchObject({ status: 'updated', added: expect.arrayContaining(['table']) });
      const updated = await catalog();
      expect(updated).toContain("id: 'table'");

      const files = await listBlueprintFiles(UI_SYSTEM_BLUEPRINT);
      const afterUpdate = await Promise.all(
        files.map((file) => read(`${SYSTEM}/${file.replace(/^.*\//, '').replace(/\.tpl$/, '')}`)),
      );
      // A fresh application of the UI System to a project that has the same components gives the same files.
      await build(['modal', 'table']);
      await apply();
      const fresh = await Promise.all(
        files.map((file) => read(`${SYSTEM}/${file.replace(/^.*\//, '').replace(/\.tpl$/, '')}`)),
      );
      expect(afterUpdate).toEqual(fresh);
    });

    it('leaves the catalog alone when the developer edited it, and names the files and what is missing', async () => {
      await build(['modal']);
      await apply();
      const file = join(project, `${SYSTEM}/ui-system.catalog.ts`);
      const edited = `${await catalog()}\n// my own entry\n`;
      await writeFile(file, edited);
      await componentsProfile.apply({
        targetDir: project,
        name: 'demo',
        prefix: 'app',
        set: ['table'],
      });
      const report = await uiSystemProfile.update({
        targetDir: project,
        name: 'demo',
        prefix: 'app',
      });
      expect(report).toMatchObject({
        status: 'edited',
        missing: expect.arrayContaining(['table']),
        edited: [`${SYSTEM}/ui-system.catalog.ts`],
      });
      expect(await catalog()).toBe(edited);
    });

    it('does nothing when the catalog is complete', async () => {
      await apply();
      expect(
        await uiSystemProfile.update({ targetDir: project, name: 'demo', prefix: 'app' }),
      ).toEqual({
        status: 'current',
      });
    });
  });
});
