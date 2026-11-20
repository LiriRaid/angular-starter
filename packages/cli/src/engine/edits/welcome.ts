import { Node, SyntaxKind } from 'ts-morph';
import { parseSource, quote, stringProperty } from './typescript.js';

/** A card of the welcome page; `route` opens a page of the application, `docs` names a file. */
export interface WelcomeCardSpec {
  id: string;
  title: string;
  description: string;
  icon: string;
  route?: string;
  href?: string;
  docs?: string;
}

/**
 * Appends a card to the `WELCOME_CARDS` list of the welcome page (`features/home/home.data.ts`),
 * unless a card with the same id is already there.
 */
export function addWelcomeCard(source: string, card: WelcomeCardSpec): string {
  const file = parseSource(source);
  const list = file
    .getVariableDeclaration('WELCOME_CARDS')
    ?.getInitializerIfKind(SyntaxKind.ArrayLiteralExpression);
  if (!list) throw new Error('Could not find the "WELCOME_CARDS" list to add a card to.');

  const exists = list
    .getElements()
    .filter(Node.isObjectLiteralExpression)
    .some((element) => stringProperty(element, 'id') === card.id);
  if (!exists) {
    const properties = [
      `id: ${quote(card.id)}`,
      `title: ${quote(card.title)}`,
      `description: ${quote(card.description)}`,
      `icon: ${quote(card.icon)}`,
      ...(card.route === undefined ? [] : [`route: ${quote(card.route)}`]),
      ...(card.href === undefined ? [] : [`href: ${quote(card.href)}`]),
      ...(card.docs === undefined ? [] : [`docs: ${quote(card.docs)}`]),
    ];
    list.addElement(`{ ${properties.join(', ')} }`, { useNewLines: true });
  }
  return file.getFullText();
}
