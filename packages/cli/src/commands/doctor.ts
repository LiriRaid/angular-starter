import {
  ANGULAR_CLI_VERSION,
  SUPPORTED_NODE_RANGE,
  compareVersions,
  isSupportedNode,
} from '../compat.js';
import type { ProgramDeps } from '../deps.js';
import { RuntimeError } from '../errors.js';
import { println, type CliIo } from '../io.js';
import { createStyler } from '../ui/format.js';

const PROBE_TIMEOUT_MS = 15_000;
const PACKAGE_MANAGERS = ['npm', 'pnpm', 'yarn'] as const;

export async function doctorCommand(io: CliIo, deps: ProgramDeps): Promise<void> {
  const style = createStyler(io.color);
  const ok = (text: string): void => println(io.stdout, `${style.green('✓')} ${text}`);
  const warn = (text: string): void => println(io.stdout, `${style.yellow('!')} ${text}`);
  const fail = (text: string): void => println(io.stdout, `${style.red('✗')} ${text}`);
  let failed = false;

  if (isSupportedNode(deps.nodeVersion)) {
    ok(`Node.js v${deps.nodeVersion} (supported: ${SUPPORTED_NODE_RANGE})`);
  } else {
    fail(`Node.js v${deps.nodeVersion} is not supported (requires ${SUPPORTED_NODE_RANGE})`);
    failed = true;
  }

  // The probes are independent and each may wait for a timeout, so they run together.
  const [npx, git, ...managers] = await Promise.all(
    ['npx', 'git', ...PACKAGE_MANAGERS].map((tool) => probe(deps, tool)),
  );

  if (npx) {
    ok(`npx ${npx}`);
  } else {
    fail('npx was not found. It ships with npm and is needed to run the Angular CLI.');
    failed = true;
  }

  PACKAGE_MANAGERS.forEach((manager, index) => {
    const version = managers[index];
    if (version) ok(`${manager} ${version}`);
    else warn(`${manager} not found (optional)`);
  });

  if (git) ok(git);
  else warn('git not found: projects can only be created without a Git repository');

  try {
    const result = await deps.run('npm', ['view', '@angular/cli', 'dist-tags.latest'], {
      timeoutMs: PROBE_TIMEOUT_MS,
    });
    const latest = result.stdout.trim();
    if (compareVersions(latest, ANGULAR_CLI_VERSION) > 0) {
      warn(
        `Angular CLI ${latest} is newer than the version this release is tested with (${ANGULAR_CLI_VERSION}).`,
      );
    } else {
      ok(`Angular CLI ${ANGULAR_CLI_VERSION} is the latest stable release`);
    }
  } catch {
    warn('Could not check the latest Angular CLI release (are you offline?)');
  }

  if (failed) throw new RuntimeError('Some checks failed.');
}

async function probe(deps: ProgramDeps, command: string): Promise<string | undefined> {
  try {
    const result = await deps.run(command, ['--version'], { timeoutMs: PROBE_TIMEOUT_MS });
    return result.stdout.split('\n')[0]?.trim() || undefined;
  } catch {
    return undefined;
  }
}
