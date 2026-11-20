import { Project } from 'ts-morph';
import { describe, expect, it } from 'vitest';
import {
  addCallArgument,
  addComponentImport,
  addProvider,
  addRouterFeature,
  addRoutes,
  removeClassProperty,
} from './typescript.js';

/** The files exactly as `ng new` (Angular CLI 22.3) writes them. */
const APP_CONFIG = `import { ApplicationConfig, provideBrowserGlobalErrorListeners } from '@angular/core';
import { provideRouter } from '@angular/router';
import { routes } from './app.routes';

export const appConfig: ApplicationConfig = {
  providers: [
    // Keep this comment.
    provideBrowserGlobalErrorListeners(),
    provideRouter(routes)
  ]
};
`;

const APP_ROUTES = `import { Routes } from '@angular/router';

export const routes: Routes = [];
`;

const APP = `import { Component, signal } from '@angular/core';
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
`;

/** Parses with the TypeScript compiler so a test fails when an edit produces invalid code. */
function syntaxErrors(source: string): number {
  const project = new Project({ useInMemoryFileSystem: true, skipLoadingLibFiles: true });
  const file = project.createSourceFile('check.ts', source);
  return project.getProgram().getSyntacticDiagnostics(file).length;
}

describe('addRouterFeature', () => {
  it('imports the feature and passes it to provideRouter', () => {
    const result = addRouterFeature(APP_CONFIG, 'withComponentInputBinding');
    expect(result).toContain(
      "import { provideRouter, withComponentInputBinding } from '@angular/router';",
    );
    expect(result).toContain('provideRouter(routes, withComponentInputBinding())');
    expect(syntaxErrors(result)).toBe(0);
  });

  it('keeps the rest of the file untouched', () => {
    const result = addRouterFeature(APP_CONFIG, 'withComponentInputBinding');
    expect(result).toContain('// Keep this comment.');
    expect(result).toContain('provideBrowserGlobalErrorListeners(),');
    expect(result).toContain("import { routes } from './app.routes';");
  });

  it('is idempotent', () => {
    const once = addRouterFeature(APP_CONFIG, 'withComponentInputBinding');
    expect(addRouterFeature(once, 'withComponentInputBinding')).toBe(once);
  });

  it('appends after the features the project already has', () => {
    const withFeature = addRouterFeature(APP_CONFIG, 'withHashLocation');
    const result = addRouterFeature(withFeature, 'withComponentInputBinding');
    expect(result).toContain(
      'provideRouter(routes, withHashLocation(), withComponentInputBinding())',
    );
  });

  it('fails clearly when there is no provideRouter call', () => {
    expect(() =>
      addRouterFeature('export const appConfig = { providers: [] };\n', 'withX'),
    ).toThrow(/provideRouter/);
  });
});

describe('addRoutes', () => {
  const routes = [
    { path: '', pathMatch: 'full' as const, redirectTo: 'home' },
    { path: 'home', lazy: { file: '@features/home/home.routes', exportName: 'HOME_ROUTES' } },
  ];

  it('appends a redirect and a lazy feature route to the routes array', () => {
    const result = addRoutes(APP_ROUTES, routes);
    expect(result).toContain("path: ''");
    expect(result).toContain("pathMatch: 'full'");
    expect(result).toContain("redirectTo: 'home'");
    expect(result).toContain("path: 'home'");
    expect(result).toContain(
      "loadChildren: () => import('@features/home/home.routes').then((m) => m.HOME_ROUTES)",
    );
    expect(result).toContain("import { Routes } from '@angular/router';");
    expect(syntaxErrors(result)).toBe(0);
  });

  it('keeps the routes that already exist', () => {
    const existing = `import { Routes } from '@angular/router';

export const routes: Routes = [{ path: 'legacy', redirectTo: 'home' }];
`;
    const result = addRoutes(existing, [routes[1]!]);
    expect(result).toContain("path: 'legacy'");
    expect(result.indexOf("path: 'legacy'")).toBeLessThan(result.indexOf("path: 'home'"));
  });

  it('does not add a route twice', () => {
    const once = addRoutes(APP_ROUTES, routes);
    expect(addRoutes(once, routes)).toBe(once);
  });

  it('fails clearly when there is no routes array', () => {
    expect(() => addRoutes('export const other = 1;\n', routes)).toThrow(/routes/);
  });
});

describe('removeClassProperty', () => {
  it('removes the property and the import that only it used', () => {
    const result = removeClassProperty(APP, 'App', 'title');
    expect(result).not.toContain('title');
    expect(result).toContain("import { Component } from '@angular/core';");
    expect(result).toContain('export class App {}');
    expect(syntaxErrors(result)).toBe(0);
  });

  it('keeps imports that are still used elsewhere', () => {
    const source = APP.replace('}\n', '  readonly other = signal(1);\n}\n');
    const result = removeClassProperty(source, 'App', 'title');
    expect(result).toContain("import { Component, signal } from '@angular/core';");
    expect(result).toContain('other = signal(1)');
  });

  it('leaves the file alone when the property is already gone', () => {
    const once = removeClassProperty(APP, 'App', 'title');
    expect(removeClassProperty(once, 'App', 'title')).toBe(once);
  });

  it('fails clearly when the class does not exist', () => {
    expect(() => removeClassProperty(APP, 'Missing', 'title')).toThrow(/Missing/);
  });
});

