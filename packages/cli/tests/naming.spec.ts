import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { PROJECT_CONFIG_FILE } from '../src/config/project-config.js';
import { RESERVED_PREFIX } from '../src/config/schema.js';

const root = fileURLToPath(new URL('../../../', import.meta.url));
const read = (path: string): string => readFileSync(join(root, path), 'utf8');

interface Manifest {
  name: string;
  version: string;
  bin: Record<string, string>;
  homepage?: string;
  bugs?: { url: string };
  repository: { url: string };
}

/** The previous names, written in pieces so this spec does not match itself. */
const OLD_NAMES = [
  ['as', 'starter'].join('-'),
  ['AS', 'Starter'].join(' '),
  ['angular', 'starter'].join('-'),
  ['Angular', 'Starter'].join(' '),
  ['ANGULAR', 'STARTER'].join('_'),
];

function filesBelow(folder: string): string[] {
  return readdirSync(join(root, folder)).flatMap((entry) => {
    const path = join(folder, entry);
    if (entry === 'node_modules' || entry === 'dist') return [];
    return statSync(join(root, path)).isDirectory() ? filesBelow(path) : [path];
  });
}

/** What ships or is read today; the history (ADR, plans, CHANGELOG) keeps the names of its time. */
function currentFiles(): string[] {
  return [
    'README.md',
    'CONTRIBUTING.md',
    'SECURITY.md',
    'package.json',
    'packages/cli/package.json',
    ...filesBelow('blueprints'),
    ...filesBelow('packages/cli/src'),
    ...filesBelow('packages/cli/tests').filter((file) => !file.endsWith('naming.spec.ts')),
  ];
}

describe('the name of the project', () => {
  const manifest = JSON.parse(read('packages/cli/package.json')) as Manifest;

  it('publishes the CLI under the author scope, never as Angular itself', () => {
    expect(manifest.name).toBe('@liriraid/starter-angular');
  });

  it('is still 0.x: 1.0 waits for the author', () => {
    expect(manifest.version).toBe('0.1.0');
  });

  it('installs `sa` and the full name `starter-angular`, and no other binary', () => {
    expect(manifest.bin).toEqual({ sa: 'dist/bin.js', 'starter-angular': 'dist/bin.js' });
  });

  it('points the repository, the home page and the issues to starter-angular', () => {
    expect(manifest.repository.url).toBe('git+https://github.com/LiriRaid/starter-angular.git');
    expect(manifest.homepage).toBe('https://github.com/LiriRaid/starter-angular#readme');
    expect(manifest.bugs?.url).toBe('https://github.com/LiriRaid/starter-angular/issues');
  });

  it('names the root workspace starter-angular', () => {
    expect((JSON.parse(read('package.json')) as { name: string }).name).toBe('starter-angular');
  });

  it('names the file of the configuration of a project after the project', () => {
    expect(PROJECT_CONFIG_FILE).toBe('starter-angular.config.json');
  });

  it('leaves no trace of the previous names in what ships or is read today', () => {
    const offenders = currentFiles().filter((file) => {
      const text = read(file);
      return OLD_NAMES.some((name) => text.includes(name));
    });
    expect(offenders).toEqual([]);
  });

  it('tells in the README that it is not affiliated with Google, and about the system `sa`', () => {
    const readme = read('README.md');
    expect(readme).toMatch(/not affiliated with(,| or)? .*Google/i);
    expect(readme).toMatch(/process accounting/i);
    expect(readme).toContain('starter-angular');
  });

  it('explains in the README why the web calls it Starter for Angular', () => {
    const readme = read('README.md');
    expect(readme).toContain('Starter for Angular');
    expect(readme).toMatch(/Starter Angular/);
  });
});

describe('the prefix of what is generated', () => {
  it('reserves sa as the prefix of the components of the starter', () => {
    expect(RESERVED_PREFIX).toBe('sa');
  });

  it('leaves no as- prefix in the blueprints or in the CLI: selectors, classes, tokens and files', () => {
    const dashed = /(?<![A-Za-z0-9])-{0,2}as-[a-z]/;
    const pascal = /(?<![A-Za-z0-9])As[A-Z]/;
    // The directives, in the camelCase of the template and in the lowercase the DOM gives the attribute.
    const directive = /(?<![A-Za-z0-9])as(Tooltip|Ripple|tooltip|ripple)\b/;
    const offenders = currentFiles().filter((file) => {
      if (file.endsWith('.spec.ts') && file.includes('tests')) return false;
      const name = file.split(/[\\/]/).pop() ?? '';
      const folders = file.split(/[\\/]/);
      if (folders.some((part) => /^as-/.test(part)) || /^as-/.test(name)) return true;
      const text = read(file);
      return dashed.test(text) || pascal.test(text) || directive.test(text);
    });
    expect(offenders).toEqual([]);
  });

  it('writes the environment variables of the project with the SA_ prefix', () => {
    const offenders = currentFiles().filter((file) => /(?<![A-Z_])AS_[A-Z]/.test(read(file)));
    expect(offenders).toEqual([]);
  });
});
