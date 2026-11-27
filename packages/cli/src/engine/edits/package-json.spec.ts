import { parse } from 'jsonc-parser';
import { describe, expect, it } from 'vitest';
import { addDependencies, addDevDependencies, addScripts } from './package-json.js';

const PACKAGE_JSON = `{
  "name": "demo",
  "version": "0.0.0",
  "dependencies": {
    "@angular/core": "^22.3.0",
    "rxjs": "~7.8.0",
    "tslib": "^2.3.0"
  },
  "devDependencies": {
    "typescript": "~6.0.2"
  }
}
`;

describe('addDependencies', () => {
  it('adds the dependency in alphabetical order and leaves the rest untouched', () => {
    const result = addDependencies(PACKAGE_JSON, { '@lucide/angular': '^1.76.0' });
    expect(Object.keys(parse(result).dependencies)).toEqual([
      '@angular/core',
      '@lucide/angular',
      'rxjs',
      'tslib',
    ]);
    expect(parse(result).dependencies['@lucide/angular']).toBe('^1.76.0');
    expect(parse(result).devDependencies).toEqual({ typescript: '~6.0.2' });
    expect(result.endsWith('\n')).toBe(true);
  });

  it('creates the dependencies section when the project has none', () => {
    const result = addDependencies('{\n  "name": "demo"\n}\n', { 'some-lib': '^1.0.0' });
    expect(parse(result)).toEqual({ name: 'demo', dependencies: { 'some-lib': '^1.0.0' } });
  });

  it('does not change a dependency the project already declares', () => {
    const once = addDependencies(PACKAGE_JSON, { rxjs: '^9.0.0' });
    expect(parse(once).dependencies.rxjs).toBe('~7.8.0');
    expect(once).toBe(PACKAGE_JSON);
  });

  it('is idempotent', () => {
    const once = addDependencies(PACKAGE_JSON, { '@lucide/angular': '^1.76.0' });
    expect(addDependencies(once, { '@lucide/angular': '^1.76.0' })).toBe(once);
  });

  it('fails clearly when the file is not valid JSON', () => {
    expect(() => addDependencies('{ "name": ', { a: '1.0.0' })).toThrow(/package\.json/);
  });
});

describe('addDevDependencies', () => {
  it('adds to devDependencies in alphabetical order and leaves dependencies untouched', () => {
    const result = addDevDependencies(PACKAGE_JSON, {
      eslint: '^10.15.0',
      '@eslint/js': '^10.0.1',
    });
    expect(Object.keys(parse(result).devDependencies)).toEqual([
      '@eslint/js',
      'eslint',
      'typescript',
    ]);
    expect(parse(result).dependencies).toEqual(parse(PACKAGE_JSON).dependencies);
  });

  it('creates the section when the project has none', () => {
    const result = addDevDependencies('{\n  "name": "demo"\n}\n', { eslint: '^10.15.0' });
    expect(parse(result)).toEqual({ name: 'demo', devDependencies: { eslint: '^10.15.0' } });
  });

  it('keeps the version of a package the project already declares, and is idempotent', () => {
    const kept = addDevDependencies(PACKAGE_JSON, { typescript: '~7.0.0' });
    expect(kept).toBe(PACKAGE_JSON);
    const once = addDevDependencies(PACKAGE_JSON, { eslint: '^10.15.0' });
    expect(addDevDependencies(once, { eslint: '^10.15.0' })).toBe(once);
  });

  it('does not take a package that is in dependencies for a missing one', () => {
    expect(addDevDependencies(PACKAGE_JSON, { rxjs: '^9.0.0' })).toBe(PACKAGE_JSON);
  });
});

describe('addScripts', () => {
  const WITH_SCRIPTS =
    '{\n  "name": "demo",\n  "scripts": {\n    "build": "ng build",\n    "test": "ng test"\n  }\n}\n';

  it('appends the scripts after the ones the project has, in the order given', () => {
    const result = addScripts(WITH_SCRIPTS, { lint: 'eslint .', 'lint:fix': 'eslint . --fix' });
    expect(Object.keys(parse(result).scripts)).toEqual(['build', 'test', 'lint', 'lint:fix']);
  });

  it('never replaces a script the project already has', () => {
    const result = addScripts(WITH_SCRIPTS, { test: 'vitest run', lint: 'eslint .' });
    expect(parse(result).scripts.test).toBe('ng test');
    expect(parse(result).scripts.lint).toBe('eslint .');
  });

  it('creates the section when the project has none, and is idempotent', () => {
    const once = addScripts('{\n  "name": "demo"\n}\n', { lint: 'eslint .' });
    expect(parse(once)).toEqual({ name: 'demo', scripts: { lint: 'eslint .' } });
    expect(addScripts(once, { lint: 'eslint .' })).toBe(once);
  });

  it('fails clearly when the file is not valid JSON', () => {
    expect(() => addScripts('{ "name": ', { a: 'b' })).toThrow(/package\.json/);
  });
});
