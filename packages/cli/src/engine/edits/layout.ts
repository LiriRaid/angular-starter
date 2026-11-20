import { Node, SyntaxKind, Writers } from 'ts-morph';
import {
  addNamedImports,
  componentMetadata,
  layoutChildren,
  parseSource,
  quote,
  routesArray,
  stringProperty,
  type ImportSpec,
} from './typescript.js';

/**
 * Edits that the application shell makes to the files of a project: the layout providers of the root
 * component, the layout route that wraps the routes and the groups of the navigation tree. Every
 * function takes the file's text and returns the new text.
 */

/**
 * Adds `expression` (for example `...provideLayout(TREE)`) to the `providers` of the `@Component` of
 * `className`, with the imports it needs. An expression that is already there is not added twice.
 */
export function addComponentProvider(
  source: string,
  className: string,
  expression: string,
  imports: readonly ImportSpec[],
): string {
  const file = parseSource(source);
  const metadata = componentMetadata(file, className);

  const property = metadata.getProperty('providers')?.asKind(SyntaxKind.PropertyAssignment);
  if (!property) {
    metadata.addPropertyAssignment({ name: 'providers', initializer: `[${expression}]` });
  } else {
    const array = property.getInitializerIfKind(SyntaxKind.ArrayLiteralExpression);
    if (!array) throw new Error(`The providers of "${className}" are not an array literal.`);
    if (!array.getElements().some((element) => element.getText() === expression)) {
      array.addElement(expression);
    }
  }
  for (const spec of imports) addNamedImports(file, spec);
  return file.getFullText();
}

/**
 * Moves every route of the exported `routes` array into the `children` of one route that lazy-loads
 * the layout component `layout.exportName` from `layout.file`. A project that already has a layout
 * route is left alone.
 */
export function wrapRoutesInLayout(
  source: string,
  layout: { file: string; exportName: string },
): string {
  const file = parseSource(source);
  const routes = routesArray(file);
  if (layoutChildren(routes)) return source;

  const children = routes.getElements().map((element) => element.getText());
  for (let index = routes.getElements().length - 1; index >= 0; index--)
    routes.removeElement(index);
  routes.addElement(
    Writers.object({
      path: quote(''),
      loadComponent: `() => import(${quote(layout.file)}).then((m) => m.${layout.exportName})`,
      children: children.length === 0 ? '[]' : `[\n${children.join(',\n')}\n]`,
    }),
    { useNewLines: true },
  );
  file.formatText({ indentSize: 2, convertTabsToSpaces: true });
  return file.getFullText();
}

/** A page of the navigation tree; an entry with `children` only opens them. */
export interface NavigationEntrySpec {
  id: string;
  title: string;
  link?: string;
  icon?: string;
  children?: readonly NavigationEntrySpec[];
}

export interface NavigationGroupSpec {
  label: string;
  items: readonly NavigationEntrySpec[];
}

/** Appends groups to the `APP_NAVIGATION` tree, skipping those whose label is already there. */
export function addNavigationGroups(
  source: string,
  groups: readonly NavigationGroupSpec[],
): string {
  const file = parseSource(source);
  const tree = file
    .getVariableDeclaration('APP_NAVIGATION')
    ?.getInitializerIfKind(SyntaxKind.ArrayLiteralExpression);
  if (!tree) throw new Error('Could not find the "APP_NAVIGATION" tree to add groups to.');

  const labels = tree
    .getElements()
    .filter(Node.isObjectLiteralExpression)
    .map((group) => stringProperty(group, 'label'));
  for (const group of groups) {
    if (labels.includes(group.label)) continue;
    tree.addElement(groupText(group), { useNewLines: true });
  }
  return file.getFullText();
}

const indentation = (level: number): string => '  '.repeat(level);

function groupText(group: NavigationGroupSpec): string {
  const items = group.items.map((item) => entryText(item, 2)).join('\n');
  return `{\n${indentation(1)}label: ${quote(group.label)},\n${indentation(1)}items: [\n${items}\n${indentation(1)}],\n}`;
}

/** One entry on its own line when it is a page, over several lines when it has children. */
function entryText(entry: NavigationEntrySpec, level: number): string {
  const icon = entry.icon === undefined ? '' : ` icon: ${quote(entry.icon)},`;
  const base = `id: ${quote(entry.id)}, title: ${quote(entry.title)},${icon}`;
  if (!entry.children?.length) {
    return `${indentation(level)}{ ${base} type: 'basic', link: ${quote(entry.link ?? '')} },`;
  }
  const children = entry.children.map((child) => entryText(child, level + 2)).join('\n');
  return [
    `${indentation(level)}{`,
    `${indentation(level + 1)}id: ${quote(entry.id)},`,
    `${indentation(level + 1)}title: ${quote(entry.title)},`,
    ...(entry.icon === undefined ? [] : [`${indentation(level + 1)}icon: ${quote(entry.icon)},`]),
    `${indentation(level + 1)}type: 'collapsable',`,
    `${indentation(level + 1)}children: [`,
    children,
    `${indentation(level + 1)}],`,
    `${indentation(level)}},`,
  ].join('\n');
}
