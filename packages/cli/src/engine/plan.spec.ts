import { mkdir, mkdtemp, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { blueprintTargets } from './blueprint.js';
import { FilePlan } from './plan.js';

let root: string;

async function put(file: string, text = 'x'): Promise<void> {
  await mkdir(dirname(join(root, file)), { recursive: true });
  await writeFile(join(root, file), text);
}

beforeEach(async () => {
  root = await mkdtemp(join(tmpdir(), 'sa-plan-'));
});

afterEach(async () => {
  await rm(root, { recursive: true, force: true });
});

describe('blueprintTargets', () => {
  it('lists the project files of a blueprint without the .tpl suffix', async () => {
    const source = join(root, 'blueprint');
    await mkdir(join(source, 'src/app'), { recursive: true });
    await writeFile(join(source, 'src/app/app.ts.tpl'), '');
    await writeFile(join(source, 'src/app/app.html'), '');
    expect(await blueprintTargets(source)).toEqual(['src/app/app.html', 'src/app/app.ts']);
  });
});

describe('FilePlan', () => {
  it('marks a file that is not in the project as created and one that is as updated', async () => {
    await put('package.json');
    const plan = new FilePlan(root);
    await plan.write('package.json');
    await plan.write('src/main.ts');
    expect(plan.files()).toEqual([
      { path: 'package.json', action: 'update' },
      { path: 'src/main.ts', action: 'create' },
    ]);
  });

  it('sees what an earlier step planned as already there, so a project that does not exist can be planned', async () => {
    const plan = new FilePlan(join(root, 'not-yet'));
    expect(await plan.exists('src/app/app.ts')).toBe(false);
    await plan.write('src/app/app.ts');
    expect(await plan.exists('src/app/app.ts')).toBe(true);
    await plan.edit('src/app/app.ts');
    await plan.write('src/app/app.ts');
    expect(plan.files()).toEqual([{ path: 'src/app/app.ts', action: 'create' }]);
  });

  it('edits only what is there, and a file the plan creates stays created', async () => {
    await put('angular.json');
    const plan = new FilePlan(root);
    await plan.edit('angular.json');
    await plan.write('src/styles.css');
    await plan.edit('src/styles.css');
    expect(plan.files()).toEqual([
      { path: 'angular.json', action: 'update' },
      { path: 'src/styles.css', action: 'create' },
    ]);
  });

  it('removes a file of the project, and forgets one it had planned to create', async () => {
    await put('src/app/app.html');
    const plan = new FilePlan(root);
    await plan.remove('src/app/app.html');
    await plan.write('src/app/app.css');
    await plan.remove('src/app/app.css');
    await plan.remove('src/app/missing.css');
    expect(plan.files()).toEqual([{ path: 'src/app/app.html', action: 'remove' }]);
  });

  it('writes again a file it had removed, which leaves it updated', async () => {
    await put('a.txt');
    const plan = new FilePlan(root);
    await plan.remove('a.txt');
    await plan.write('a.txt');
    expect(plan.files()).toEqual([{ path: 'a.txt', action: 'update' }]);
  });

  it('remembers which files a step changed, even when the plan creates them', async () => {
    const plan = new FilePlan(join(root, 'project'));
    await plan.write('src/app/home.html');
    expect(plan.wasEdited('src/app/home.html')).toBe(false);
    await plan.edit('src/app/home.html');
    expect(plan.wasEdited('src/app/home.html')).toBe(true);
    expect(plan.files()).toEqual([{ path: 'src/app/home.html', action: 'create' }]);
  });

  it('plans every file of a blueprint', async () => {
    const source = join(root, 'blueprint');
    await mkdir(join(source, 'docs'), { recursive: true });
    await writeFile(join(source, 'docs/guide.md.tpl'), '');
    const plan = new FilePlan(join(root, 'project'));
    await plan.blueprint(source);
    expect(plan.files()).toEqual([{ path: 'docs/guide.md', action: 'create' }]);
  });
});
