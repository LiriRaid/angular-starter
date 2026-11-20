import { mkdtemp, readFile, readdir, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { writeGeneratedWorkspace } from '../../../tests/helpers/generated-workspace.js';
import { screamingProfile } from '../architectures/screaming.js';
import { BLUEPRINTS_ROOT, listBlueprintFiles } from '../blueprint.js';
import { designProfile } from './design.js';

const ANGULAR_JSON = `{
  "projects": {
    "demo": {
      "architect": {
        "build": { "options": { "styles": ["src/styles.css"] } }
      }
    }
  }
}
`;
const TAILWIND_STYLES = `/* You can add global styles to this file, and also import other style files */

@import 'tailwindcss';
`;

let project: string;

beforeEach(async () => {
  project = await mkdtemp(join(tmpdir(), 'as-design-'));
  await writeGeneratedWorkspace(project, {
    'angular.json': ANGULAR_JSON,
    'src/styles.css': TAILWIND_STYLES,
  });
  await screamingProfile.apply({ targetDir: project, name: 'demo', prefix: 'app' });
});

afterEach(async () => {
  await rm(project, { recursive: true, force: true });
});

const read = (file: string): Promise<string> => readFile(join(project, file), 'utf8');
const apply = (tailwind: boolean, name = 'demo') =>
  designProfile.apply({ targetDir: project, name, prefix: 'app', tailwind });

describe('design base', () => {
  it('writes plain CSS design files that need no Tailwind', async () => {
    await apply(false);
    for (const file of [
      'src/styles/design.css',
      'src/styles/tokens.css',
      'src/styles/base.css',
      'src/styles/typography.css',
      'src/styles/scrollbar.css',
      'src/styles/animations.css',
    ]) {
      await expect(read(file), file).resolves.toBeTypeOf('string');
    }
    const entry = await read('src/styles/design.css');
    for (const part of ['tokens', 'base', 'typography', 'forms', 'scrollbar', 'animations']) {
      expect(entry).toContain(`./${part}.css`);
    }
    expect(await read('src/styles/tokens.css')).toContain('--as-primary-500');
    expect(await read('src/styles/tokens.css')).toContain('.dark');
  });

  it('registers the design entry in the styles of angular.json', async () => {
    await apply(false);
    const styles = JSON.parse(await read('angular.json')).projects.demo.architect.build.options
      .styles;
    expect(styles).toEqual(['src/styles.css', 'src/styles/design.css']);
  });

  it('adds the theme and the icons to the application config', async () => {
    await apply(false);
    const config = await read('src/app/app.config.ts');
    expect(config).toContain('provideThemeInitializer()');
    expect(config).toContain('provideAsIcons()');
    expect(config).toContain("from '@core/theme/theme.initializer'");
    expect(config).toContain("from '@core/icons/icons.provider'");
  });

  it('maps the tokens to Tailwind only when Tailwind is on', async () => {
    await apply(true);
    expect(await read('src/styles/tailwind.css')).toContain('@custom-variant dark');
    expect(await read('src/styles/tailwind.css')).toContain('@theme inline');
    expect(await read('src/styles.css')).toBe(
      `${TAILWIND_STYLES.trimEnd()}\n@import './styles/tailwind.css';\n`,
    );
  });

  it('does not write the Tailwind files without Tailwind', async () => {
    await apply(false);
    await expect(read('src/styles/tailwind.css')).rejects.toThrow();
    expect(await read('src/styles.css')).toBe(TAILWIND_STYLES);
  });

  it('writes the theme service with its spec in core', async () => {
    await apply(false);
    for (const file of [
      'src/app/core/theme/theme.service.ts',
      'src/app/core/theme/theme.service.spec.ts',
      'src/app/core/theme/theme-palettes.ts',
      'src/app/core/theme/theme-storage.ts',
      'src/app/core/theme/theme.initializer.ts',
      'src/app/core/icons/icons.ts',
      'src/app/core/icons/icons.provider.ts',
    ]) {
      await expect(read(file), file).resolves.toBeTypeOf('string');
    }
    expect(await read('src/app/core/theme/theme-storage.ts')).toContain("'demo:theme-mode'");
  });

  it('writes the utilities and pipes with their specs in shared', async () => {
    await apply(false);
    for (const name of [
      'derive-initials',
      'escape-html',
      'format-file-size',
      'relative-time',
      'date-time',
      'safe-timeout',
      'slugify',
      'focus-trap',
      'generate-id',
      'download-file',
    ]) {
      await expect(read(`src/app/shared/utils/${name}.ts`), name).resolves.toBeTypeOf('string');
      await expect(read(`src/app/shared/utils/${name}.spec.ts`), name).resolves.toContain(
        'describe(',
      );
    }
    for (const name of ['relative-time', 'file-size', 'initials']) {
      await expect(read(`src/app/shared/pipes/${name}.pipe.ts`), name).resolves.toBeTypeOf(
        'string',
      );
      await expect(read(`src/app/shared/pipes/${name}.pipe.spec.ts`), name).resolves.toContain(
        'describe(',
      );
    }
  });

  it('leaves no unresolved placeholder in any generated file', async () => {
    await apply(true);
    for (const root of ['design', 'design-tailwind']) {
      for (const file of await listBlueprintFiles(join(BLUEPRINTS_ROOT, root))) {
        const generated = file.replace(/\.tpl$/, '');
        expect(await read(generated), generated).not.toMatch(/__[A-Z_]+__/);
      }
    }
  });

  it('declares the files the verification stage must find', async () => {
    await apply(true);
    expect(designProfile.requiredFiles.length).toBeGreaterThan(5);
    for (const file of designProfile.requiredFiles) {
      await expect(read(file), file).resolves.toBeTypeOf('string');
    }
  });

  it('writes nothing when angular.json has no styles to extend', async () => {
    await writeGeneratedWorkspace(project, { 'angular.json': '{ "projects": {} }\n' });
    await expect(apply(true)).rejects.toThrow(/Could not adapt angular\.json/);
    await expect(read('src/styles/design.css')).rejects.toThrow();
    expect(await read('src/styles.css')).toBe(TAILWIND_STYLES);
  });
});

describe('design blueprint rules (ADR-0002 and ADR-0005)', () => {
  const root = join(BLUEPRINTS_ROOT, 'design', 'src', 'app');

  async function importsOf(layer: string): Promise<{ file: string; module: string }[]> {
    const entries = await readdir(join(root, layer), { recursive: true, withFileTypes: true });
    const found: { file: string; module: string }[] = [];
    for (const entry of entries.filter((item) => item.isFile() && item.name.endsWith('.ts.tpl'))) {
      const path = join(entry.parentPath, entry.name);
      const text = await readFile(path, 'utf8');
      for (const match of text.matchAll(/from '([^']+)'/g)) {
        found.push({ file: path, module: match[1] ?? '' });
      }
    }
    return found;
  }

  it('keeps core free of features and shared', async () => {
    const bad = (await importsOf('core')).filter(({ module }) =>
      /^@(features|shared)\//.test(module),
    );
    expect(bad).toEqual([]);
  });

  it('keeps shared free of features', async () => {
    const bad = (await importsOf('shared')).filter(({ module }) => /^@features\//.test(module));
    expect(bad).toEqual([]);
  });

  it('does not bring authentication, guards or interceptors', async () => {
    const files = await listBlueprintFiles(join(BLUEPRINTS_ROOT, 'design'));
    expect(files.filter((file) => /auth|guard|interceptor|session/i.test(file))).toEqual([]);
  });
});
