import { IndentationText, Node, Project, QuoteKind, SyntaxKind, Writers } from 'ts-morph';
import type { ArrayLiteralExpression, ObjectLiteralExpression, SourceFile } from 'ts-morph';

/**
 * Edits to generated TypeScript files. Every function takes the file's text and returns the new
 * text, working on the syntax tree so that formatting and comments the user already has survive and
 * so that a file whose shape is not the expected one fails loudly instead of being half-edited.
 */

export interface RouteSpec {
  path: string;
  pathMatch?: 'full' | 'prefix';
  redirectTo?: string;
  /** Lazy-loads the routes array exported as `exportName` from `file`. */
  lazy?: { file: string; exportName: string };
}

export interface ImportSpec {
  module: string;
  /** Named imports the file must have from `module`. */
  names: readonly string[];
}

const ROUTER_MODULE = '@angular/router';

let project: Project | undefined;

/** One in-memory project is reused: creating it loads the TypeScript compiler. */
export function parseSource(source: string): SourceFile {
  project ??= new Project({
    useInMemoryFileSystem: true,
    skipLoadingLibFiles: true,
    manipulationSettings: {
      quoteKind: QuoteKind.Single,
      indentationText: IndentationText.TwoSpaces,
    },
  });
  return project.createSourceFile('source.ts', source, { overwrite: true });
}

/** Imports `feature` from `@angular/router` and passes `feature()` to `provideRouter(...)`. */
export function addRouterFeature(source: string, feature: string): string {
  return addCallArgument(source, 'provideRouter', `${feature}()`, [
    { module: ROUTER_MODULE, names: [feature] },
  ]);
}

/**
 * Passes `expression` (for example `withEventReplay()`) to the call `callName(...)` and adds the
 * imports it needs. An argument that starts like the expression (same function name) is already
 * there and is left alone.
 */
export function addCallArgument(
  source: string,
  callName: string,
  expression: string,
  imports: readonly ImportSpec[],
): string {
  const file = parseSource(source);
  const call = file
    .getDescendantsOfKind(SyntaxKind.CallExpression)
    .find((candidate) => candidate.getExpression().getText() === callName);
  if (!call) throw new Error(`Could not find a ${callName}(...) call to add ${expression} to.`);

  const head = expression.slice(0, expression.indexOf('(') + 1);
  if (!call.getArguments().some((argument) => argument.getText().startsWith(head))) {
    call.addArgument(expression);
  }
  for (const spec of imports) addNamedImports(file, spec);
  return file.getFullText();
}

/** The object passed to `@Component({ ... })` on `className`. */
export function componentMetadata(file: SourceFile, className: string): ObjectLiteralExpression {
  const declaration = file.getClass(className);
  if (!declaration) throw new Error(`Could not find the class "${className}".`);
  const metadata = declaration
    .getDecorator('Component')
    ?.getArguments()[0]
    ?.asKind(SyntaxKind.ObjectLiteralExpression);
  if (!metadata) throw new Error(`The class "${className}" has no @Component({ ... }) metadata.`);
  return metadata;
}

/** Adds `name` to the `imports` of the `@Component` of `className`, importing it from `module`. */
export function addComponentImport(
  source: string,
  className: string,
  name: string,
  module: string,
): string {
  const file = parseSource(source);
  const metadata = componentMetadata(file, className);

  const array = metadata
    .getProperty('imports')
    ?.asKind(SyntaxKind.PropertyAssignment)
    ?.getInitializerIfKind(SyntaxKind.ArrayLiteralExpression);
  if (!array) {
    metadata.addPropertyAssignment({ name: 'imports', initializer: `[${name}]` });
  } else if (!array.getElements().some((element) => element.getText() === name)) {
    array.addElement(name);
  }
  addNamedImports(file, { module, names: [name] });
  return file.getFullText();
}

/**
 * Gives the component an inline `template` instead of template and style files, and makes it
 * `OnPush`. The files themselves are for the caller to delete.
 */
