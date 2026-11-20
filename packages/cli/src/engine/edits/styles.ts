/**
 * Edits to the global stylesheet (`src/styles.css`) of a Tailwind CSS project. Like the reference
 * application, the stylesheet is where every design file is imported, so the developer sees (and
 * owns) the whole list. Every function takes the file's text and returns the new text.
 */

/** The design base, in the order the reference application imports it. */
export const DESIGN_STYLE_IMPORTS: readonly string[] = [
  './styles/theme/theme-styles.css',
  './styles/base-elements-styles.css',
  './styles/mixins-styles.css',
  './styles/scrollbar-styles.css',
  './styles/typography/text-and-color-styles.css',
  './styles/typography/typography-styles.css',
  './app/shared/animations/animations.css',
];

const TAILWIND_IMPORT = /^@import\s+(['"])tailwindcss\1\s*;?[ \t]*$/m;
const ANIMATIONS_IMPORT = `@import '${DESIGN_STYLE_IMPORTS.at(-1)}';`;
const COMPONENT_STYLES_FOLDER = './styles/components';

/** The line ending the file already uses, so an edit never mixes them. */
const eolOf = (text: string): string => (text.includes('\r\n') ? '\r\n' : '\n');

/**
 * Adds, right after the Tailwind CSS import: the `dark` variant on the `.dark` class, the cascade
 * layers the component stylesheets rely on, and the design imports. Running it twice changes
 * nothing.
 */
export function addDesignStyles(text: string): string {
  const tailwind = TAILWIND_IMPORT.exec(text);
  if (!tailwind) {
    throw new Error(
      "it does not import Tailwind CSS (@import 'tailwindcss'), which the design needs.",
    );
  }
  const imports = DESIGN_STYLE_IMPORTS.map((file) => `@import '${file}';`).filter(
    (line) => !text.includes(line),
  );
  if (imports.length === 0) return text;
  const eol = eolOf(text);

  // Only what is missing is added, so a stylesheet the developer already edited keeps its own.
  const variant = '@custom-variant dark (&:where(.dark, .dark *));';
  const layers = '@layer base, components, legacy-overrides, utilities;';
  const block = [
    '',
    ...(text.includes('@custom-variant dark') ? [] : [variant, '']),
    ...(text.includes('@layer base, components') ? [] : [layers, '']),
    ...imports,
  ].join(eol);
  const end = tailwind.index + tailwind[0].length;
  return `${text.slice(0, end)}${eol}${block}${text.slice(end)}`;
}

/**
 * Imports the stylesheets of components (`button-styles` is `styles/components/button-styles.css`)
 * that are not imported yet, before the shared animations as in the reference application.
 */
export function addComponentStyles(text: string, names: readonly string[]): string {
  const eol = eolOf(text);
  const lines = text.split(eol);
  const anchor = lines.findIndex((line) => line.trim() === ANIMATIONS_IMPORT);
  if (anchor < 0) {
    throw new Error(
      'it does not import the design base yet; add the design before its components.',
    );
  }
  const missing = names
    .map((name) => `@import '${COMPONENT_STYLES_FOLDER}/${name}.css';`)
    .filter((line) => !text.includes(line));
  if (missing.length === 0) return text;
  lines.splice(anchor, 0, ...missing);
  return lines.join(eol);
}
