import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { TOOLING_PACKAGES } from '../../compat.js';
import { pathExists } from '../fs.js';
import { toolingProfile } from './tooling.js';

const MANIFEST = `{
  "name": "demo",
  "scripts": {
    "build": "ng build",
    "test": "ng test"
  },
  "dependencies": {
    "@angular/core": "^22.3.0"
  },
  "devDependencies": {
    "prettier": "^3.8.1",
    "typescript": "~6.0.2"
  }
}
`;

let dir: string;

beforeEach(async () => {
  dir = await mkdtemp(join(tmpdir(), 'sa-tooling-'));
  await writeFile(join(dir, 'package.json'), MANIFEST);
});

afterEach(async () => {
  await rm(dir, { recursive: true, force: true });
});

const manifest = async () => JSON.parse(await readFile(join(dir, 'package.json'), 'utf8'));
const apply = (overrides: Partial<Parameters<typeof toolingProfile.apply>[0]> = {}) =>
  toolingProfile.apply({ targetDir: dir, prefix: 'app', style: 'css', ...overrides });

describe('tooling profile', () => {
  it('writes the ESLint configuration with the selector prefix of the project', async () => {
    const report = await apply({ prefix: 'shop' });
    const config = await readFile(join(dir, 'eslint.config.mjs'), 'utf8');

    expect(report.eslint).toBe('added');
    expect(config).toContain("prefix: ['shop', 'sa']");
    expect(config).not.toMatch(/__[A-Z_]+__/);
    expect(config).toContain('angular.configs.templateRecommended');
  });

  it('does not apply the output naming rules to the sa- components, whose API names them onClick, input or change', async () => {
    await apply();
    const config = await readFile(join(dir, 'eslint.config.mjs'), 'utf8');

    expect(config).toContain("files: ['src/app/shared/components/sa-*/**/*.ts']");
    expect(config).toContain("'@angular-eslint/no-output-on-prefix': 'off'");
    expect(config).toContain("'@angular-eslint/no-output-native': 'off'");
  });

  it('adds the lint packages as dev dependencies with the versions the CLI was tested with', async () => {
    await apply();
    const { devDependencies, dependencies } = await manifest();

    for (const name of ['eslint', '@eslint/js', 'typescript-eslint', 'angular-eslint']) {
      expect(devDependencies[name]).toBe(TOOLING_PACKAGES[name]);
    }
    expect(dependencies).toEqual({ '@angular/core': '^22.3.0' });
    // Prettier comes with ng new: the version the project has stays.
    expect(devDependencies.prettier).toBe('^3.8.1');
  });

  it('adds Prettier when the project has none', async () => {
    await writeFile(join(dir, 'package.json'), '{\n  "name": "demo"\n}\n');
    await apply();

    expect((await manifest()).devDependencies.prettier).toBe(TOOLING_PACKAGES['prettier']);
  });

  it('adds the lint and format scripts after the ones the project has', async () => {
    await apply();
    const { scripts } = await manifest();

    expect(Object.keys(scripts)).toEqual([
      'build',
      'test',
      'test:watch',
      'lint',
      'lint:fix',
      'format',
      'format:check',
    ]);
    expect(scripts['lint']).toBe('eslint "src/**/*.{ts,html}"');
    expect(scripts['lint:fix']).toBe('eslint "src/**/*.{ts,html}" --fix');
    expect(scripts['format']).toBe('prettier --write "src/**/*.{ts,html,css}"');
    expect(scripts['format:check']).toBe('prettier --check "src/**/*.{ts,html,css}"');
    expect(scripts['test']).toBe('ng test');
    expect(scripts['test:watch']).toBe('ng test --watch');
  });

  it.each([
    ['css', 'css'],
    ['scss', 'scss'],
    ['less', 'less'],
  ] as const)('formats the %s stylesheets too', async (style, extension) => {
    await apply({ style });

    expect((await manifest()).scripts['format']).toBe(
      `prettier --write "src/**/*.{ts,html,${extension}}"`,
    );
  });

  it('formats only code and templates in a project with indented Sass, which Prettier cannot read', async () => {
    await apply({ style: 'sass' });

    expect((await manifest()).scripts['format']).toBe('prettier --write "src/**/*.{ts,html}"');
  });

  it('never replaces a script the project already has', async () => {
    await writeFile(
      join(dir, 'package.json'),
      '{\n  "name": "demo",\n  "scripts": {\n    "lint": "ng lint",\n    "format": "biome format"\n  }\n}\n',
    );
    await apply();
    const { scripts } = await manifest();

    expect(scripts['lint']).toBe('ng lint');
    expect(scripts['format']).toBe('biome format');
    expect(scripts['lint:fix']).toBeDefined();
  });

  it.each([
    'eslint.config.js',
    'eslint.config.mjs',
    'eslint.config.cjs',
    'eslint.config.ts',
    '.eslintrc.json',
    '.eslintrc.cjs',
  ])(
    'keeps the ESLint setup the developer has (%s) and adds only what is not about ESLint',
    async (file) => {
      await writeFile(join(dir, file), "// the developer's own\n");
      const report = await apply();
      const { devDependencies, scripts } = await manifest();

      expect(report.eslint).toBe('kept');
      expect(report.found).toBe(file);
      expect(await readFile(join(dir, file), 'utf8')).toBe("// the developer's own\n");
      if (file !== 'eslint.config.mjs')
        expect(await pathExists(join(dir, 'eslint.config.mjs'))).toBe(false);
      expect(devDependencies['eslint']).toBeUndefined();
      expect(devDependencies['angular-eslint']).toBeUndefined();
      expect(scripts['lint']).toBeUndefined();
      expect(scripts['format']).toBeDefined();
      expect(scripts['format:check']).toBeDefined();
      expect(scripts['test:watch']).toBeDefined();
    },
  );

  it('keeps an ESLint setup that lives in package.json', async () => {
    await writeFile(
      join(dir, 'package.json'),
      '{\n  "name": "demo",\n  "eslintConfig": { "root": true }\n}\n',
    );
    const report = await apply();

    expect(report.eslint).toBe('kept');
    expect(report.found).toBe('package.json (eslintConfig)');
    expect(await pathExists(join(dir, 'eslint.config.mjs'))).toBe(false);
  });

  it('is idempotent: a second run finds its own configuration and changes nothing', async () => {
    await apply();
    const first = await readFile(join(dir, 'package.json'), 'utf8');
    const config = await readFile(join(dir, 'eslint.config.mjs'), 'utf8');
    const report = await apply();

    expect(report.eslint).toBe('kept');
    expect(await readFile(join(dir, 'package.json'), 'utf8')).toBe(first);
    expect(await readFile(join(dir, 'eslint.config.mjs'), 'utf8')).toBe(config);
  });

  it('writes nothing when the package.json is not valid', async () => {
    await writeFile(join(dir, 'package.json'), '{ "name": ');

    await expect(apply()).rejects.toThrow(/package\.json/);
    expect(await pathExists(join(dir, 'eslint.config.mjs'))).toBe(false);
  });

  it('names the files a new project must have', () => {
    expect(toolingProfile.requiredFiles).toEqual(['eslint.config.mjs']);
  });
});

