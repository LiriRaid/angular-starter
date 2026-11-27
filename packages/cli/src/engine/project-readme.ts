import { readFile, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { CAPABILITIES, type CapabilityCategory } from '../config/capabilities.js';
import type { StarterOptions } from '../config/schema.js';
import { installedComponentIds } from './components/installed.js';

const README = 'README.md';

/**
 * The part of the README that describes what the project has lives between these two markers
 * (ADR-0024). Generating or adding something rewrites only that block; whatever the developer
 * writes outside of it is never touched.
 */
export const PROJECT_START = '<!-- sa:project -->';
export const PROJECT_END = '<!-- /sa:project -->';

/** The sections `ng new` writes in its README, which the Starter Angular README has no use for. */
const ANGULAR_SECTIONS = new Set([
  'development server',
  'code scaffolding',
  'building',
  'running unit tests',
  'running end-to-end tests',
  'additional resources',
]);

/**
 * True for the README `ng new` writes and nobody has touched: its signature line is there and every
 * heading is one of its own, so a section the developer added makes it theirs.
 */
function isAngularReadme(text: string): boolean {
  if (
    !/This project was generated using \[Angular CLI\]\(https:\/\/github\.com\/angular\/angular-cli\)/.test(
      text,
    )
  ) {
    return false;
  }
  const headings = text
    .split(/\r?\n/)
    .filter((line) => /^#{1,6} /.test(line))
    .slice(1);
  return headings.every((line) =>
    ANGULAR_SECTIONS.has(line.replace(/^#+ /, '').trim().toLowerCase()),
  );
}

const labelOf = (category: CapabilityCategory, id: string): string =>
  CAPABILITIES[category].find((option) => option.id === id)?.label ?? id;

/** What the quality scripts of ADR-0027 do, in the order the README lists them. */
const QUALITY_SCRIPTS: readonly (readonly [script: string, what: string])[] = [
  ['test:watch', 'runs the unit tests and runs them again on every change'],
  ['lint', 'checks the code and the templates with ESLint'],
  ['lint:fix', 'fixes what ESLint can fix'],
  ['format', 'formats the code with Prettier'],
  ['format:check', 'checks that the code is formatted (for CI)'],
];

/** The commands of the project, in the syntax of its package manager; the quality ones only when the project has the script. */
function commandsOf(packageManager: string, scripts: ReadonlySet<string>): string[] {
  const run = (script: string): string =>
    packageManager === 'npm' ? `npm run ${script}` : `${packageManager} ${script}`;
  return [
    `- \`${packageManager} start\`: starts the development server (http://localhost:4200).`,
    `- \`${run('build')}\`: builds the application into \`dist/\`.`,
    `- \`${packageManager} test\`: runs the unit tests (\`sa test\` does the same from the CLI).`,
    ...QUALITY_SCRIPTS.filter(([script]) => scripts.has(script)).map(
      ([script, what]) => `- \`${run(script)}\`: ${what}.`,
    ),
  ];
}

/** The names of the scripts of the project; none when it has no readable package.json. */
async function scriptsOf(targetDir: string): Promise<Set<string>> {
  const text = await readFile(join(targetDir, 'package.json'), 'utf8').catch(() => undefined);
  try {
    const scripts: unknown = text === undefined ? undefined : JSON.parse(text).scripts;
    return new Set(scripts && typeof scripts === 'object' ? Object.keys(scripts) : []);
  } catch {
    return new Set();
  }
}

async function projectBlock(
  targetDir: string,
  options: StarterOptions,
  eol: string,
): Promise<string> {
  const components = await installedComponentIds(targetDir);
  const structured = options.architecture !== 'angular-default';
  const has: string[] = [
    `- **Architecture**: ${labelOf('architecture', options.architecture)}${structured ? ' (`core/`, `features/` and `shared/`, with the `@core`, `@features` and `@shared` aliases)' : ''}.`,
    `- **Routing**: ${labelOf('routing', options.routing)}.`,
    `- **Styles**: ${options.tailwind ? 'Tailwind CSS' : labelOf('style', options.style)}.`,
    `- **Rendering**: ${labelOf('rendering', options.rendering)}.`,
    ...(options.appShell === 'starter'
      ? [
          `- **Application shell**: ${labelOf('appShell', options.appShell)}, with the ${labelOf('layout', options.layout)} layout.`,
        ]
      : []),
    ...(options.presence === 'starter'
      ? [`- **Presence**: ${labelOf('presence', options.presence)}.`]
      : []),
    ...(components.length > 0
      ? [
          `- **Components**: ${components.length} \`sa-\` components in \`src/app/shared/components\` (see its README for the list).`,
        ]
      : []),
    ...(options.uiSystem === 'starter'
      ? [
          '- **UI System**: ' +
            `${labelOf('uiSystem', options.uiSystem)}, the catalog of the components in the UI tab of the design preferences page.`,
        ]
      : []),
    ...(options.icons === 'none' ? [] : [`- **Icons**: ${labelOf('icons', options.icons)}.`]),
  ];
  const commands = [
    ...commandsOf(options.packageManager, await scriptsOf(targetDir)),
    ...(structured
      ? ['- `sa generate feature <name>`: creates a feature in `src/app/features`.']
      : []),
    '- `sa add <capability>`: adds what the project lacks (components, routing, app shell, UI System, icons, presence, rendering, architecture); `sa list` shows the options.',
    '- `sa info`: shows what this project has. `sa doctor`: checks that it is healthy.',
  ];
  return [
    'Generated with [Starter Angular](https://github.com/LiriRaid/starter-angular) on top of the Angular CLI.',
    '',
    '## What this project has',
    '',
    ...has,
    '',
    'The choices are in `starter-angular.config.json`; this section is kept up to date by `sa` as you add pieces, so write your own notes outside the two markers.',
    '',
    '## Commands',
    '',
    ...commands,
  ].join(eol);
}

export interface ProjectReadme {
  targetDir: string;
  /** The project name, as typed by the user. */
  name: string;
  options: StarterOptions;
}

/**
 * Keeps the README of the project describing what it has. A README that still is the one `ng new`
 * writes becomes a Starter Angular one; one that has the block gets only the block rewritten; any
 * other README, or none, is the developer's and is left exactly as it is.
 */
export async function refreshProjectReadme({
  targetDir,
  name,
  options,
}: ProjectReadme): Promise<void> {
  const path = join(targetDir, README);
  const current = await readFile(path, 'utf8').catch(() => undefined);
  // `ng new` always writes one: a project without a README is one whose developer removed it.
  if (current === undefined) return;
  const eol = current.includes('\r\n') ? '\r\n' : '\n';
  const block = `${PROJECT_START}${eol}${await projectBlock(targetDir, options, eol)}${eol}${PROJECT_END}`;

  if (isAngularReadme(current)) {
    await writeFile(path, `# ${name}${eol}${eol}${block}${eol}`);
    return;
  }
  const start = current.indexOf(PROJECT_START);
  const end = current.indexOf(PROJECT_END);
  if (start < 0 || end < start) return;
  const updated = `${current.slice(0, start)}${block}${current.slice(end + PROJECT_END.length)}`;
  if (updated !== current) await writeFile(path, updated);
}
