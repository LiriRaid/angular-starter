import { mkdir, mkdtemp, readFile, readdir, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { writeGeneratedWorkspace } from '../../../tests/helpers/generated-workspace.js';
import { screamingProfile } from '../architectures/screaming.js';
import { BLUEPRINTS_ROOT, listBlueprintFiles } from '../blueprint.js';
import { designProfile } from '../design/design.js';
import {
  COMPONENTS,
  EXTRA_COMPONENTS,
  RECOMMENDED_COMPONENTS,
  componentsOf,
  stylesOf,
} from './manifest.js';
import { componentsProfile } from './components.js';
import { COMPONENT_DESCRIPTIONS } from './descriptions.js';

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

  it('is closed: the recommended collection needs nothing outside itself', () => {
    const ids = componentsOf('recommended').map((component) => component.id);
    expect(new Set(ids).size).toBe(ids.length);
    expect([...ids].sort()).toEqual([...RECOMMENDED_COMPONENTS].sort());
  });

  it('keeps the "all" collection a superset of the recommended one, 26 components in total', () => {
    const recommended = componentsOf('recommended').map((component) => component.id);
    const all = componentsOf('all').map((component) => component.id);
    expect(all).toEqual(expect.arrayContaining(recommended));
    expect(EXTRA_COMPONENTS).toHaveLength(10);
    expect(all).toHaveLength(26);
    expect(new Set(COMPONENTS.map((component) => component.id)).size).toBe(26);
  });

  it('lists the global stylesheets of the generated components only, each once', () => {
    const recommended = stylesOf(componentsOf('recommended'));
    expect(recommended).toEqual(
      expect.arrayContaining([
        'button-styles',
        'input-styles',
        'select-styles',
        'popover-styles',
        'tooltip-styles',
        'toast-styles',
        'presence-indicator-styles',
      ]),
    );
    expect(recommended).not.toContain('table-styles');
    expect(stylesOf(componentsOf('all'))).toContain('table-styles');
    expect(new Set(recommended).size).toBe(recommended.length);
  });

  it.each(COMPONENTS.map((component) => [component.id, component] as const))(
    '%s has its blueprint, spec, barrel exports and stylesheets',
    async (_id, component) => {
      const folder = join(COMPONENTS_ROOT, `sa-${component.id}`, 'src/app/shared/components');
      const files = await listBlueprintFiles(folder);
      const own = files.filter((file) => file.startsWith(`sa-${component.id}/`));
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
          const declared = `export (abstract |declare )?(class|interface|type|const|function|enum) ${bare}\\b`;
          const reexported = `export (type )?\\{[^}]*\\b${bare}\\b`;
          expect(source, `${entry.from} exports ${bare}`).toMatch(
            new RegExp(`${declared}|${reexported}`),
          );
        }
      }
      for (const style of component.styles) {
        const sheet = join(COMPONENTS_ROOT, `sa-${component.id}`, 'src/styles/components');
        await expect(readFile(join(sheet, `${style}.css`), 'utf8'), style).resolves.toContain('{');
      }
    },
  );

  it.each(COMPONENTS.map((component) => [component.id, component] as const))(
    '%s declares every component it imports',
    async (_id, component) => {
      const folder = join(COMPONENTS_ROOT, `sa-${component.id}`, 'src/app/shared/components');
      const imported = new Set<string>();
      for (const file of await listBlueprintFiles(folder)) {
        if (!file.endsWith('.ts.tpl') || file.includes('.spec.')) continue;
        const text = await readFile(join(folder, file), 'utf8');
        for (const match of text.matchAll(/from '\.\.\/sa-([a-z-]+)\//g)) {
          if (match[1] !== component.id) imported.add(match[1] ?? '');
        }
      }
      expect([...imported].sort()).toEqual([...component.uses].sort());
    },
  );
});

describe('component blueprints follow the rules of the starter', () => {
  async function sources(): Promise<{ file: string; text: string }[]> {
    const found: { file: string; text: string }[] = [];
    for (const file of await listBlueprintFiles(COMPONENTS_ROOT)) {
      if (file.endsWith('.ts.tpl')) {
        found.push({ file, text: await readFile(join(COMPONENTS_ROOT, file), 'utf8') });
      }
    }
    return found;
  }

  it('never import from features nor from the business parts of core and shared', async () => {
    for (const { file, text } of await sources()) {
      for (const match of text.matchAll(/from '(@[^']+)'/g)) {
        const module = match[1] ?? '';
        if (module.startsWith('@angular/') || module.startsWith('@lucide/')) continue;
        expect(module, file).toMatch(
          /^@(core\/(common|theme)|shared\/(utils|data|services|components\/sa-toast))\b/,
        );
      }
    }
  });

  it('are standalone, OnPush components prefixed with sa-', async () => {
    for (const { file, text } of await sources()) {
      if (file.includes('.spec.') || !text.includes('@Component(')) continue;
      expect(text, file).toContain('ChangeDetectionStrategy.OnPush');
      expect(text, file).toMatch(/selector: 'sa-[a-zA-Z-]+'/);
      expect(text, file).not.toContain('NgModule');
    }
  });

  it('render Lucide icons only through sa-icon', async () => {
    for (const { file, text } of await sources()) {
      if (file.includes('sa-icon/')) continue;
      expect(text, file).not.toContain('@lucide/angular');
    }
  });

  it('keep the reference application code: nothing was rewritten into a lighter version', async () => {
    // The ported button is the full one, with its ripple and its severities.
    const button = await readFile(
      join(COMPONENTS_ROOT, 'sa-button/src/app/shared/components/sa-button/sa-button.ts.tpl'),
      'utf8',
    );
    expect(button.split('\n').length).toBeGreaterThan(150);
    expect(button).toContain('export class SaButton');
  });
});

