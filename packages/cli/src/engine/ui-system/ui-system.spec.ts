import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { writeGeneratedWorkspace } from '../../../tests/helpers/generated-workspace.js';
import { appShellProfile } from '../app-shell/app-shell.js';
import { screamingProfile } from '../architectures/screaming.js';
import { BLUEPRINTS_ROOT, listBlueprintFiles } from '../blueprint.js';
import { componentsProfile } from '../components/components.js';
import { RECOMMENDED_COMPONENTS, componentsOfIds } from '../components/manifest.js';
import { designProfile } from '../design/design.js';
import { starterRoutingProfile } from '../routing/starter.js';
import { UI_SYSTEM_MARKER, uiSystemProfile } from './ui-system.js';

const UI_SYSTEM_BLUEPRINT = join(BLUEPRINTS_ROOT, 'ui-system');
const PAGE = 'src/app/features/preference-design';
const SYSTEM = `${PAGE}/ui-system`;

let project: string;

beforeEach(async () => {
  project = await mkdtemp(join(tmpdir(), 'as-ui-system-'));
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
    for (const variant of ['xsmall', 'mode-over', 'type-tags', 'icon-only', 'preview']) {
      expect(catalog, variant).toContain(variant);
    }
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

  it('only previews components that the essential collection brings', async () => {
    const allowed = new Set(
      componentsOfIds(RECOMMENDED_COMPONENTS).flatMap((component) =>
        component.exports.flatMap(({ names }) => names.map((name) => name.replace(/^type /, ''))),
      ),
    );
    for (const file of await listBlueprintFiles(UI_SYSTEM_BLUEPRINT)) {
      if (!file.endsWith('.ts.tpl')) continue;
      const text = await readFile(join(UI_SYSTEM_BLUEPRINT, file), 'utf8');
      for (const [, names] of text.matchAll(
        /import \{([^}]*)\} from '@shared\/(?:components|services)'/g,
      )) {
        for (const name of (names ?? '')
          .split(',')
          .map((entry) => entry.trim().replace(/^type /, ''))) {
          if (name)
            expect(allowed.has(name) || name === 'AlertService', `${file}: ${name}`).toBe(true);
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
