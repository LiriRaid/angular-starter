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

/** What `ng new` gives the initial bundle: a warning at 500 kB and an error at 1 MB. */
const ANGULAR_INITIAL_BUDGET = { warning: '500kB', error: '1MB' } as const;
/** What a project with the shell and the components needs (ADR-0024): a warning at 1 MB, an error at 2 MB. */
const INITIAL_BUDGET = { warning: '1MB', error: '2MB' } as const;

interface Budget {
  type?: string;
  maximumWarning?: string;
  maximumError?: string;
}

/**
 * Raises the budget of the initial bundle of the production build from the values `ng new` writes
 * (500 kB, 1 MB) to 1 MB and 2 MB, which the shell, the components and the design base need. A budget
 * the developer already changed is left as it is, and so is a file with no initial budget, so running it
 * again changes nothing. The edit keeps the rest of angular.json as it was.
 */
export function raiseInitialBudget(text: string): string {
  const errors: ParseError[] = [];
  const config = parse(text, errors, { allowTrailingComma: true }) as {
    projects?: Record<
      string,
      { architect?: { build?: { configurations?: { production?: { budgets?: Budget[] } } } } }
    >;
  };
  if (errors.length > 0) throw new Error('The angular.json file is not valid JSON.');

  const [project, definition] = Object.entries(config.projects ?? {})[0] ?? [];
  const budgets = definition?.architect?.build?.configurations?.production?.budgets;
  const index = budgets?.findIndex((budget) => budget.type === 'initial') ?? -1;
  const initial = budgets?.[index];
  if (
    project === undefined ||
    !initial ||
    initial.maximumWarning !== ANGULAR_INITIAL_BUDGET.warning ||
    initial.maximumError !== ANGULAR_INITIAL_BUDGET.error
  ) {
    return text;
  }

  const path = [
    'projects',
    project,
    'architect',
    'build',
    'configurations',
    'production',
    'budgets',
    index,
  ];
  const once = applyEdits(
    text,
    modify(text, [...path, 'maximumWarning'], INITIAL_BUDGET.warning, {
      formattingOptions: FORMATTING,
    }),
  );
  return applyEdits(
    once,
    modify(once, [...path, 'maximumError'], INITIAL_BUDGET.error, {
      formattingOptions: FORMATTING,
    }),
  );
}
