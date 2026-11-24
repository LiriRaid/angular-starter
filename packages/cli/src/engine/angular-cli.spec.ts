import { mkdir, mkdtemp, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, describe, expect, it } from 'vitest';
import { ANGULAR_CLI_VERSION } from '../compat.js';
import { DEFAULT_OPTIONS } from '../config/resolve.js';
import { buildNgAddSsrCommand, buildNgCommand } from './angular-cli.js';

describe('buildNgCommand', () => {
  it('runs the tested Angular CLI version through npx', () => {
    const { command, args } = buildNgCommand('my-app', DEFAULT_OPTIONS);
    expect(command).toBe('npx');
    expect(args.slice(0, 4)).toEqual([
      '--yes',
      `@angular/cli@${ANGULAR_CLI_VERSION}`,
      'new',
      'my-app',
    ]);
  });

  it('passes every modelled option explicitly and never lets ng install or init git', () => {
    const { args } = buildNgCommand('my-app', DEFAULT_OPTIONS);
    expect(args).toEqual(
      expect.arrayContaining([
        '--defaults',
        '--interactive=false',
        '--skip-install',
        '--skip-git',
        '--routing',
        '--zoneless',
        '--ai-config=none',
        '--package-manager=npm',
        '--prefix=app',
        '--ssr=false',
      ]),
    );
  });

  it('uses the official Tailwind integration for the CSS format', () => {
    expect(buildNgCommand('a', { ...DEFAULT_OPTIONS, tailwind: true }).args).toContain(
      '--style=tailwind',
    );
  });

  it('keeps the chosen stylesheet format without Tailwind', () => {
    const options = { ...DEFAULT_OPTIONS, tailwind: false, style: 'scss' } as const;
    expect(buildNgCommand('a', options).args).toContain('--style=scss');
  });

  it('enables Angular SSR for the ssr rendering strategy', () => {
    const args = buildNgCommand('a', { ...DEFAULT_OPTIONS, rendering: 'ssr' }).args;
    expect(args).toContain('--ssr');
    expect(args).not.toContain('--ssr=false');
  });

  it('starts the Starter SSR strategy from the Angular SSR setup', () => {
    const args = buildNgCommand('a', { ...DEFAULT_OPTIONS, rendering: 'starter-ssr' }).args;
    expect(args).toContain('--ssr');
    expect(args).not.toContain('--ssr=false');
  });

  it('forwards the package manager and prefix', () => {
    const args = buildNgCommand('a', {
      ...DEFAULT_OPTIONS,
      packageManager: 'pnpm',
      prefix: 'acme',
    }).args;
    expect(args).toContain('--package-manager=pnpm');
    expect(args).toContain('--prefix=acme');
  });
});

describe('buildNgAddSsrCommand', () => {
  const projects: string[] = [];
  afterEach(async () => {
    await Promise.all(projects.splice(0).map((dir) => rm(dir, { recursive: true, force: true })));
  });

  async function projectDir(withLocalCli: boolean, withManifest = true): Promise<string> {
    const dir = await mkdtemp(join(tmpdir(), 'as-ng-add-'));
    projects.push(dir);
    if (withLocalCli) {
      await mkdir(join(dir, 'node_modules', '@angular', 'cli', 'bin'), { recursive: true });
      await writeFile(join(dir, 'node_modules', '@angular', 'cli', 'bin', 'ng.js'), '');
      if (withManifest) {
        await writeFile(join(dir, 'node_modules', '@angular', 'cli', 'package.json'), '{}');
      }
    }
    return dir;
  }

  it("runs the project's own Angular CLI with node, never through the .bin shim: pnpm rewrites the Windows shim while cmd.exe is reading it, and cmd.exe then runs the command a second time", async () => {
    const dir = await projectDir(true);
    expect(await buildNgAddSsrCommand(dir)).toEqual({
      command: process.execPath,
      args: [
        join(dir, 'node_modules', '@angular', 'cli', 'bin', 'ng.js'),
        'add',
        '@angular/ssr',
        '--skip-confirmation',
      ],
    });
  });

  it('downloads the tested Angular CLI version through npx when the project has no dependencies installed', async () => {
    const dir = await projectDir(false);
    expect(await buildNgAddSsrCommand(dir)).toEqual({
      command: 'npx',
      args: [
        '--yes',
        `@angular/cli@${ANGULAR_CLI_VERSION}`,
        'add',
        '@angular/ssr',
        '--skip-confirmation',
      ],
    });
  });

  it('falls back to npx when the installed CLI is incomplete (an interrupted install left ng.js without its package.json)', async () => {
    const dir = await projectDir(true, false);
    expect((await buildNgAddSsrCommand(dir)).command).toBe('npx');
  });
});
