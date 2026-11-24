import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';

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

/** The previous name, written in pieces so this spec does not match itself. */
const OLD_SLUG = ['as', 'starter'].join('-');
const OLD_NAME = ['AS', 'Starter'].join(' ');

function filesBelow(folder: string): string[] {
  return readdirSync(join(root, folder)).flatMap((entry) => {
    const path = join(folder, entry);
    if (entry === 'node_modules' || entry === 'dist') return [];
    return statSync(join(root, path)).isDirectory() ? filesBelow(path) : [path];
  });
}

describe('the name of the project', () => {
  const manifest = JSON.parse(read('packages/cli/package.json')) as Manifest;

  it('publishes the CLI under the author scope, never as Angular itself', () => {
    expect(manifest.name).toBe('@liriraid/angular-starter');
  });

  it('is still 0.x: 1.0 waits for the author', () => {
    expect(manifest.version).toBe('0.1.0');
  });

  it('installs `as` and the full name `angular-starter`, and no other binary', () => {
    expect(manifest.bin).toEqual({ as: 'dist/bin.js', 'angular-starter': 'dist/bin.js' });
  });

  it('points the repository, the home page and the issues to angular-starter', () => {
    expect(manifest.repository.url).toBe('git+https://github.com/LiriRaid/angular-starter.git');
    expect(manifest.homepage).toBe('https://github.com/LiriRaid/angular-starter#readme');
    expect(manifest.bugs?.url).toBe('https://github.com/LiriRaid/angular-starter/issues');
  });

  it('names the root workspace angular-starter', () => {
    expect((JSON.parse(read('package.json')) as { name: string }).name).toBe('angular-starter');
  });

  it('leaves no trace of the old name in what ships or is read today', () => {
    const files = [
      'README.md',
      'CONTRIBUTING.md',
      'SECURITY.md',
      'package.json',
      'packages/cli/package.json',
      ...filesBelow('blueprints'),
      ...filesBelow('packages/cli/src'),
      ...filesBelow('packages/cli/tests').filter((file) => !file.endsWith('naming.spec.ts')),
    ];
    const offenders = files.filter((file) => {
      const text = read(file);
      return text.includes(OLD_SLUG) || text.includes(OLD_NAME);
    });
    expect(offenders.map((file) => relative('.', file))).toEqual([]);
  });

  it('tells in the README that it is not affiliated with Google, and about the system `as`', () => {
    const readme = read('README.md');
    expect(readme).toMatch(/not affiliated with(,| or)? .*Google/i);
    expect(readme).toContain('GNU assembler');
    expect(readme).toContain('angular-starter');
  });
});
