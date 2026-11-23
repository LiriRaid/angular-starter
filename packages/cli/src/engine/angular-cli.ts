import { join } from 'node:path';
import { ANGULAR_CLI_VERSION } from '../compat.js';
import type { StarterOptions } from '../config/schema.js';
import { pathExists } from './fs.js';

export interface NgCommand {
  command: string;
  args: string[];
}

/**
 * The official `ng new`, pinned to the tested Angular CLI version. Every option the CLI models is
 * passed explicitly so nothing is ever prompted, and installation and Git are left to later stages
 * so they can happen after any change those stages make to the project.
 */
export function buildNgCommand(name: string, options: StarterOptions): NgCommand {
  const style = options.tailwind ? 'tailwind' : options.style;
  return {
    command: 'npx',
    args: [
      '--yes',
      `@angular/cli@${ANGULAR_CLI_VERSION}`,
      'new',
      name,
      '--defaults',
      '--interactive=false',
      '--skip-install',
      '--skip-git',
      '--routing',
      `--style=${style}`,
      options.rendering === 'csr' ? '--ssr=false' : '--ssr',
      '--zoneless',
      '--ai-config=none',
      `--package-manager=${options.packageManager}`,
      `--prefix=${options.prefix}`,
    ],
  };
}

/**
 * The official `ng add @angular/ssr` for a project that exists already. When the project has its own
 * Angular CLI installed it runs that file with node, never the `node_modules/.bin/ng` shim: `ng add`
 * installs packages, pnpm rewrites the shim while it runs, and on Windows cmd.exe reads a batch file
 * as it executes it, so it resumes in the rewritten file and runs the whole command a second time
 * ("A merge conflicted on path /src/server.ts"). Without the CLI installed it downloads the tested one.
 */
export async function buildNgAddSsrCommand(targetDir: string): Promise<NgCommand> {
  const addArgs = ['add', '@angular/ssr', '--skip-confirmation'];
  const cliFolder = join(targetDir, 'node_modules', '@angular', 'cli');
  const localCli = join(cliFolder, 'bin', 'ng.js');
  // Both files: an interrupted install can leave the first without the second.
  if ((await pathExists(localCli)) && (await pathExists(join(cliFolder, 'package.json')))) {
    return { command: process.execPath, args: [localCli, ...addArgs] };
  }
  return { command: 'npx', args: ['--yes', `@angular/cli@${ANGULAR_CLI_VERSION}`, ...addArgs] };
}
