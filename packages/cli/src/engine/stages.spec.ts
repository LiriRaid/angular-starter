import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { describe, expect, it, vi } from 'vitest';
import { RuntimeError, UsageError } from '../errors.js';
import { EditShapeError } from './edits/planned.js';
import { DEFAULT_OPTIONS } from '../config/resolve.js';
import type { GenerationContext } from './pipeline.js';
import {
  NEW_PROJECT_STAGES,
  applyAppShell,
  applyArchitecture,
  applyArchitectureToProject,
  applyComponents,
  applyDesign,
  applyPresence,
  installArgsOf,
  validateEnvironment,
} from './stages.js';

const contextWith = (
  components: 'none' | 'recommended' | 'all',
  appShell: 'none' | 'starter' = 'none',
): GenerationContext =>
  ({ options: { ...DEFAULT_OPTIONS, components, appShell } }) as GenerationContext;

describe('new project stages', () => {
  it('adds the design base and the components only with a component collection', () => {
    for (const stage of [applyDesign, applyComponents]) {
      expect(stage.enabled?.(contextWith('none'))).toBe(false);
      expect(stage.enabled?.(contextWith('recommended'))).toBe(true);
      expect(stage.enabled?.(contextWith('all'))).toBe(true);
    }
  });

  it('adds the design base for the application shell too, and the shell only when chosen', () => {
    expect(applyDesign.enabled?.(contextWith('none', 'starter'))).toBe(true);
    expect(applyDesign.enabled?.(contextWith('none', 'none'))).toBe(false);
    expect(applyComponents.enabled?.(contextWith('none', 'starter'))).toBe(false);
    expect(applyAppShell.enabled?.(contextWith('none', 'starter'))).toBe(true);
    expect(applyAppShell.enabled?.(contextWith('all', 'none'))).toBe(false);
  });

  it('adds presence only when it was chosen', () => {
    const context = (presence: 'none' | 'starter'): GenerationContext =>
      ({ options: { ...DEFAULT_OPTIONS, presence } }) as GenerationContext;
    expect(applyPresence.enabled?.(context('starter'))).toBe(true);
    expect(applyPresence.enabled?.(context('none'))).toBe(false);
  });

  it('runs in the order each stage needs', () => {
    const ids = NEW_PROJECT_STAGES.map((stage) => stage.id);
    const order = [
      'create-workspace',
      'apply-architecture',
      'apply-routing',
      'apply-rendering',
      'apply-design',
      'apply-components',
      'apply-app-shell',
      'apply-presence',
      'add-icon-library',
      'write-starter-config',
      'install-dependencies',
      'init-git',
      'verify-project',
    ];
    expect(ids.filter((id) => order.includes(id))).toEqual(order);
  });
});

describe('installArgsOf', () => {
  it('installs from the local cache first and skips the audit and funding calls of npm', () => {
    expect(installArgsOf('npm')).toEqual([
      'install',
      '--no-audit',
      '--no-fund',
      '--prefer-offline',
    ]);
  });

  it('prefers the offline store with pnpm and never freezes the lockfile (the CLI has just changed package.json, and CI turns the freeze on)', () => {
    expect(installArgsOf('pnpm')).toEqual(['install', '--prefer-offline', '--no-frozen-lockfile']);
  });

  it('keeps yarn plain: its modern versions reject the flag', () => {
    expect(installArgsOf('yarn')).toEqual(['install']);
  });
});

describe('validateEnvironment', () => {
  function contextWhere(
    run: (command: string) => Promise<{ stdout: string; stderr: string }>,
  ): GenerationContext {
    return {
      name: 'sa-no-such-project',
      cwd: tmpdir(),
      targetDir: join(tmpdir(), 'sa-no-such-project'),
      options: { ...DEFAULT_OPTIONS, packageManager: 'yarn', install: true, git: false },
      deps: { run, nodeVersion: '24.15.0' },
    } as unknown as GenerationContext;
  }

  it('says a package manager is missing when it cannot be started', async () => {
    const context = contextWhere(async (command) => {
      if (command === 'yarn') throw new Error('spawn yarn ENOENT');
      return { stdout: '1.0.0', stderr: '' };
    });
    await expect(validateEnvironment.run(context)).rejects.toThrow(
      'The package manager "yarn" was not found',
    );
  });

  it('shows what a package manager says when it is installed but refuses to run (corepack inside a folder that names another manager)', async () => {
    const context = contextWhere(async (command) => {
      if (command === 'yarn') {
        throw Object.assign(new Error('Command failed'), {
          stderr:
            'This project is configured to use pnpm because package.json has a "packageManager" field\nmore',
        });
      }
      return { stdout: '1.0.0', stderr: '' };
    });
    await expect(validateEnvironment.run(context)).rejects.toThrow(
      /"yarn" could not run: This project is configured to use pnpm/,
    );
  });
});

describe('applyArchitectureToProject', () => {
  it('turns a file with an unexpected shape into a usage error that names it', async () => {
    const run = vi
      .spyOn(applyArchitecture, 'run')
      .mockRejectedValue(new EditShapeError('src/app/app.ts', 'no class App'));
    await expect(applyArchitectureToProject.run({} as GenerationContext)).rejects.toBeInstanceOf(
      UsageError,
    );
    run.mockRestore();
  });

  it('lets any other failure through as it is', async () => {
    const run = vi.spyOn(applyArchitecture, 'run').mockRejectedValue(new RuntimeError('disk full'));
    await expect(applyArchitectureToProject.run({} as GenerationContext)).rejects.toThrow(
      'disk full',
    );
    await expect(
      applyArchitectureToProject.run({} as GenerationContext),
    ).rejects.not.toBeInstanceOf(UsageError);
    run.mockRestore();
  });
});
