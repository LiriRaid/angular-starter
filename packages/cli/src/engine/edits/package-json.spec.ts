import { parse } from 'jsonc-parser';
import { describe, expect, it } from 'vitest';
import { addDependencies } from './package-json.js';

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
