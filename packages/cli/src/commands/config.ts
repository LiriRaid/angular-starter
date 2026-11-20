import { PROJECT_CONFIG_FILE } from '../config/project-config.js';
import { UsageError } from '../errors.js';
import { println, type CliIo } from '../io.js';
import { findProject } from '../project/find.js';
import { formatRows } from '../ui/format.js';

const READ_ONLY_HINT =
  'The options that shape a project (architecture, stylesheet format, package manager, prefix) are decided by "as new"; "as add" applies the ones that can be added later.';

/** `as config list|get <key>`: reads the options recorded in `angular-starter.config.json`. */
export async function configCommand(
  io: CliIo,
  action: string | undefined,
  key: string | undefined,
): Promise<void> {
  if (action !== 'list' && action !== 'get') {
    throw new UsageError(
      action === undefined
        ? 'Usage: as config <list|get> [key]'
        : `"as config ${action}" does not exist: ${PROJECT_CONFIG_FILE} is read-only.`,
      READ_ONLY_HINT,
    );
  }

  const { options } = await findProject(io.cwd);
  if (action === 'list') {
    for (const line of formatRows(Object.entries(options).map(([k, v]) => [k, String(v)]))) {
      println(io.stdout, line);
    }
    return;
  }

  if (key === undefined) throw new UsageError('Usage: as config get <key>');
  if (!Object.hasOwn(options, key)) {
    throw new UsageError(
      `Unknown option "${key}". Choose one of: ${Object.keys(options).join(', ')}.`,
    );
  }
  println(io.stdout, String(options[key as keyof typeof options]));
}