describe('addProvider', () => {
  const PROVIDER = "provideNavigation(APP_NAVIGATION, { appName: 'demo' })";
  const IMPORTS = [
    { module: '@core/navigation/navigation.providers', names: ['provideNavigation'] },
    { module: '@features/app-shell/navigation/navigation.data', names: ['APP_NAVIGATION'] },
  ];

  it('appends the provider and imports what it uses', () => {
    const result = addProvider(APP_CONFIG, PROVIDER, IMPORTS);
    expect(result).toContain(PROVIDER);
    expect(result).toContain(
      "import { provideNavigation } from '@core/navigation/navigation.providers';",
    );
    expect(result).toContain(
      "import { APP_NAVIGATION } from '@features/app-shell/navigation/navigation.data';",
    );
    expect(result.indexOf('provideRouter(routes)')).toBeLessThan(result.indexOf(PROVIDER));
    expect(syntaxErrors(result)).toBe(0);
  });

  it('keeps the rest of the file untouched', () => {
    const result = addProvider(APP_CONFIG, PROVIDER, IMPORTS);
    expect(result).toContain('// Keep this comment.');
    expect(result).toContain('provideBrowserGlobalErrorListeners(),');
    expect(result).toContain("import { routes } from './app.routes';");
  });

  it('adds names to an import that already exists', () => {
    const result = addProvider(APP_CONFIG, 'provideX()', [
      { module: '@angular/core', names: ['provideZonelessChangeDetection'] },
    ]);
    expect(result).toContain(
      "import { ApplicationConfig, provideBrowserGlobalErrorListeners, provideZonelessChangeDetection } from '@angular/core';",
    );
  });

  it('is idempotent', () => {
    const once = addProvider(APP_CONFIG, PROVIDER, IMPORTS);
    expect(addProvider(once, PROVIDER, IMPORTS)).toBe(once);
  });

  it('fails clearly when there is no providers array', () => {
    expect(() => addProvider('export const appConfig = {};\n', PROVIDER, IMPORTS)).toThrow(
      /providers/,
    );
  });
});

const SSR_CONFIG = `import { ApplicationConfig, provideBrowserGlobalErrorListeners } from '@angular/core';
import { provideRouter } from '@angular/router';
import { routes } from './app.routes';
import { provideClientHydration } from '@angular/platform-browser';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideRouter(routes), provideClientHydration()
  ]
};
`;

describe('addCallArgument', () => {
  const IMPORT = [{ module: '@angular/platform-browser', names: ['withEventReplay'] }];

  it('passes the expression to the call and imports what it uses', () => {
    const result = addCallArgument(
      SSR_CONFIG,
      'provideClientHydration',
      'withEventReplay()',
      IMPORT,
    );
    expect(result).toContain('provideClientHydration(withEventReplay())');
    expect(result).toContain(
      "import { provideClientHydration, withEventReplay } from '@angular/platform-browser';",
    );
    expect(syntaxErrors(result)).toBe(0);
  });

  it('appends after the arguments that are already there and keeps the rest', () => {
    const once = addCallArgument(SSR_CONFIG, 'provideClientHydration', 'withEventReplay()', IMPORT);
    const twice = addCallArgument(once, 'provideClientHydration', 'withIncrementalHydration()', [
      { module: '@angular/platform-browser', names: ['withIncrementalHydration'] },
    ]);
    expect(twice).toContain(
      'provideClientHydration(withEventReplay(), withIncrementalHydration())',
    );
    expect(twice).toContain('provideBrowserGlobalErrorListeners(),');
  });

  it('accepts arguments for the feature', () => {
    const result = addCallArgument(
      SSR_CONFIG,
      'provideRouter',
      'withViewTransitions({ skipInitialTransition: true })',
      [{ module: '@angular/router', names: ['withViewTransitions'] }],
    );
    expect(result).toContain(
      'provideRouter(routes, withViewTransitions({ skipInitialTransition: true }))',
    );
  });

  it('is idempotent', () => {
    const once = addCallArgument(SSR_CONFIG, 'provideClientHydration', 'withEventReplay()', IMPORT);
    expect(addCallArgument(once, 'provideClientHydration', 'withEventReplay()', IMPORT)).toBe(once);
  });

  it('fails clearly when the call is not there', () => {
    expect(() =>
      addCallArgument(APP_CONFIG, 'provideClientHydration', 'withEventReplay()', []),
    ).toThrow(/provideClientHydration/);
  });
});

describe('addComponentImport', () => {
  it('adds the class to the imports of the component and imports it', () => {
    const result = addComponentImport(APP, 'App', 'HomeDetails', './home-details/home-details');
    expect(result).toContain('imports: [RouterOutlet, HomeDetails]');
    expect(result).toContain("import { HomeDetails } from './home-details/home-details';");
    expect(syntaxErrors(result)).toBe(0);
  });

  it('creates the imports property when the component has none', () => {
    const source =
      "import { Component } from '@angular/core';\n\n@Component({ selector: 'a-b', template: '' })\nexport class AB {}\n";
    const result = addComponentImport(source, 'AB', 'X', './x');
    expect(result).toContain('imports: [X]');
    expect(syntaxErrors(result)).toBe(0);
  });

  it('is idempotent', () => {
    const once = addComponentImport(APP, 'App', 'HomeDetails', './home-details/home-details');
    expect(addComponentImport(once, 'App', 'HomeDetails', './home-details/home-details')).toBe(
      once,
    );
  });

  it('fails clearly when the class is not there', () => {
    expect(() => addComponentImport(APP_ROUTES, 'App', 'X', './x')).toThrow(/App/);
  });
});
