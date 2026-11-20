import { describe, expect, it } from 'vitest';
import { addStyleEntry } from './angular-json.js';

/** The part of angular.json that `ng new` (Angular CLI 22.3) writes and the edit reads. */
const ANGULAR_JSON = `{
  "$schema": "./node_modules/@angular/cli/lib/config/schema.json",
  "version": 1,
  "projects": {
    "demo": {
      "projectType": "application",
      "prefix": "app",
      "architect": {
        "build": {
          "builder": "@angular/build:application",
          "options": {
            "browser": "src/main.ts",
            "styles": [
              "src/styles.css"
            ]
          }
        },
        "test": {
          "builder": "@angular/build:unit-test"
        }
      }
    }
  }
}
`;

describe('addStyleEntry', () => {
  it('appends the file to the styles of the build target', () => {
    const result = addStyleEntry(ANGULAR_JSON, 'src/styles/design.css');
    const styles = JSON.parse(result).projects.demo.architect.build.options.styles;
    expect(styles).toEqual(['src/styles.css', 'src/styles/design.css']);
  });

  it('keeps the rest of the file as it was', () => {
    const result = addStyleEntry(ANGULAR_JSON, 'src/styles/design.css');
    expect(result).toContain('"$schema": "./node_modules/@angular/cli/lib/config/schema.json"');
    expect(JSON.parse(result).projects.demo.prefix).toBe('app');
    expect(result.endsWith('\n')).toBe(true);
  });

  it('is idempotent', () => {
    const once = addStyleEntry(ANGULAR_JSON, 'src/styles/design.css');
    expect(addStyleEntry(once, 'src/styles/design.css')).toBe(once);
  });

  it('finds the project whatever its name', () => {
    const renamed = ANGULAR_JSON.replace('"demo"', '"inventory-system"');
    const styles = JSON.parse(addStyleEntry(renamed, 'a.css')).projects['inventory-system']
      .architect.build.options.styles;
    expect(styles).toContain('a.css');
  });

  it('fails clearly when the build target has no styles', () => {
    const without = ANGULAR_JSON.replace(/"styles": \[\s*"src\/styles.css"\s*\]/, '"x": 1');
    expect(() => addStyleEntry(without, 'a.css')).toThrow(/styles/);
  });

  it('fails clearly when the file is not JSON', () => {
    expect(() => addStyleEntry('{ nope', 'a.css')).toThrow(/angular\.json/);
  });
});