export function inlineComponentTemplate(
  source: string,
  className: string,
  template: string,
): string {
  const file = parseSource(source);
  const metadata = componentMetadata(file, className);

  for (const name of ['templateUrl', 'styleUrl', 'styleUrls', 'styles']) {
    metadata.getProperty(name)?.remove();
  }
  const current = metadata.getProperty('template')?.asKind(SyntaxKind.PropertyAssignment);
  if (current) current.setInitializer(quote(template));
  else metadata.addPropertyAssignment({ name: 'template', initializer: quote(template) });

  if (!metadata.getProperty('changeDetection')) {
    metadata.addPropertyAssignment({
      name: 'changeDetection',
      initializer: 'ChangeDetectionStrategy.OnPush',
    });
    addNamedImports(file, { module: '@angular/core', names: ['ChangeDetectionStrategy'] });
  }
  return file.getFullText();
}

/**
 * Appends an expression to the `providers` array of the application config, with the imports it
 * needs. An expression that is already there is not added twice.
 */
export function addProvider(
  source: string,
  expression: string,
  imports: readonly ImportSpec[],
): string {
  const file = parseSource(source);
  const array = file
    .getDescendantsOfKind(SyntaxKind.PropertyAssignment)
    .find((property) => property.getName() === 'providers')
    ?.getInitializerIfKind(SyntaxKind.ArrayLiteralExpression);
  if (!array) throw new Error('Could not find the "providers" array to add the provider to.');

  if (!array.getElements().some((element) => element.getText() === expression)) {
    array.addElement(expression, { useNewLines: true });
  }
  for (const spec of imports) addNamedImports(file, spec);
  return file.getFullText();
}

export interface NavigationItemSpec {
  id: string;
  title: string;
  link: string;
  icon?: string;
}

/** Appends a page to the first group of the `APP_NAVIGATION` tree, unless its id is there. */
export function addNavigationItem(source: string, spec: NavigationItemSpec): string {
  const file = parseSource(source);
  const tree = file
    .getVariableDeclaration('APP_NAVIGATION')
    ?.getInitializerIfKind(SyntaxKind.ArrayLiteralExpression);
  const group = tree?.getElements().find(Node.isObjectLiteralExpression);
  const items = group
    ?.getProperty('items')
    ?.asKind(SyntaxKind.PropertyAssignment)
    ?.getInitializerIfKind(SyntaxKind.ArrayLiteralExpression);
  if (!items) {
    throw new Error('Could not find the "APP_NAVIGATION" tree with a group that has "items".');
  }

  const declared = items
    .getElements()
    .filter(Node.isObjectLiteralExpression)
    .some((element) => stringProperty(element, 'id') === spec.id);
  if (!declared) {
    const icon = spec.icon === undefined ? '' : ` icon: ${quote(spec.icon)},`;
    items.addElement(
      `{ id: ${quote(spec.id)}, title: ${quote(spec.title)},${icon} type: 'basic', link: ${quote(spec.link)} }`,
      { useNewLines: true },
    );
  }
  return file.getFullText();
}

/** The exported `routes` array of `app.routes.ts`. */
export function routesArray(file: SourceFile): ArrayLiteralExpression {
  const array = file
    .getVariableDeclaration('routes')
    ?.getInitializerIfKind(SyntaxKind.ArrayLiteralExpression);
  if (!array) throw new Error('Could not find the "routes" array to add routes to.');
  return array;
}

/**
 * The `children` of the layout route: the route that lazy-loads a component of the application
 * shell (`@features/app-shell/layout/...`). The routes of the application live inside it.
 */
export function layoutChildren(routes: ArrayLiteralExpression): ArrayLiteralExpression | undefined {
  return routes
    .getElements()
    .filter(Node.isObjectLiteralExpression)
    .filter((route) =>
      (route.getProperty('loadComponent')?.getText() ?? '').includes('@features/app-shell/layout/'),
    )
    .map((route) =>
      route
        .getProperty('children')
        ?.asKind(SyntaxKind.PropertyAssignment)
        ?.getInitializerIfKind(SyntaxKind.ArrayLiteralExpression),
    )
    .find((children) => children !== undefined);
}

