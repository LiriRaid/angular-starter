import { parse } from 'jsonc-parser';
import { describe, expect, it } from 'vitest';
import { addPathAliases } from './tsconfig.js';

/** tsconfig.json as `ng new` writes it: JSON with comments. */
const TSCONFIG = `/* To learn more about Typescript configuration file: https://www.typescriptlang.org/docs/handbook/tsconfig-json.html. */
/* To learn more about Angular compiler options: https://angular.dev/reference/configs/angular-compiler-options. */
{
  "compileOnSave": false,
  "compilerOptions": {
    "noImplicitOverride": true,
    "module": "preserve"
  },
  "files": [],
  "references": [
    {
      "path": "./tsconfig.app.json"
    }
  ]
}
`;

const ALIASES = {
  '@core/*': ['./src/app/core/*'],
  '@features/*': ['./src/app/features/*'],
  '@shared/*': ['./src/app/shared/*'],
};

describe('addPathAliases', () => {
  it('adds the aliases under compilerOptions.paths', () => {
    const result = addPathAliases(TSCONFIG, ALIASES);
    expect(parse(result).compilerOptions.paths).toEqual(ALIASES);
  });

  it('keeps comments and every other option', () => {
    const result = addPathAliases(TSCONFIG, ALIASES);
    expect(result).toContain('/* To learn more about Typescript configuration file');
    const config = parse(result);
    expect(config.compilerOptions.module).toBe('preserve');
    expect(config.compilerOptions.noImplicitOverride).toBe(true);
    expect(config.references).toEqual([{ path: './tsconfig.app.json' }]);
  });

  it('keeps aliases the project already has and replaces repeated ones', () => {
    const withPaths = addPathAliases(TSCONFIG, {
      '@mine/*': ['./src/mine/*'],
      '@core/*': ['./old/*'],
    });
    const result = addPathAliases(withPaths, ALIASES);
    const { paths } = parse(result).compilerOptions;
    expect(paths['@mine/*']).toEqual(['./src/mine/*']);
    expect(paths['@core/*']).toEqual(['./src/app/core/*']);
  });

  it('is idempotent', () => {
    const once = addPathAliases(TSCONFIG, ALIASES);
    expect(addPathAliases(once, ALIASES)).toBe(once);
  });

  it('fails clearly when the file is not valid JSON', () => {
    expect(() => addPathAliases('{ "compilerOptions": ', ALIASES)).toThrow(/tsconfig/i);
  });
});
