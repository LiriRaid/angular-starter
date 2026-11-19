import { existsSync } from 'node:fs';
import { mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { copyBlueprint, listBlueprintFiles, renderTemplate } from './blueprint.js';

const VARIABLES = { PROJECT_NAME: 'demo', PREFIX: 'acme' };

describe('renderTemplate', () => {
  it('replaces every placeholder', () => {
    expect(
      renderTemplate("selector: '__PREFIX__-home' // __PROJECT_NAME__ __PREFIX__", VARIABLES),
    ).toBe("selector: 'acme-home' // demo acme");
  });

  it('leaves Angular interpolation alone', () => {
    expect(renderTemplate('<h1>{{ title() }}</h1>', VARIABLES)).toBe('<h1>{{ title() }}</h1>');
  });

  it('fails on a placeholder that has no value, so a typo cannot reach a project', () => {
    expect(() => renderTemplate('__PREFX__', VARIABLES)).toThrow(/PREFX/);
  });
});

describe('copyBlueprint', () => {
  let root: string;
  let source: string;
  let target: string;

  async function put(base: string, file: string, content: string): Promise<void> {
    await mkdir(dirname(join(base, file)), { recursive: true });
    await writeFile(join(base, file), content);
  }

  beforeEach(async () => {
    root = await mkdtemp(join(tmpdir(), 'as-blueprint-'));
    source = join(root, 'blueprint');
    target = join(root, 'project');
    await put(source, 'src/app/features/home/home.ts.tpl', "selector: '__PREFIX__-home';\n");
    await put(source, 'src/app/core/README.md', '# Core\n');
    await mkdir(target, { recursive: true });
  });

  afterEach(async () => {
    await rm(root, { recursive: true, force: true });
  });

  it('lists the template files with forward slashes', async () => {
    expect(await listBlueprintFiles(source)).toEqual([
      'src/app/core/README.md',
      'src/app/features/home/home.ts.tpl',
    ]);
  });

  it('renders the files, drops the .tpl suffix and reports what it wrote', async () => {
    const written = await copyBlueprint({ source, target, variables: VARIABLES });
    expect(written).toEqual(['src/app/core/README.md', 'src/app/features/home/home.ts']);
    expect(await readFile(join(target, 'src/app/features/home/home.ts'), 'utf8')).toBe(
      "selector: 'acme-home';\n",
    );
    expect(existsSync(join(target, 'src/app/features/home/home.ts.tpl'))).toBe(false);
  });

  it('never overwrites a file the project already has', async () => {
    await put(target, 'src/app/core/README.md', 'mine\n');
    await expect(copyBlueprint({ source, target, variables: VARIABLES })).rejects.toThrow(
      /src\/app\/core\/README\.md/,
    );
    expect(await readFile(join(target, 'src/app/core/README.md'), 'utf8')).toBe('mine\n');
  });

  it('writes nothing when any file would collide', async () => {
    await put(target, 'src/app/core/README.md', 'mine\n');
    await copyBlueprint({ source, target, variables: VARIABLES }).catch(() => undefined);
    expect(existsSync(join(target, 'src/app/features/home/home.ts'))).toBe(false);
  });

  it('overwrites only the files it is explicitly allowed to replace', async () => {
    await put(target, 'src/app/core/README.md', 'placeholder\n');
    await copyBlueprint({
      source,
      target,
      variables: VARIABLES,
      overwrite: ['src/app/core/README.md'],
    });
    expect(await readFile(join(target, 'src/app/core/README.md'), 'utf8')).toBe('# Core\n');
  });
});