/**
 * Appends routes to the exported `routes` array, skipping those that are already declared. With
 * the application shell they go to the children of its layout route, so the shell wraps them.
 */
export function addRoutes(source: string, routes: readonly RouteSpec[]): string {
  const file = parseSource(source);
  const top = routesArray(file);
  const array = layoutChildren(top) ?? top;

  for (const route of routes) {
    const declared = array
      .getElements()
      .filter(Node.isObjectLiteralExpression)
      .some((element) => isSameRoute(element, route));
    if (!declared) array.addElement(Writers.object(routeProperties(route)), { useNewLines: true });
  }
  return file.getFullText();
}

/** Removes a property from a class, along with the imports that only that property used. */
export function removeClassProperty(
  source: string,
  className: string,
  propertyName: string,
): string {
  const file = parseSource(source);
  const declaration = file.getClass(className);
  if (!declaration) throw new Error(`Could not find the class "${className}".`);

  const property = declaration.getProperty(propertyName);
  if (!property) return source;

  const used = new Set(
    property.getDescendantsOfKind(SyntaxKind.Identifier).map((identifier) => identifier.getText()),
  );
  property.remove();

  for (const name of used) {
    const stillUsed = file
      .getDescendantsOfKind(SyntaxKind.Identifier)
      .some(
        (identifier) =>
          identifier.getText() === name && !Node.isImportSpecifier(identifier.getParent()),
      );
    if (stillUsed) continue;
    for (const importDeclaration of file.getImportDeclarations()) {
      const unused = importDeclaration.getNamedImports().find((named) => named.getName() === name);
      if (!unused) continue;
      unused.remove();
      const empty =
        importDeclaration.getNamedImports().length === 0 &&
        importDeclaration.getDefaultImport() === undefined &&
        importDeclaration.getNamespaceImport() === undefined;
      if (empty) importDeclaration.remove();
    }
  }

  // Nothing is left in the body: write `class A {}` instead of an empty line between the braces.
  if (declaration.getMembers().length === 0) {
    const open = declaration.getFirstChildByKindOrThrow(SyntaxKind.OpenBraceToken);
    const close = declaration.getLastChildByKindOrThrow(SyntaxKind.CloseBraceToken);
    file.replaceText([open.getEnd(), close.getStart()], '');
  }
  return file.getFullText();
}

export function addNamedImports(file: SourceFile, { module, names }: ImportSpec): void {
  const declaration =
    file.getImportDeclaration((candidate) => candidate.getModuleSpecifierValue() === module) ??
    file.addImportDeclaration({ moduleSpecifier: module });
  for (const name of names) {
    if (!declaration.getNamedImports().some((named) => named.getName() === name)) {
      declaration.addNamedImport(name);
    }
  }
}

export function stringProperty(route: ObjectLiteralExpression, name: string): string | undefined {
  const initializer = route
    .getProperty(name)
    ?.asKind(SyntaxKind.PropertyAssignment)
    ?.getInitializer();
  return initializer && Node.isStringLiteral(initializer)
    ? initializer.getLiteralValue()
    : undefined;
}

function isSameRoute(existing: ObjectLiteralExpression, route: RouteSpec): boolean {
  if (stringProperty(existing, 'path') !== route.path) return false;
  return route.lazy
    ? existing.getProperty('loadChildren') !== undefined
    : stringProperty(existing, 'redirectTo') === route.redirectTo;
}

function routeProperties(route: RouteSpec): Record<string, string> {
  const properties: Record<string, string> = { path: quote(route.path) };
  if (route.pathMatch) properties['pathMatch'] = quote(route.pathMatch);
  if (route.redirectTo !== undefined) properties['redirectTo'] = quote(route.redirectTo);
  if (route.lazy) {
    properties['loadChildren'] =
      `() => import(${quote(route.lazy.file)}).then((m) => m.${route.lazy.exportName})`;
  }
  return properties;
}

/** `value` as a single-quoted TypeScript string literal. */
export function quote(value: string): string {
  return `'${value.replaceAll('\\', '\\\\').replaceAll("'", "\\'")}'`;
}
