import { ANGULAR_CLI_VERSION } from '../compat.js';
import type { StarterOptions } from '../config/schema.js';

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