describe('components profile', () => {
  let project: string;

  beforeEach(async () => {
    project = await mkdtemp(join(tmpdir(), 'sa-components-'));
    await writeGeneratedWorkspace(project, { 'src/styles.css': "@import 'tailwindcss';\n" });
    await screamingProfile.apply({ targetDir: project, name: 'demo', prefix: 'app' });
    await designProfile.apply({ targetDir: project, name: 'demo', prefix: 'app' });
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
      const folder = `${SHARED}/sa-${component.id}`;
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
      'SaButton',
      'SaRipple',
      'SaIcon',
      'SaInput',
      'SaSelect',
      'SaModal',
      'SaTabs',
    ]) {
      expect(barrel, name).toContain(name);
    }
    expect(barrel).toContain("from './sa-button/sa-button';");
  });

  it('brings the flags sprite that the phone country picker of the input draws', async () => {
    await apply('recommended');
    const sprite = await read('public/assets/flags-sprite.svg');
    expect(sprite).toContain('<symbol id="fi-us"');
    expect(await read(`${SHARED}/sa-input/sa-input.html`)).toContain('assets/flags-sprite.svg#fi-');
  });

  it('replaces a flags sprite that is already in the project instead of failing', async () => {
    await mkdir(join(project, 'public/assets'), { recursive: true });
    await writeFile(join(project, 'public/assets/flags-sprite.svg'), '<svg>old</svg>');
    await apply('recommended');
    expect(await read('public/assets/flags-sprite.svg')).toContain('<symbol id="fi-us"');
  });

  it('imports the stylesheet of each generated component, and only those', async () => {
    await apply('recommended');
    const styles = await read('src/styles.css');
    for (const name of stylesOf(componentsOf('recommended'))) {
      expect(styles, name).toContain(`@import './styles/components/${name}.css';`);
      await expect(read(`src/styles/components/${name}.css`), name).resolves.toContain('{');
    }
    expect(styles).not.toContain('table-styles');
    expect(styles.indexOf('button-styles')).toBeLessThan(styles.indexOf('animations.css'));
  });

  it('adds the Angular CDK that the modal and the reorder list import to package.json', async () => {
    await apply('recommended');
    const manifest = JSON.parse(await read('package.json'));
    expect(manifest.dependencies['@angular/cdk']).toMatch(/^\^22\./);
  });

  it('writes the toast queue service next to the components, as the reference does', async () => {
    await apply('recommended');
    expect(await read('src/app/shared/services/alert.service.ts')).toContain('class AlertService');
    expect(await read('src/app/shared/services/index.ts')).toContain('AlertService');
  });

  it('leaves no unresolved placeholder in a generated file', async () => {
    await apply('recommended');
    for (const component of componentsOf('recommended')) {
      const folder = join(COMPONENTS_ROOT, `sa-${component.id}`, 'src/app/shared/components');
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
    expect(barrel.match(/SaButton\b/g)?.length).toBe(1);
    const styles = await read('src/styles.css');
    expect(styles.match(/button-styles/g)?.length).toBe(1);
    expect(styles).toContain('table-styles');
  });

  it('never overwrites a file the developer changed', async () => {
    await apply('recommended');
    await writeFile(join(project, `${SHARED}/sa-button/sa-button.css`), '/* mine */');
    await apply('all');
    expect(await read(`${SHARED}/sa-button/sa-button.css`)).toBe('/* mine */');
  });

  it('lists in the README only the components and stylesheets that were generated', async () => {
    await apply('recommended');
    const readme = await read(`${SHARED}/README.md`);
    for (const component of componentsOf('recommended')) {
      expect(readme, component.id).toContain(`\`sa-${component.id}\``);
    }
    expect(readme).not.toContain('`sa-table`');
    const styles = await read('src/styles/README.md');
    expect(styles).toContain('`components/button-styles.css`');
    expect(styles).not.toContain('table-styles.css');
  });

  it('refreshes the README when the collection grows and keeps what the developer wrote', async () => {
    await apply('recommended');
    const path = join(project, `${SHARED}/README.md`);
    await writeFile(path, `${await read(`${SHARED}/README.md`)}\nMy own note.\n`);
    await apply('all');
    const readme = await read(`${SHARED}/README.md`);
    expect(readme).toContain('`sa-table`');
    expect(readme).toContain('`sa-button`');
    expect(readme).toContain('My own note.');
    expect(readme.match(/^- `sa-button`/gm)).toHaveLength(1);
  });

  it('leaves a README without the generated block alone', async () => {
    await apply('recommended');
    await writeFile(join(project, `${SHARED}/README.md`), '# My components\n');
    await apply('all');
    expect(await read(`${SHARED}/README.md`)).toBe('# My components\n');
  });

  it('describes every component of the manifest', () => {
    for (const component of COMPONENTS) {
      expect(COMPONENT_DESCRIPTIONS[component.id], component.id).toMatch(/^[A-Z].+\.$/);
    }
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
    await expect(read(`${SHARED}/sa-button/sa-button.ts`)).rejects.toThrow();
  });

  it('writes nothing when the design base is not in the stylesheet', async () => {
    await writeFile(join(project, 'src/styles.css'), "@import 'tailwindcss';\n");
    await expect(apply('recommended')).rejects.toThrow(/Could not adapt src\/styles\.css/);
    await expect(read(`${SHARED}/sa-button/sa-button.ts`)).rejects.toThrow();
  });
});
