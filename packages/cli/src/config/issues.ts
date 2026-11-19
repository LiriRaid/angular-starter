import type { z } from 'zod';

/** One line per validation issue, with the path of the offending option. */
export function formatIssues(error: z.ZodError): string {
  return error.issues
    .map(
      (issue) =>
        `  - ${issue.path.length > 0 ? issue.path.map(String).join('.') : 'config'}: ${issue.message}`,
    )
    .join('\n');
}
