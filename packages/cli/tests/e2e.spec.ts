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

describe.skipIf(!enabled)('as new (end to end, real Angular CLI)', () => {
  let cwd: string;

  beforeAll(async () => {
    expect(existsSync(bin), 'Run "pnpm build" first: dist/bin.js is missing.').toBe(true);
    cwd = await mkdtemp(join(tmpdir(), 'as-e2e-'));
  });

  afterAll(async () => {
    await rm(cwd, { recursive: true, force: true });
  });

  async function create(name: string, ...flags: string[]) {
    const result = await execa(
      'node',
      [bin, 'new', name, '--defaults', '--no-install', '--no-git', ...flags],
      { cwd, reject: false, env: { CI: '1' }, extendEnv: true },
    );
    expect(result.exitCode, `${result.stdout}\n${result.stderr}`).toBe(0);
    return join(cwd, name);
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
});
