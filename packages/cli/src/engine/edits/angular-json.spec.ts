import { describe, expect, it } from 'vitest';
import { addTestSetupFile, raiseInitialBudget } from './angular-json.js';

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
            "browser": "src/main.ts"
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

const setupFiles = (text: string): unknown =>
  JSON.parse(text).projects.demo.architect.test.options?.setupFiles;

describe('addTestSetupFile', () => {
  it('registers a setup file in the options of the test target', () => {
    const result = addTestSetupFile(ANGULAR_JSON, 'src/test-setup.ts');
    expect(setupFiles(result)).toEqual(['src/test-setup.ts']);
  });

  it('keeps the rest of the file as it was', () => {
    const result = addTestSetupFile(ANGULAR_JSON, 'src/test-setup.ts');
    expect(result).toContain('"$schema": "./node_modules/@angular/cli/lib/config/schema.json"');
    expect(JSON.parse(result).projects.demo.architect.test.builder).toBe(
      '@angular/build:unit-test',
    );
  });

  it('appends to the setup files the project already has', () => {
    const withOne = addTestSetupFile(ANGULAR_JSON, 'src/first.ts');
    expect(setupFiles(addTestSetupFile(withOne, 'src/test-setup.ts'))).toEqual([
      'src/first.ts',
      'src/test-setup.ts',
    ]);
  });

  it('does not add the same file twice', () => {
    const once = addTestSetupFile(ANGULAR_JSON, 'src/test-setup.ts');
    expect(addTestSetupFile(once, 'src/test-setup.ts')).toBe(once);
  });

  it('rejects text that is not JSON', () => {
    expect(() => addTestSetupFile('{ nope', 'src/test-setup.ts')).toThrow(/not valid JSON/);
  });

  it('fails when the project has no test target', () => {
    const without = ANGULAR_JSON.replace(/,\s*"test": \{[^}]*\}/, '');
    expect(() => addTestSetupFile(without, 'src/test-setup.ts')).toThrow(/"test" target/);
  });
});

/** The production budgets `ng new` (Angular CLI 22.3) writes. */
const WITH_BUDGETS = `{
  "projects": {
    "demo": {
      "architect": {
        "build": {
          "configurations": {
            "production": {
              "budgets": [
                {
                  "type": "initial",
                  "maximumWarning": "500kB",
                  "maximumError": "1MB"
                },
                {
                  "type": "anyComponentStyle",
                  "maximumWarning": "4kB",
                  "maximumError": "8kB"
                }
              ],
              "outputHashing": "all"
            }
          }
        }
      }
    }
  }
}
`;

const budgets = (text: string): { type: string; maximumWarning: string; maximumError: string }[] =>
  JSON.parse(text).projects.demo.architect.build.configurations.production.budgets;

describe('raiseInitialBudget', () => {
  it('raises the initial bundle budget from the Angular defaults to 1 MB and 2 MB', () => {
    const [initial, style] = budgets(raiseInitialBudget(WITH_BUDGETS));
    expect(initial).toEqual({ type: 'initial', maximumWarning: '1MB', maximumError: '2MB' });
    // The budget of each component stylesheet is not touched: the components are made to fit it.
    expect(style).toEqual({
      type: 'anyComponentStyle',
      maximumWarning: '4kB',
      maximumError: '8kB',
    });
  });

  it('keeps the rest of the file as it was', () => {
    const result = raiseInitialBudget(WITH_BUDGETS);
    expect(result).toContain('"outputHashing": "all"');
    expect(result.replace('"1MB"', '"500kB"').replace('"2MB"', '"1MB"')).toBe(WITH_BUDGETS);
  });

  it('is idempotent', () => {
    const once = raiseInitialBudget(WITH_BUDGETS);
    expect(raiseInitialBudget(once)).toBe(once);
  });

  it('leaves a budget the developer changed alone', () => {
    const changed = WITH_BUDGETS.replace('"500kB"', '"700kB"');
    expect(raiseInitialBudget(changed)).toBe(changed);
    const errorOnly = WITH_BUDGETS.replace('"1MB"', '"3MB"');
    expect(raiseInitialBudget(errorOnly)).toBe(errorOnly);
  });

  it('leaves a file with no initial budget as it is', () => {
    expect(raiseInitialBudget(ANGULAR_JSON)).toBe(ANGULAR_JSON);
    const noInitial = WITH_BUDGETS.replace('"initial"', '"bundle"');
    expect(raiseInitialBudget(noInitial)).toBe(noInitial);
  });

  it('rejects text that is not JSON', () => {
    expect(() => raiseInitialBudget('{ nope')).toThrow(/not valid JSON/);
  });
});
