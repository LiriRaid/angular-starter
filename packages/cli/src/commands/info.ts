import { readFile } from 'node:fs/promises';
import { join } from 'node:path';
import { ANGULAR_CLI_VERSION, SUPPORTED_NODE_RANGE, isSupportedNode } from '../compat.js';
import { PROJECT_CONFIG_FILE } from '../config/project-config.js';
import { configFileSchema } from '../config/schema.js';
import type { ProgramDeps } from '../deps.js';
import { println, type CliIo } from '../io.js';
import { formatRows } from '../ui/format.js';
import { CLI_VERSION } from '../version.js';

export async function infoCommand(io: CliIo, deps: ProgramDeps): Promise<void> {
  const node = `v${deps.nodeVersion} (${isSupportedNode(deps.nodeVersion) ? 'supported' : `not supported, requires ${SUPPORTED_NODE_RANGE}`})`;
  println(io.stdout, 'Angular Starter CLI');
  for (const line of formatRows([
    ['CLI version', CLI_VERSION],
    ['Tested Angular CLI', ANGULAR_CLI_VERSION],
    ['Node.js', node],
    ['Platform', `${process.platform} ${process.arch}`],
  ])) {
    println(io.stdout, line);
  }

  const options = await readProjectOptions(io.cwd);
  if (options) {
    println(io.stdout);
    println(io.stdout, `Project configuration (${PROJECT_CONFIG_FILE})`);
    const rows = Object.entries(options).map(([key, value]) => [key, String(value)] as const);
    for (const line of formatRows(rows)) println(io.stdout, line);
  }
}

async function readProjectOptions(cwd: string): Promise<Record<string, unknown> | undefined> {
  try {
    const text = await readFile(join(cwd, PROJECT_CONFIG_FILE), 'utf8');
    const parsed = configFileSchema.safeParse(JSON.parse(text));
    return parsed.success ? parsed.data.options : undefined;
  } catch {
    return undefined;
  }
}
