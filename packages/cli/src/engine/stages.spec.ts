import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { describe, expect, it, vi } from 'vitest';
import { RuntimeError } from '../errors.js';
import { screamingProfile } from './architectures/screaming.js';
import { DEFAULT_OPTIONS } from '../config/resolve.js';
import type { GenerationContext } from './pipeline.js';
import { toolingProfile } from './tooling/tooling.js';
import {
  NEW_PROJECT_STAGES,
  applyAppShell,
  applyArchitectureToProject,
  applyComponents,
  applyDesign,
  applyPresence,
  applyTooling,
  formatProject,
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
      'apply-tooling',
      'write-starter-config',
      'install-dependencies',
      'format-project',
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
  const contextOf = (): GenerationContext =>
    ({
      name: 'demo',
      targetDir: tmpdir(),
      options: { ...DEFAULT_OPTIONS, architecture: 'screaming' },
      warnings: [],
      notes: [],
    }) as unknown as GenerationContext;

  it('tells what the profile adapted and removed, what to review and what to do next', async () => {
    const adopt = vi.spyOn(screamingProfile, 'adopt').mockResolvedValue({
      adapted: ['src/app/app.ts'],
      removed: ['src/app/app.html'],
      review: [{ file: 'src/app/app.css', reason: 'it is no longer used' }],
    });
    const context = contextOf();
    await applyArchitectureToProject.run(context);
    expect(context.notes?.join('\n')).toContain('Adapted: src/app/app.ts.');
    expect(context.notes?.join('\n')).toContain('Removed');
    expect(context.notes?.join('\n')).toContain('sa generate feature');
    expect(context.warnings).toEqual(['Review src/app/app.css: it is no longer used']);
    adopt.mockRestore();
  });

  it('lets a failure of the profile through as it is', async () => {
    const adopt = vi
      .spyOn(screamingProfile, 'adopt')
      .mockRejectedValue(new RuntimeError('disk full'));
    await expect(applyArchitectureToProject.run(contextOf())).rejects.toThrow('disk full');
    adopt.mockRestore();
  });
});

describe('tooling stages', () => {
  const contextWith = (
    install: boolean,
    run: GenerationContext['deps']['run'],
    packageManager: 'npm' | 'pnpm' | 'yarn' = 'pnpm',
  ): GenerationContext =>
    ({
      name: 'demo',
      targetDir: join(tmpdir(), 'demo'),
      options: { ...DEFAULT_OPTIONS, install, packageManager },
      deps: { run, nodeVersion: '24.15.0' },
      warnings: [],
      notes: [],
    }) as unknown as GenerationContext;

  it('adds lint and format to every project, whatever its architecture or options', () => {
    expect(applyTooling.enabled).toBeUndefined();
  });

  describe('what applyTooling tells after the steps', () => {
    const toldBy = async (install: boolean, created: boolean): Promise<string> => {
      const apply = vi.spyOn(toolingProfile, 'apply').mockResolvedValue({ eslint: 'added' });
      const context = contextWith(install, vi.fn());
      context.created = created;
      await applyTooling.run(context);
      apply.mockRestore();
      return (context.notes ?? []).join('\n');
    };

    it('says nothing when the dependencies are installed', async () => {
      expect(await toldBy(true, true)).toBe('');
      expect(await toldBy(true, false)).toBe('');
    });

    it('asks a new project that was not installed to format it after installing', async () => {
      const notes = await toldBy(false, true);

      expect(notes).toContain('pnpm install');
      expect(notes).toContain('pnpm run format');
    });

    it('asks a project that was not installed, when the tooling was added to it, to install: its code was not reformatted', async () => {
      const notes = await toldBy(false, false);

      expect(notes).toContain('pnpm install');
      expect(notes).not.toContain('run format');
    });
  });

  it('formats the generated code only when the dependencies are installed, since Prettier comes with them', () => {
    expect(formatProject.enabled?.(contextWith(true, vi.fn()))).toBe(true);
    expect(formatProject.enabled?.(contextWith(false, vi.fn()))).toBe(false);
  });

  it.each(['npm', 'pnpm', 'yarn'] as const)(
    'formats with the format script of the project, through %s',
    async (manager) => {
      const run = vi.fn().mockResolvedValue({ stdout: '', stderr: '' });
      await formatProject.run(contextWith(true, run, manager));

      expect(run).toHaveBeenCalledWith(
        manager,
        ['run', 'format'],
        expect.objectContaining({ cwd: join(tmpdir(), 'demo') }),
      );
    },
  );

  it('warns instead of failing when the formatting cannot run: the project is complete without it', async () => {
    const context = contextWith(true, vi.fn().mockRejectedValue(new Error('prettier is gone')));
    await formatProject.run(context);

    expect(context.warnings.join('\n')).toContain('prettier is gone');
    expect(context.warnings.join('\n')).toContain('run format');
  });
});
