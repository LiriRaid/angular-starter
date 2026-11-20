import { existsSync } from 'node:fs';
import { mkdtemp, readFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execa } from 'execa';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';

/**
 * Runs the compiled CLI against the real Angular CLI (needs network and a prior `pnpm build`).
 * Opt in with AS_E2E=1.
 */
const enabled = process.env['AS_E2E'] === '1';
const bin = fileURLToPath(new URL('../dist/bin.js', import.meta.url));
const TIMEOUT_MS = 5 * 60_000;
const INSTALL_TIMEOUT_MS = 15 * 60_000;
const CLEANUP_TIMEOUT_MS = 2 * 60_000;

describe.skipIf(!enabled)('as new (end to end, real Angular CLI)', () => {
  let cwd: string;

  beforeAll(async () => {
    expect(existsSync(bin), 'Run "pnpm build" first: dist/bin.js is missing.').toBe(true);
    cwd = await mkdtemp(join(tmpdir(), 'as-e2e-'));
  });

  // Deleting two installed projects (node_modules) takes longer than the default hook timeout.
  afterAll(async () => {
    await rm(cwd, { recursive: true, force: true });
  }, CLEANUP_TIMEOUT_MS);

  async function create(name: string, ...flags: string[]) {
    const result = await execa(
      'node',
      [bin, 'new', name, '--defaults', '--no-install', '--no-git', ...flags],
      { cwd, reject: false, env: { CI: '1' }, extendEnv: true },
    );
    expect(result.exitCode, `${result.stdout}\n${result.stderr}`).toBe(0);
    return join(cwd, name);
  }

  /** Creates a project with its dependencies installed, so that it can be built and tested. */
  async function createInstalled(name: string, ...flags: string[]) {
    const result = await execa(
      'node',
      [bin, 'new', name, '--defaults', '--no-git', '--package-manager', 'npm', ...flags],
      { cwd, reject: false, env: { CI: '1' }, extendEnv: true },
    );
    expect(
      result.exitCode,
      `${result.stdout}
${result.stderr}`,
    ).toBe(0);
    return join(cwd, name);
  }

  /** Runs the compiled CLI inside an existing project, as a person would. */
  async function asProject(project: string, ...args: string[]) {
    const result = await execa('node', [bin, ...args], {
      cwd: project,
      reject: false,
      env: { CI: '1' },
      extendEnv: true,
    });
    expect(
      result.exitCode,
      `as ${args.join(' ')}
${result.stdout}
${result.stderr}`,
    ).toBe(0);
  }

  async function ng(project: string, ...args: string[]) {
    const result = await execa('npx', ['--no-install', 'ng', ...args], {
      cwd: project,
      reject: false,
      env: { CI: '1' },
      extendEnv: true,
    });
    expect(
      result.exitCode,
      `ng ${args.join(' ')}
${result.stdout}
${result.stderr}`,
    ).toBe(0);
  }

  const read = (project: string, file: string): Promise<string> =>
    readFile(join(project, file), 'utf8');

  it(
    'creates a CSS + Tailwind application with the default options',
    async () => {
      const project = await create('e2e-tailwind');
      expect(existsSync(join(project, 'angular-starter.config.json'))).toBe(true);
      expect(existsSync(join(project, 'src', 'main.ts'))).toBe(true);
      const manifest = await read(project, 'package.json');
      expect(manifest).toContain('tailwindcss');
      // Zoneless is the Angular 22 default: the app has no zone.js at all.
      expect(manifest).not.toContain('zone.js');
    },
    TIMEOUT_MS,
  );

  it(
    'creates an SCSS application without Tailwind and records the options',
    async () => {
      const project = await create('e2e-scss', '--style', 'scss', '--prefix', 'acme');
      expect(existsSync(join(project, 'src', 'styles.scss'))).toBe(true);
      expect(await read(project, 'package.json')).not.toContain('tailwindcss');
      const config = JSON.parse(await read(project, 'angular-starter.config.json'));
      expect(config.options).toMatchObject({ style: 'scss', tailwind: false, prefix: 'acme' });
      expect(await read(project, 'angular.json')).toContain('"prefix": "acme"');
    },
    TIMEOUT_MS,
  );

  it(
    'creates an application with the default Angular SSR setup',
    async () => {
      const project = await create('e2e-ssr', '--rendering', 'ssr');
      expect(existsSync(join(project, 'src', 'main.server.ts'))).toBe(true);
    },
    TIMEOUT_MS,
  );

  it.each([
    ['csr', 'e2e-screaming'],
    ['ssr', 'e2e-screaming-ssr'],
  ])(
    'creates a Screaming Architecture project (%s) that builds and passes its tests',
    async (rendering, name) => {
      const project = await createInstalled(
        name,
        '--architecture',
        'screaming',
        '--rendering',
        rendering,
      );

      for (const file of [
        'src/app/core/README.md',
        'src/app/features/home/home.routes.ts',
        'src/app/shared/components/index.ts',
      ]) {
        expect(existsSync(join(project, file)), file).toBe(true);
      }
      expect(await read(project, 'tsconfig.json')).toContain('"@features/*"');
      const config = JSON.parse(await read(project, 'angular-starter.config.json'));
      expect(config.options.architecture).toBe('screaming');

      await ng(project, 'build');
      await ng(project, 'test', '--watch=false');
    },
    INSTALL_TIMEOUT_MS,
  );

  it.each([
    ['csr', 'e2e-routing'],
    ['ssr', 'e2e-routing-ssr'],
  ])(
    'creates a Screaming project with the Angular Starter routing (%s) that builds and passes its tests',
    async (rendering, name) => {
      const project = await createInstalled(
        name,
        '--architecture',
        'screaming',
        '--routing',
        'starter',
        '--rendering',
        rendering,
      );

      for (const file of [
        'src/app/core/navigation/breadcrumb.service.ts',
        'src/app/core/navigation/navigation-title.strategy.ts',
        'src/app/core/navigation/navigation.providers.ts',
        'src/app/features/app-shell/navigation/navigation.data.ts',
      ]) {
        expect(existsSync(join(project, file)), file).toBe(true);
      }
      expect(await read(project, 'src/app/app.config.ts')).toContain(
        `provideNavigation(APP_NAVIGATION, { appName: '${name}' })`,
      );
      const config = JSON.parse(await read(project, 'angular-starter.config.json'));
      expect(config.options).toMatchObject({ architecture: 'screaming', routing: 'starter' });

      await ng(project, 'build');
      await ng(project, 'test', '--watch=false');
    },
    INSTALL_TIMEOUT_MS,
  );

  it(
    'creates a Starter SSR project with incremental hydration that builds and passes its tests',
    async () => {
      const project = await createInstalled(
        'e2e-starter-ssr',
        '--architecture',
        'screaming',
        '--routing',
        'starter',
        '--rendering',
        'starter-ssr',
        '--icons',
        'none',
        '--components',
        'none',
      );
      const config = await read(project, 'src/app/app.config.ts');
      expect(config).toContain('withIncrementalHydration()');
      expect(await read(project, 'src/app/features/home/home.html')).toContain(
        '@defer (hydrate on viewport)',
      );
      expect(existsSync(join(project, 'src', 'main.server.ts'))).toBe(true);

      await ng(project, 'build');
      await ng(project, 'test', '--watch=false');
    },
    INSTALL_TIMEOUT_MS,
  );

  it(
    'adds routing, icons and SSR to an existing project and generates a feature that build and test',
    async () => {
      const project = await createInstalled(
        'e2e-add',
        '--architecture',
        'screaming',
        '--routing',
        'angular',
        '--icons',
        'none',
        '--components',
        'none',
      );
      await asProject(project, 'add', 'routing', 'starter');
      await asProject(project, 'add', 'icons', 'lucide');
      await asProject(project, 'generate', 'feature', 'billing');
      await asProject(project, 'generate', 'component', 'invoice-card', '--feature', 'billing');
      await asProject(project, 'add', 'rendering', 'starter-ssr');

      const config = JSON.parse(await read(project, 'angular-starter.config.json'));
      expect(config.options).toMatchObject({
        routing: 'starter',
        icons: 'lucide',
        rendering: 'starter-ssr',
      });
      expect(await read(project, 'src/app/app.config.ts')).toContain('withIncrementalHydration()');
      expect(
        existsSync(join(project, 'src/app/features/billing/invoice-card/invoice-card.ts')),
      ).toBe(true);
      expect(
        await read(project, 'src/app/features/app-shell/navigation/navigation.data.ts'),
      ).toContain("id: 'billing'");

      await ng(project, 'build');
      await ng(project, 'test', '--watch=false');
    },
    INSTALL_TIMEOUT_MS,
  );

  it(
    'installs the Lucide Icons package and still builds',
    async () => {
      const project = await createInstalled('e2e-lucide', '--icons', 'lucide');
      expect(
        JSON.parse(await read(project, 'package.json')).dependencies['@lucide/angular'],
      ).toMatch(/^\^1\./);
      expect(existsSync(join(project, 'node_modules', '@lucide', 'angular'))).toBe(true);
      await ng(project, 'build');
    },
    INSTALL_TIMEOUT_MS,
  );
});
