import { applyEdits, modify, parse } from 'jsonc-parser';
import type { ParseError } from 'jsonc-parser';

const FORMATTING = { insertSpaces: true, tabSize: 2 } as const;

interface TestTarget {
  options?: { setupFiles?: unknown };
}

/**
 * Registers a file in the `setupFiles` of the test target of the application: it runs before every
 * spec, which is where the test environment gets what the application provides at startup. The file
 * is edited as JSON with comments, so the rest of angular.json keeps its formatting; a file that is
 * already listed is not added twice.
 */
export function addTestSetupFile(text: string, file: string): string {
  const errors: ParseError[] = [];
  const config = parse(text, errors, { allowTrailingComma: true }) as {
    projects?: Record<string, { architect?: { test?: TestTarget } }>;
  };
  if (errors.length > 0) throw new Error('The angular.json file is not valid JSON.');

  const [project, definition] = Object.entries(config.projects ?? {})[0] ?? [];
  const test = definition?.architect?.test;
  if (project === undefined || !test) {
    throw new Error('Could not find the "test" target of the application in angular.json.');
  }

  const current = test.options?.setupFiles;
  const files = Array.isArray(current) ? (current as string[]) : [];
  if (files.includes(file)) return text;

  const path = ['projects', project, 'architect', 'test', 'options', 'setupFiles'];
  return applyEdits(
    text,
    modify(text, files.length > 0 ? [...path, -1] : path, files.length > 0 ? file : [file], {
      formattingOptions: FORMATTING,
      isArrayInsertion: files.length > 0,
    }),
  );
}
