import { mkdir, mkdtemp, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { afterEach, describe, expect, it } from 'vitest';
import { ESSENTIAL_COMPONENT_IDS } from '../config/components.js';
import { optionsSchema } from '../config/schema.js';
import { detectProject } from './detect.js';

const roots: string[] = [];

afterEach(async () => {
  await Promise.all(roots.splice(0).map((dir) => rm(dir, { recursive: true, force: true })));
});

/** A project folder with the given files (path to text); the ones `ng new` always has are added. */
async function project(files: Record<string, string> = {}): Promise<string> {
  const root = await mkdtemp(join(tmpdir(), 'as-detect-'));
  roots.push(root);
  const all: Record<string, string> = {
    'angular.json': JSON.stringify({ projects: { demo: { prefix: 'app' } } }),
    'package.json': JSON.stringify({ name: 'demo', dependencies: { '@angular/core': '^22.0.0' } }),
    'src/styles.css': '',
    'src/app/app.config.ts': 'export const appConfig = {};',
    ...files,
  };
  for (const [path, text] of Object.entries(all)) {
    await mkdir(join(root, dirname(path)), { recursive: true });
    await writeFile(join(root, path), text);
  }
  return root;
}

const ALIASES = JSON.stringify({
  compilerOptions: { paths: { '@features/*': ['./src/app/features/*'] } },
});

const manifest = (extra: Record<string, unknown>): string =>
  JSON.stringify({ name: 'demo', dependencies: { '@angular/core': '^22.0.0' }, ...extra });

describe('detectProject', () => {
  it('describes a project straight from ng new with the options that add nothing', async () => {
    const { options } = await detectProject(await project({ 'package-lock.json': '{}' }));
    expect(options).toMatchObject({
      architecture: 'angular-default',
      routing: 'angular',
      style: 'css',
      tailwind: false,
      rendering: 'csr',
      ssrPurpose: 'none',
      appShell: 'none',
      layout: 'none',
      presence: 'none',
      components: 'none',
      uiSystem: 'none',
      icons: 'none',
      packageManager: 'npm',
      prefix: 'app',
    });
  });

  it('gives a result the configuration schema accepts', async () => {
    const { options } = await detectProject(await project());
    expect(optionsSchema.safeParse(options).success).toBe(true);
  });

  it.each([
    ['src/styles.scss', 'scss'],
    ['src/styles.sass', 'sass'],
    ['src/styles.less', 'less'],
  ])('reads the stylesheet format from %s', async (file, style) => {
    const { options } = await detectProject(await project({ [file]: '' }));
    expect(options.style).toBe(style);
  });

  it('sees Tailwind CSS and Lucide in the dependencies', async () => {
    const root = await project({
      'package.json': manifest({
        devDependencies: { tailwindcss: '^4.0.0' },
        dependencies: { '@angular/core': '^22.0.0', '@lucide/angular': '^1.0.0' },
      }),
    });
    const { options } = await detectProject(root);
    expect(options).toMatchObject({ tailwind: true, icons: 'lucide' });
  });

  it('tells the lock file of each package manager, then the packageManager field, then npm', async () => {
    expect(
      (await detectProject(await project({ 'pnpm-lock.yaml': '' }))).options.packageManager,
    ).toBe('pnpm');
    expect((await detectProject(await project({ 'yarn.lock': '' }))).options.packageManager).toBe(
      'yarn',
    );
    const field = await project({ 'package.json': manifest({ packageManager: 'pnpm@12.9.1' }) });
    expect((await detectProject(field)).options.packageManager).toBe('pnpm');
    expect((await detectProject(await project())).options.packageManager).toBe('npm');
  });

  it('sees Angular SSR, and the Starter SSR by its incremental hydration', async () => {
    const ssr = await project({
      'package.json': manifest({ dependencies: { '@angular/ssr': '^22.0.0' } }),
    });
    expect((await detectProject(ssr)).options).toMatchObject({
      rendering: 'ssr',
      ssrPurpose: 'none',
    });

    const starter = await project({
      'package.json': manifest({ dependencies: { '@angular/ssr': '^22.0.0' } }),
      'src/app/app.config.ts': 'provideClientHydration(withIncrementalHydration())',
    });
    expect((await detectProject(starter)).options).toMatchObject({
      rendering: 'starter-ssr',
      ssrPurpose: 'backoffice',
    });
  });

  it('recognises the Screaming Architecture by its three folders and its aliases', async () => {
    const root = await project({
      'src/app/core/.keep': '',
      'src/app/features/.keep': '',
      'src/app/shared/.keep': '',
      'tsconfig.json': ALIASES,
    });
    expect((await detectProject(root)).options.architecture).toBe('screaming');

    const partial = await project({
      'src/app/core/.keep': '',
      'src/app/shared/.keep': '',
      'tsconfig.json': ALIASES,
    });
    expect((await detectProject(partial)).options.architecture).toBe('angular-default');

    const noAliases = await project({
      'src/app/core/.keep': '',
      'src/app/features/.keep': '',
      'src/app/shared/.keep': '',
    });
    const { options, notes } = await detectProject(noAliases);
    expect(options.architecture).toBe('angular-default');
    expect(notes.join('\n')).toContain('@features alias');
  });

  it('recognises what the starter generates: routing, shell, presence, UI System', async () => {
    const root = await project({
      'src/app/core/.keep': '',
      'src/app/features/app-shell/navigation/navigation.data.ts': '',
      'src/app/features/app-shell/layout/main/main.ts': '',
      'src/app/core/presence/presence.service.ts': '',
      'src/app/features/preference-design/ui-system/ui-system.ts': '',
      'src/app/shared/.keep': '',
      'tsconfig.json': ALIASES,
    });
    expect((await detectProject(root)).options).toMatchObject({
      architecture: 'screaming',
      routing: 'starter',
      appShell: 'starter',
      layout: 'floating-wide',
      presence: 'starter',
      uiSystem: 'starter',
    });
  });

  it('turns the as- components in shared into a collection, or a custom selection', async () => {
    const custom = await project({
      'src/app/shared/components/as-button/as-button.ts': '',
      'src/app/shared/components/as-modal/as-modal.ts': '',
    });
    expect((await detectProject(custom)).options).toMatchObject({
      components: 'custom',
      componentList: ['button', 'modal'],
    });

    const files = Object.fromEntries(
      ESSENTIAL_COMPONENT_IDS.map((id) => [`src/app/shared/components/as-${id}/as-${id}.ts`, '']),
    );
    expect((await detectProject(await project(files))).options.components).toBe('recommended');
  });

  it('keeps the prefix of the application, and replaces the reserved one with a note', async () => {
    const acme = await project({
      'angular.json': JSON.stringify({ projects: { demo: { prefix: 'acme' } } }),
    });
    expect((await detectProject(acme)).options.prefix).toBe('acme');

    const reserved = await project({
      'angular.json': JSON.stringify({ projects: { demo: { prefix: 'as' } } }),
    });
    const { options, notes } = await detectProject(reserved);
    expect(options.prefix).toBe('app');
    expect(notes.join('\n')).toContain('"as" is reserved');
  });

  it('refuses a folder that is not an Angular workspace', async () => {
    const root = await mkdtemp(join(tmpdir(), 'as-detect-'));
    roots.push(root);
    await expect(detectProject(root)).rejects.toThrow('angular.json');
  });
});
