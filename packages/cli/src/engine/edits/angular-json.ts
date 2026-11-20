import { applyEdits, modify, parse } from 'jsonc-parser';
import type { ParseError } from 'jsonc-parser';

const FORMATTING = { insertSpaces: true, tabSize: 2 } as const;

/**
 * Adds a global stylesheet to the `styles` of the build target of the application, after the ones
 * that are already there. The file is edited as JSON with comments, so the rest of angular.json
 * keeps its formatting; a stylesheet that is already listed is not added twice.
 */
export function addStyleEntry(text: string, entry: string): string {
  const errors: ParseError[] = [];
  const config = parse(text, errors, { allowTrailingComma: true }) as {
    projects?: Record<string, { architect?: { build?: { options?: { styles?: unknown } } } }>;
  };
  if (errors.length > 0) throw new Error('The angular.json file is not valid JSON.');

  const [project, definition] = Object.entries(config.projects ?? {})[0] ?? [];
  const styles = definition?.architect?.build?.options?.styles;
  if (project === undefined || !Array.isArray(styles)) {
    throw new Error('Could not find the "styles" list of the build target in angular.json.');
  }
  if (styles.includes(entry)) return text;

  return applyEdits(
    text,
    modify(text, ['projects', project, 'architect', 'build', 'options', 'styles', -1], entry, {
      formattingOptions: FORMATTING,
      isArrayInsertion: true,
    }),
  );
}
