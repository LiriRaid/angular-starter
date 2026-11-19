import { IndentationText, Node, Project, QuoteKind, SyntaxKind, Writers } from 'ts-morph';
import type { ObjectLiteralExpression, SourceFile } from 'ts-morph';

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
function parseSource(source: string): SourceFile {
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
  const file = parseSource(source);
  const call = file
    .getDescendantsOfKind(SyntaxKind.CallExpression)
    .find((candidate) => candidate.getExpression().getText() === 'provideRouter');
  if (!call) {
    throw new Error('Could not find a provideRouter(...) call to add the router feature to.');
  }

  if (!call.getArguments().some((argument) => argument.getText().startsWith(`${feature}(`))) {
    call.addArgument(`${feature}()`);
  }

  addNamedImports(file, { module: ROUTER_MODULE, names: [feature] });
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

/** Appends routes to the exported `routes` array, skipping those that are already declared. */
export function addRoutes(source: string, routes: readonly RouteSpec[]): string {
  const file = parseSource(source);
  const array = file
    .getVariableDeclaration('routes')
    ?.getInitializerIfKind(SyntaxKind.ArrayLiteralExpression);
  if (!array) throw new Error('Could not find the "routes" array to add routes to.');

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

function addNamedImports(file: SourceFile, { module, names }: ImportSpec): void {
  const declaration =
    file.getImportDeclaration((candidate) => candidate.getModuleSpecifierValue() === module) ??
    file.addImportDeclaration({ moduleSpecifier: module });
  for (const name of names) {
    if (!declaration.getNamedImports().some((named) => named.getName() === name)) {
      declaration.addNamedImport(name);
    }
  }
}

function stringProperty(route: ObjectLiteralExpression, name: string): string | undefined {
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
