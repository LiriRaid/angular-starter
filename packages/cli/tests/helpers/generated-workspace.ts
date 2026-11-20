import { mkdir, writeFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';

/** The files `ng new` (Angular CLI 22.3, zoneless, routing on) writes, reduced to what the engine reads. */
export const GENERATED_FILES: Readonly<Record<string, string>> = {
  'package.json': `{
  "name": "demo",
  "version": "0.0.0",
  "dependencies": {
    "@angular/core": "^22.3.0",
    "rxjs": "~7.8.0"
  }
}
`,
  'angular.json': `{
  "$schema": "./node_modules/@angular/cli/lib/config/schema.json",
  "version": 1,
  "projects": {
    "demo": {
      "projectType": "application",
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
`,
  'src/styles.css': `/* You can add global styles to this file, and also import other style files */

@import 'tailwindcss';
`,
  'tsconfig.json': `/* To learn more about Typescript configuration file: https://www.typescriptlang.org/docs/handbook/tsconfig-json.html. */
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
`,
  'src/main.ts': '\n',
  'src/app/app.ts': `import { Component, signal } from '@angular/core';
import { RouterOutlet } from '@angular/router';

@Component({
  imports: [RouterOutlet],
  selector: 'app-root',
  styleUrl: './app.css',
  templateUrl: './app.html',
})
export class App {
  protected readonly title = signal('demo');
}
`,
  'src/app/app.html': '<h1>Hello, demo</h1>\n',
  'src/app/app.css': '',
  'src/app/app.spec.ts': "describe('App', () => { it('renders Hello, demo', () => {}); });\n",
  'src/app/app.config.ts': `import { ApplicationConfig, provideBrowserGlobalErrorListeners } from '@angular/core';
import { provideRouter } from '@angular/router';
import { routes } from './app.routes';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideRouter(routes)
  ]
};
`,
  'src/app/app.routes.ts': `import { Routes } from '@angular/router';

export const routes: Routes = [];
`,
};

/** Writes the generated workspace into `directory`; `overrides` replaces or (with null) removes files. */
export async function writeGeneratedWorkspace(
  directory: string,
  overrides: Readonly<Record<string, string | null>> = {},
): Promise<void> {
  const files = { ...GENERATED_FILES, ...overrides };
  for (const [file, content] of Object.entries(files)) {
    if (content === null) continue;
    await mkdir(dirname(join(directory, file)), { recursive: true });
    await writeFile(join(directory, file), content);
  }
}
