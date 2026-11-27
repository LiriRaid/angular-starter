import { mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { DEFAULT_OPTIONS, resolveOptions } from '../config/resolve.js';
import type { StarterOptions } from '../config/schema.js';
import { ANGULAR_README } from '../../tests/helpers/generated-workspace.js';
import { PROJECT_END, PROJECT_START, refreshProjectReadme } from './project-readme.js';

let project: string;

beforeEach(async () => {
  project = await mkdtemp(join(tmpdir(), 'sa-readme-'));
  await mkdir(join(project, 'src/app/shared/components/sa-button'), { recursive: true });
  await mkdir(join(project, 'src/app/shared/components/sa-modal'), { recursive: true });
});

afterEach(async () => {
  await rm(project, { recursive: true, force: true });
});

const README = (): Promise<string> => readFile(join(project, 'README.md'), 'utf8');
const refresh = (options: StarterOptions = DEFAULT_OPTIONS) =>
  refreshProjectReadme({ targetDir: project, name: 'My Shop', options });

describe('refreshProjectReadme', () => {
  it('replaces the README that ng new writes with one that describes the project', async () => {
    await writeFile(join(project, 'README.md'), ANGULAR_README);
    await refresh();
    const text = await README();
    expect(text).not.toContain('This project was generated using [Angular CLI]');
    expect(text.startsWith('# My Shop\n')).toBe(true);
    expect(text).toContain(PROJECT_START);
    expect(text).toContain(PROJECT_END);
    expect(text).toContain('Starter Angular');
  });

  it('names what the project has, from its options', async () => {
    await writeFile(join(project, 'README.md'), ANGULAR_README);
    await refresh(
      resolveOptions({
        flags: {
          architecture: 'screaming',
          routing: 'starter',
          appShell: 'starter',
          components: 'recommended',
          uiSystem: 'starter',
          icons: 'lucide',
          presence: 'starter',
        },
      }),
    );
    const text = await README();
    for (const piece of [
      'Screaming Architecture',
      'Starter Angular Routing',
      'Starter Angular App Shell',
      'Starter Angular Presence',
      'Starter Angular UI System',
      'Lucide Icons',
      'Tailwind CSS',
      'Client-Side Rendering',
    ]) {
      expect(text, piece).toContain(piece);
    }
    // The components are counted from the folders the project has.
    expect(text).toContain('2 `sa-` components');
  });

  it('leaves out what the project does not have', async () => {
    await writeFile(join(project, 'README.md'), ANGULAR_README);
    await rm(join(project, 'src/app/shared'), { recursive: true });
    await refresh(
      resolveOptions({
        flags: {
          architecture: 'angular-default',
          routing: 'angular',
          components: 'none',
          appShell: 'none',
          icons: 'none',
        },
      }),
    );
    const text = await README();
    expect(text).toContain('Angular default structure');
    expect(text).not.toContain('Starter Angular UI System');
    expect(text).not.toContain('`sa-` components');
    expect(text).not.toContain('sa generate feature');
  });

  it('gives the commands of the package manager of the project', async () => {
    await writeFile(join(project, 'README.md'), ANGULAR_README);
    await refresh({ ...DEFAULT_OPTIONS, packageManager: 'pnpm' });
    expect(await README()).toContain('pnpm start');
    await writeFile(join(project, 'README.md'), ANGULAR_README);
    await refresh({ ...DEFAULT_OPTIONS, packageManager: 'npm' });
    expect(await README()).toContain('npm start');
    await writeFile(join(project, 'README.md'), ANGULAR_README);
    await refresh({ ...DEFAULT_OPTIONS, packageManager: 'yarn' });
    expect(await README()).toContain('yarn start');
  });

  describe('lint and format commands', () => {
    const SCRIPTS = {
      'test:watch': 'ng test --watch',
      lint: 'eslint "src/**/*.{ts,html}"',
      'lint:fix': 'eslint "src/**/*.{ts,html}" --fix',
      format: 'prettier --write "src/**/*.{ts,html,css}"',
      'format:check': 'prettier --check "src/**/*.{ts,html,css}"',
    };

    it('lists the ones the project has, in the syntax of its package manager', async () => {
      await writeFile(join(project, 'README.md'), ANGULAR_README);
      await writeFile(join(project, 'package.json'), JSON.stringify({ scripts: SCRIPTS }));
      await refresh({ ...DEFAULT_OPTIONS, packageManager: 'pnpm' });
      const pnpm = await README();
      for (const command of [
        'pnpm test:watch',
        'pnpm lint',
        'pnpm lint:fix',
        'pnpm format',
        'pnpm format:check',
      ]) {
        expect(pnpm, command).toContain(`\`${command}\``);
      }

      await writeFile(join(project, 'README.md'), ANGULAR_README);
      await refresh({ ...DEFAULT_OPTIONS, packageManager: 'npm' });
      const npm = await README();
      for (const command of [
        'npm run test:watch',
        'npm run lint',
        'npm run lint:fix',
        'npm run format',
        'npm run format:check',
      ]) {
        expect(npm, command).toContain(`\`${command}\``);
      }
    });

    it('does not list a command the project does not have', async () => {
      await writeFile(join(project, 'README.md'), ANGULAR_README);
      await writeFile(
        join(project, 'package.json'),
        JSON.stringify({ scripts: { format: 'prettier --write .' } }),
      );
      await refresh({ ...DEFAULT_OPTIONS, packageManager: 'pnpm' });
      const text = await README();

      expect(text).toContain('`pnpm format`');
      expect(text).not.toContain('pnpm lint');
      expect(text).not.toContain('format:check');
    });

    it('lists none when the project has no package.json to read', async () => {
      await writeFile(join(project, 'README.md'), ANGULAR_README);
      await refresh();

      expect(await README()).not.toContain('lint');
    });
  });

  it('rewrites only its own block when it is there, and keeps what the developer wrote around it', async () => {
    await writeFile(join(project, 'README.md'), ANGULAR_README);
    await refresh();
    const first = await README();
    const written = `# My Shop\n\nOur own intro.\n\n${first.slice(first.indexOf(PROJECT_START))}\n## Deploy\n\nWe deploy on Fridays.\n`;
    await writeFile(join(project, 'README.md'), written);
    await refresh({ ...DEFAULT_OPTIONS, uiSystem: 'none', components: 'none', appShell: 'none' });
    const text = await README();
    expect(text).toContain('Our own intro.');
    expect(text).toContain('We deploy on Fridays.');
    expect(text.startsWith('# My Shop\n\nOur own intro.')).toBe(true);
    expect(text).not.toContain('Starter Angular UI System');
  });

  it('leaves a README the developer wrote, with no block, exactly as it is', async () => {
    const own = '# My Shop\n\nHow to run it: ask Ana.\n';
    await writeFile(join(project, 'README.md'), own);
    await refresh();
    expect(await README()).toBe(own);
  });

  it('leaves a README that mentions Angular CLI but is no longer the one ng new wrote', async () => {
    const edited = `${ANGULAR_README}\n## Our notes\n\nKeep the lockfile.\n`;
    await writeFile(join(project, 'README.md'), edited);
    await refresh();
    // The Angular README is recognised by its first lines being intact: an extra section is the developer's.
    expect(await README()).toBe(edited);
  });

  it('is idempotent', async () => {
    await writeFile(join(project, 'README.md'), ANGULAR_README);
    await refresh();
    const once = await README();
    await refresh();
    expect(await README()).toBe(once);
  });

  it('does not bring back a README the developer removed', async () => {
    await refresh();
    await expect(README()).rejects.toThrow();
  });

  it('keeps the line endings of the file', async () => {
    await writeFile(join(project, 'README.md'), ANGULAR_README.replace(/\n/g, '\r\n'));
    await refresh();
    const text = await README();
    expect(text).toContain('\r\n');
    expect(text.replace(/\r\n/g, '')).not.toContain('\n');
  });
});
