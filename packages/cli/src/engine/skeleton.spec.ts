import { describe, expect, it } from 'vitest';
import { skeletonFiles, ssrFiles } from './skeleton.js';

/** What `ng new` of Angular 22.3 writes with the flags `buildNgCommand` passes (`ng new --dry-run`). */
const CSR_TAILWIND_PNPM = [
  '.editorconfig',
  '.gitignore',
  '.postcssrc.json',
  '.prettierrc',
  '.vscode/extensions.json',
  '.vscode/launch.json',
  '.vscode/tasks.json',
  'README.md',
  'angular.json',
  'package.json',
  'pnpm-workspace.yaml',
  'public/favicon.ico',
  'src/app/app.config.ts',
  'src/app/app.css',
  'src/app/app.html',
  'src/app/app.routes.ts',
  'src/app/app.spec.ts',
  'src/app/app.ts',
  'src/index.html',
  'src/main.ts',
  'src/styles.css',
  'tsconfig.app.json',
  'tsconfig.json',
  'tsconfig.spec.json',
];

const SSR_CSS_NPM = [
  '.editorconfig',
  '.gitignore',
  '.prettierrc',
  '.vscode/extensions.json',
  '.vscode/launch.json',
  '.vscode/tasks.json',
  'README.md',
  'angular.json',
  'package.json',
  'public/favicon.ico',
  'src/app/app.config.server.ts',
  'src/app/app.config.ts',
  'src/app/app.css',
  'src/app/app.html',
  'src/app/app.routes.server.ts',
  'src/app/app.routes.ts',
  'src/app/app.spec.ts',
  'src/app/app.ts',
  'src/index.html',
  'src/main.server.ts',
  'src/main.ts',
  'src/server.ts',
  'src/styles.css',
  'tsconfig.app.json',
  'tsconfig.json',
  'tsconfig.spec.json',
];

describe('skeletonFiles', () => {
  it('is what ng new writes for a client-rendered project with Tailwind and pnpm', () => {
    const files = skeletonFiles({
      style: 'css',
      tailwind: true,
      rendering: 'csr',
      packageManager: 'pnpm',
    });
    expect([...files].sort()).toEqual(CSR_TAILWIND_PNPM);
  });

  it('adds the server files for SSR and drops what only Tailwind and pnpm bring', () => {
    const files = skeletonFiles({
      style: 'css',
      tailwind: false,
      rendering: 'starter-ssr',
      packageManager: 'npm',
    });
    expect([...files].sort()).toEqual(SSR_CSS_NPM);
  });

  it('names the stylesheets after the format of the project', () => {
    const files = skeletonFiles({
      style: 'scss',
      tailwind: false,
      rendering: 'csr',
      packageManager: 'npm',
    });
    expect(files).toContain('src/styles.scss');
    expect(files).toContain('src/app/app.scss');
    expect(files).not.toContain('src/styles.css');
  });
});

describe('ssrFiles', () => {
  it('lists the server files ng add @angular/ssr creates and the configuration it changes', () => {
    const { created, changed } = ssrFiles();
    expect(created).toEqual(
      expect.arrayContaining([
        'src/server.ts',
        'src/main.server.ts',
        'src/app/app.config.server.ts',
      ]),
    );
    expect(changed).toEqual(expect.arrayContaining(['angular.json', 'package.json']));
  });
});
