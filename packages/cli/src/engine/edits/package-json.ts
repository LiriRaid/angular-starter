import { applyEdits, modify, parse } from 'jsonc-parser';
import type { ParseError } from 'jsonc-parser';

const FORMATTING = { insertSpaces: true, tabSize: 2 } as const;

/**
 * Adds entries to `dependencies`, keeping the section alphabetical like the package managers do.
 * A package the project already declares keeps the version it has.
 */
export function addDependencies(
  text: string,
  dependencies: Readonly<Record<string, string>>,
): string {
  const errors: ParseError[] = [];
  parse(text, errors, { allowTrailingComma: true });
  if (errors.length > 0) throw new Error('The package.json file is not valid JSON.');

  let result = text;
  for (const [name, version] of Object.entries(dependencies)) {
    const current = Object.keys(parse(result)?.dependencies ?? {});
    if (current.includes(name)) continue;
    const index = current.filter((existing) => existing < name).length;
    result = applyEdits(
      result,
      modify(result, ['dependencies', name], version, {
        formattingOptions: FORMATTING,
        getInsertionIndex: () => index,
      }),
    );
  }
  return result;
}
