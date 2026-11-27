import { applyEdits, modify, parse } from 'jsonc-parser';
import type { ParseError } from 'jsonc-parser';

const FORMATTING = { insertSpaces: true, tabSize: 2 } as const;

type Section = 'dependencies' | 'devDependencies' | 'scripts';

function parseManifest(text: string): void {
  const errors: ParseError[] = [];
  parse(text, errors, { allowTrailingComma: true });
  if (errors.length > 0) throw new Error('The package.json file is not valid JSON.');
}

/**
 * Adds the entries a section does not have yet and keeps the ones it has with the value they have.
 * `sorted` keeps the section alphabetical like the package managers do; without it the entries go at
 * the end, in the order given.
 */
function addEntries(
  text: string,
  section: Section,
  entries: Readonly<Record<string, string>>,
  sorted: boolean,
  declaredIn: readonly Section[] = [section],
): string {
  parseManifest(text);

  let result = text;
  for (const [name, value] of Object.entries(entries)) {
    const manifest = parse(result) ?? {};
    const current = Object.keys(manifest[section] ?? {});
    const declared = declaredIn.some((other) => name in (manifest[other] ?? {}));
    if (declared) continue;
    const index = sorted ? current.filter((existing) => existing < name).length : current.length;
    result = applyEdits(
      result,
      modify(result, [section, name], value, {
        formattingOptions: FORMATTING,
        getInsertionIndex: () => index,
      }),
    );
  }
  return result;
}

/**
 * Adds entries to `dependencies`, keeping the section alphabetical like the package managers do.
 * A package the project already declares keeps the version it has.
 */
export function addDependencies(
  text: string,
  dependencies: Readonly<Record<string, string>>,
): string {
  return addEntries(text, 'dependencies', dependencies, true);
}

/**
 * Adds entries to `devDependencies`, alphabetical. A package the project declares already, in this
 * section or in `dependencies`, keeps the version it has.
 */
export function addDevDependencies(
  text: string,
  dependencies: Readonly<Record<string, string>>,
): string {
  return addEntries(text, 'devDependencies', dependencies, true, [
    'devDependencies',
    'dependencies',
  ]);
}

/** Adds scripts after the ones the project has; a script the project already has is never replaced. */
export function addScripts(text: string, scripts: Readonly<Record<string, string>>): string {
  return addEntries(text, 'scripts', scripts, false);
}
