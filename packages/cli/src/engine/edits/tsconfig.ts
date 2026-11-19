import { applyEdits, modify, parse } from 'jsonc-parser';
import type { ParseError } from 'jsonc-parser';

const FORMATTING = { insertSpaces: true, tabSize: 2 } as const;

/**
 * Sets `compilerOptions.paths` entries in a tsconfig. The file is JSON with comments, so it is
 * edited with `jsonc-parser`, which leaves comments, ordering and every other option as they are.
 */
export function addPathAliases(text: string, aliases: Readonly<Record<string, string[]>>): string {
  const errors: ParseError[] = [];
  parse(text, errors, { allowTrailingComma: true });
  if (errors.length > 0) throw new Error('The tsconfig file is not valid JSON.');

  let result = text;
  for (const [alias, targets] of Object.entries(aliases)) {
    result = applyEdits(
      result,
      modify(result, ['compilerOptions', 'paths', alias], targets, {
        formattingOptions: FORMATTING,
      }),
    );
  }
  return result;
}