describe('tooling profile: what a project lacks', () => {
  const project = () => ({ targetDir: dir, prefix: 'app', style: 'css' as const });

  it('says a project lacks it before the tooling is applied, and writes nothing to find out', async () => {
    const before = await readFile(join(dir, 'package.json'), 'utf8');

    expect(await toolingProfile.isComplete(project())).toBe(false);
    expect(await readFile(join(dir, 'package.json'), 'utf8')).toBe(before);
    expect(await pathExists(join(dir, 'eslint.config.mjs'))).toBe(false);
  });

  it('says a project that has everything but the watch script of the tests lacks it', async () => {
    await toolingProfile.apply(project());
    const manifest = JSON.parse(await readFile(join(dir, 'package.json'), 'utf8'));
    delete manifest.scripts['test:watch'];
    await writeFile(join(dir, 'package.json'), JSON.stringify(manifest, null, 2));

    expect(await toolingProfile.isComplete(project())).toBe(false);
  });

  it('says a project has it once the tooling is applied', async () => {
    await toolingProfile.apply(project());

    expect(await toolingProfile.isComplete(project())).toBe(true);
  });

  it('says a project lacks the format scripts even when it has an ESLint setup of its own', async () => {
    await writeFile(join(dir, 'eslint.config.js'), '// own\n');
    expect(await toolingProfile.isComplete(project())).toBe(false);

    await toolingProfile.apply(project());
    expect(await toolingProfile.isComplete(project())).toBe(true);
  });
});
