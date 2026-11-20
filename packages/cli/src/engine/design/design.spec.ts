import { mkdtemp, readFile, readdir, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { writeGeneratedWorkspace } from '../../../tests/helpers/generated-workspace.js';
import { screamingProfile } from '../architectures/screaming.js';
import { BLUEPRINTS_ROOT, listBlueprintFiles } from '../blueprint.js';
import { DESIGN_STYLE_IMPORTS } from '../edits/styles.js';
import { designProfile } from './design.js';

const ANGULAR_JSON = `{
  "projects": {
    "demo": {
      "architect": {
        "build": { "options": { "styles": ["src/styles.css"] } },
        "test": { "builder": "@angular/build:unit-test" }
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
const apply = (name = 'demo') => designProfile.apply({ targetDir: project, name, prefix: 'app' });

describe('design base', () => {
  it('lays the stylesheets out like the reference application, every file named -styles.css', async () => {
    await apply();
    for (const file of [
      'src/styles/theme/theme-styles.css',
      'src/styles/base-elements-styles.css',
      'src/styles/mixins-styles.css',
      'src/styles/scrollbar-styles.css',
      'src/styles/typography/text-and-color-styles.css',
      'src/styles/typography/typography-styles.css',
    ]) {
      await expect(read(file), file).resolves.toBeTypeOf('string');
    }
    const entries = await readdir(join(project, 'src/styles'), {
      recursive: true,
      withFileTypes: true,
    });
    for (const entry of entries.filter((item) => item.isFile())) {
      expect(entry.name, entry.name).toMatch(/-styles\.css$/);
    }
  });

  it('loads the Inter font of the reference application from index.html', async () => {
    await designProfile.apply({ targetDir: project, name: 'demo', prefix: 'app' });
    const html = await readFile(join(project, 'src/index.html'), 'utf8');
    expect(html).toContain('family=Inter:wght@100..900');
    expect(html.match(/family=Inter/g)).toHaveLength(1);
    expect(await readFile(join(project, 'src/styles/base-elements-styles.css'), 'utf8')).toContain(
      "font-family: 'Inter'",
    );
  });

  it('keeps the animations in shared/animations', async () => {
    await apply();
    expect(await read('src/app/shared/animations/animations.css')).toContain('@keyframes');
  });

  it('imports every design file from src/styles.css, not from angular.json', async () => {
    await apply();
    const styles = await read('src/styles.css');
    expect(styles.split('\n')[1]).toBe("@import 'tailwindcss';");
    expect(styles).toContain('@custom-variant dark (&:where(.dark, .dark *));');
    expect(styles).toContain('@layer base, components, legacy-overrides, utilities;');
    for (const file of DESIGN_STYLE_IMPORTS) expect(styles).toContain(`@import '${file}';`);
    expect(
      JSON.parse(await read('angular.json')).projects.demo.architect.build.options.styles,
    ).toEqual(['src/styles.css']);
  });

  it('gives the specs the icons the application provides at startup', async () => {
    await apply();
    const angularJson = JSON.parse(await read('angular.json'));
    expect(angularJson.projects.demo.architect.test.options.setupFiles).toEqual([
      'src/test-setup.ts',
    ]);
    const setup = await read('src/test-setup.ts');
    expect(setup).toContain('{ provide: LUCIDE_ICONS, useExisting: AS_LUCIDE_ICONS }');
  });

  it('writes the tokens with the as- prefix and a dark theme, with no business sections', async () => {
    await apply();
    const theme = await read('src/styles/theme/theme-styles.css');
    expect(theme).toContain('--as-primary-color');
    expect(theme).toContain('--as-surface-0');
    expect(theme).toContain('.dark {');
    expect(theme).toContain('--app-panel-bg');
    expect(theme).not.toMatch(/--omni-|--login-|--app-eco-/);
  });

  it('adds the theme and the Lucide registration to the application config', async () => {
    await apply();
    const config = await read('src/app/app.config.ts');
    expect(config).toContain('provideThemeInitializer()');
    expect(config).toContain('{ provide: LUCIDE_ICONS, useExisting: AS_LUCIDE_ICONS }');
    expect(config).toContain("from '@core/theme/theme.initializer'");
    expect(config).toContain("from '@core/common/icons/lucide-icons.provider'");
    expect(config).toMatch(/import \{ LUCIDE_ICONS \} from '@lucide\/angular'/);
  });

  it('writes the theme service with its spec in core/theme', async () => {
    await apply();
    for (const file of [
      'src/app/core/theme/theme.service.ts',
      'src/app/core/theme/theme.service.spec.ts',
      'src/app/core/theme/theme-palettes.ts',
      'src/app/core/theme/theme-preferences.storage.ts',
      'src/app/core/theme/theme.initializer.ts',
    ]) {
      await expect(read(file), file).resolves.toBeTypeOf('string');
    }
    expect(await read('src/app/core/theme/theme-preferences.storage.ts')).toContain(
      "'demo:theme-mode'",
    );
  });

  it('keeps the theme service usable while the server renders (no dataset on the root element)', async () => {
    await apply();
    const service = await read('src/app/core/theme/theme.service.ts');
    // The server DOM has no `dataset`; attributes work everywhere.
    expect(service).not.toContain('.dataset');
    expect(service).toContain("setAttribute('data-primary-color'");
    expect(service).toContain("setAttribute('data-surface-color'");
  });

  it('writes the icon registration in core/common/icons', async () => {
    await apply();
    for (const file of ['lucide-icons.ts', 'lucide-icons.provider.ts', 'as-icons.ts']) {
      await expect(read(`src/app/core/common/icons/${file}`), file).resolves.toBeTypeOf('string');
    }
    expect(await read('src/app/core/common/icons/lucide-icons.ts')).toContain('Home: LucideHouse');
  });

  it('writes the generic utilities with their specs in shared/utils', async () => {
    await apply();
    for (const name of [
      'derive-initials',
      'avatar-accent',
      'escape-html',
      'format-file-size',
      'format-phone-number',
      'relative-time',
      'date-time-format',
      'safe-timeout',
      'slugify',
      'download-file',
      'native-overlay-dismiss',
      'panel-placement',
      'responsive-action-size',
    ]) {
      await expect(read(`src/app/shared/utils/${name}.ts`), name).resolves.toBeTypeOf('string');
      await expect(read(`src/app/shared/utils/${name}.spec.ts`), name).resolves.toContain(
        'describe(',
      );
    }
    for (const name of ['accent-palette', 'phone-countries', 'phone-number-formats']) {
      await expect(read(`src/app/shared/data/${name}.ts`), name).resolves.toBeTypeOf('string');
    }
  });

  it('leaves no unresolved placeholder in any generated file', async () => {
    await apply();
    for (const file of await listBlueprintFiles(join(BLUEPRINTS_ROOT, 'design'))) {
      const generated = file.replace(/\.tpl$/, '');
      expect(await read(generated), generated).not.toMatch(/__[A-Z_]+__/);
    }
  });

  it('declares the files the verification stage must find', async () => {
    await apply();
    expect(designProfile.requiredFiles.length).toBeGreaterThan(5);
    for (const file of designProfile.requiredFiles) {
      await expect(read(file), file).resolves.toBeTypeOf('string');
    }
  });

  it('writes nothing when the stylesheet does not import Tailwind CSS', async () => {
    await writeGeneratedWorkspace(project, { 'src/styles.css': 'body { margin: 0; }\n' });
    await expect(apply()).rejects.toThrow(/Could not adapt src\/styles\.css.*Tailwind CSS/);
    await expect(read('src/styles/theme/theme-styles.css')).rejects.toThrow();
    expect(await read('src/styles.css')).toBe('body { margin: 0; }\n');
  });
});

describe('design blueprint rules (ADR-0002 and ADR-0007)', () => {
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

  it('keeps shared free of features and of the business of core', async () => {
    const bad = (await importsOf('shared')).filter(({ module }) =>
      /^@features\/|^@core\/(auth|realtime|interceptors|notifications|config)/.test(module),
    );
    expect(bad).toEqual([]);
  });

  it('does not bring authentication, guards, interceptors or business', async () => {
    const files = await listBlueprintFiles(join(BLUEPRINTS_ROOT, 'design'));
    expect(
      files.filter((file) => /auth|guard|interceptor|session|contact|ticket|whatsapp/i.test(file)),
    ).toEqual([]);
  });
});

describe('what every generated file may say', () => {
  async function allText(): Promise<{ file: string; text: string }[]> {
    const found: { file: string; text: string }[] = [];
    for (const group of ['design', 'components']) {
      const base = join(BLUEPRINTS_ROOT, group);
      for (const file of await listBlueprintFiles(base)) {
        found.push({ file, text: await readFile(join(base, file), 'utf8') });
      }
    }
    return found;
  }

  it('carries no trace of the reference application or of any employer', async () => {
    for (const { file, text } of await allText()) {
      expect(text, file).not.toMatch(/omni|yalo/i);
    }
  });
});
