import type { StarterOptions } from '../config/schema.js';

/** The server files `ng new --ssr` and `ng add @angular/ssr` create. */
const SSR_CREATED = [
  'src/main.server.ts',
  'src/server.ts',
  'src/app/app.config.server.ts',
  'src/app/app.routes.server.ts',
];

/** What `ng add @angular/ssr` changes in a project that exists. */
const SSR_CHANGED = ['angular.json', 'package.json', 'tsconfig.app.json', 'src/app/app.config.ts'];

/** What `ng add @angular/ssr` does to a project, for `sa add rendering`. */
export function ssrFiles(): { created: readonly string[]; changed: readonly string[] } {
  return { created: SSR_CREATED, changed: SSR_CHANGED };
}

/**
 * The files the Angular CLI writes in `ng new` with the flags `buildNgCommand` passes, for the options
 * that change them: the format of the stylesheets, Tailwind's PostCSS file, pnpm's workspace file and
 * the server files of SSR. It is the list of Angular 22.3 (`ANGULAR_CLI_VERSION`); the e2e checks it
 * against a real `ng new --dry-run`, so a new Angular that adds a file fails there and not in a preview.
 */
export function skeletonFiles(
  options: Pick<StarterOptions, 'style' | 'tailwind' | 'rendering' | 'packageManager'>,
): string[] {
  const extension = options.tailwind ? 'css' : options.style;
  return [
    '.editorconfig',
    '.gitignore',
    '.prettierrc',
    ...(options.tailwind ? ['.postcssrc.json'] : []),
    '.vscode/extensions.json',
    '.vscode/launch.json',
    '.vscode/tasks.json',
    'README.md',
    'angular.json',
    'package.json',
    ...(options.packageManager === 'pnpm' ? ['pnpm-workspace.yaml'] : []),
    'public/favicon.ico',
    'src/app/app.config.ts',
    `src/app/app.${extension}`,
    'src/app/app.html',
    'src/app/app.routes.ts',
    'src/app/app.spec.ts',
    'src/app/app.ts',
    'src/index.html',
    'src/main.ts',
    `src/styles.${extension}`,
    'tsconfig.app.json',
    'tsconfig.json',
    'tsconfig.spec.json',
    ...(options.rendering === 'csr' ? [] : SSR_CREATED),
  ];
}
