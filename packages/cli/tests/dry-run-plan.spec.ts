import { createHash } from 'node:crypto';
import { mkdtemp, readFile, readdir, rm, stat } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join, relative, sep } from 'node:path';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import type { PlannedFile } from '../src/engine/plan.js';
import { run } from '../src/main.js';
import { createFakeIo } from './helpers/fake-io.js';
import { createFakeRunner } from './helpers/fake-runner.js';
import { skeletonFiles } from '../src/engine/skeleton.js';
import { GENERATED_FILES } from './helpers/generated-workspace.js';
import { SSR_APP_CONFIG, createStarterProject } from './helpers/starter-project.js';

/**
 * The tree of `--dry-run` is a promise about the files. These tests keep it: for each capability the
 * tree is read back and compared with what the same command really creates, changes and deletes. A
 * blueprint or a step that changes without its `plan` fails here, not in a developer's preview.
 */

const SLOW = 180_000;

let cwd: string;

beforeEach(async () => {
  cwd = await mkdtemp(join(tmpdir(), 'sa-plan-'));
});

afterEach(async () => {
  await rm(cwd, { recursive: true, force: true });
});

/** Every file of the project by path, with a hash of its content. */
async function snapshot(root: string): Promise<Map<string, string>> {
  const files = new Map<string, string>();
  const entries = await readdir(root, { recursive: true, withFileTypes: true });
  for (const entry of entries) {
    if (!entry.isFile()) continue;
    const path = relative(root, join(entry.parentPath, entry.name)).split(sep).join('/');
    const text = await readFile(join(root, path));
    files.set(path, createHash('sha1').update(text).digest('hex'));
  }
  return files;
}

const byPath = (left: PlannedFile, right: PlannedFile): number =>
  left.path.localeCompare(right.path, 'en');

/** What changed between two snapshots. */
function difference(before: Map<string, string>, after: Map<string, string>): PlannedFile[] {
  const changes: PlannedFile[] = [];
  for (const [path, hash] of after) {
    if (!before.has(path)) changes.push({ path, action: 'create' });
    else if (before.get(path) !== hash) changes.push({ path, action: 'update' });
  }
  for (const path of before.keys()) {
    if (!after.has(path)) changes.push({ path, action: 'remove' });
  }
  return changes.sort(byPath);
}

/** Reads the files of the tree `--dry-run --verbose` draws back into paths and actions. */
function readTree(out: string): PlannedFile[] {
  const lines = out.split('\n');
  const root = lines.indexOf('What it would write:') + 2;
  const files: PlannedFile[] = [];
  const folders: string[] = [];
  for (const line of lines.slice(root + 1)) {
    if (line === '') break;
    const match = /^((?:│ {3}| {4})*)(?:├── |└── )(?:([+~-]) )?(.+)$/.exec(line);
    if (!match) throw new Error(`Not a line of the tree: "${line}"`);
    const [, indent = '', mark, name = ''] = match;
    folders.length = indent.length / 4;
    if (mark === undefined) {
      folders.push(name.replace(/\/$/, ''));
      continue;
    }
    const action = mark === '+' ? 'create' : mark === '~' ? 'update' : 'remove';
    files.push({ path: [...folders, name].join('/'), action });
  }
  return files.sort(byPath);
}

async function sa(project: string, args: string[]): Promise<{ code: number; out: string }> {
  const fake = createFakeIo({ cwd: project });
  const code = await run(args, fake.io, { run: createFakeRunner().run });
  return { code, out: fake.out() };
}

interface Case {
  name: string;
  flags: readonly string[];
  add: readonly string[];
}

const CASES: readonly Case[] = [
  {
    name: 'icons',
    flags: ['--icons', 'none'],
    add: ['icons', 'lucide'],
  },
  {
    name: 'routing',
    flags: ['--routing', 'angular', '--app-shell', 'none'],
    add: ['routing', 'starter'],
  },
  {
    name: 'components',
    flags: ['--components', 'none', '--icons', 'none', '--app-shell', 'none'],
    add: ['components', 'recommended'],
  },
  {
    name: 'app-shell',
    flags: ['--app-shell', 'none', '--components', 'none', '--icons', 'none'],
    add: ['app-shell'],
  },
  {
    name: 'presence',
    flags: [],
    add: ['presence'],
  },
  {
    name: 'ui-system',
    flags: [],
    add: ['ui-system'],
  },
  {
    name: 'architecture',
    flags: [
      '--architecture',
      'angular-default',
      '--routing',
      'angular',
      '--components',
      'none',
      '--app-shell',
      'none',
      '--icons',
      'none',
    ],
    add: ['architecture', 'screaming'],
  },
];

describe('the tree of --dry-run matches what the command writes', () => {
  for (const { name, flags, add } of CASES) {
    it(
      `sa add ${add.join(' ')}`,
      async () => {
        const project = await createStarterProject(cwd, flags);
        const before = await snapshot(project);

        const preview = await sa(project, [
          'add',
          ...add,
          '--no-install',
          '--dry-run',
          '--verbose',
        ]);
        expect(preview.code, name).toBe(0);
        // A dry run writes nothing.
        expect(difference(before, await snapshot(project))).toEqual([]);
        const promised = readTree(preview.out);

        const real = await sa(project, ['add', ...add, '--no-install']);
        expect(real.code, name).toBe(0);
        const done = difference(before, await snapshot(project));

        expect(promised).toEqual(done);
      },
      SLOW,
    );
  }
});

describe('the tree of sa new --dry-run matches the project it creates', () => {
  const NEW_CASES: readonly { name: string; flags: readonly string[]; ssr?: boolean }[] = [
    { name: 'the defaults', flags: [] },
    {
      name: 'a Screaming project with the shell, presence and the UI System',
      flags: [
        '--architecture',
        'screaming',
        '--app-shell',
        'starter',
        '--presence',
        'starter',
        '--ui-system',
        'starter',
      ],
    },
    { name: 'Starter SSR', flags: ['--rendering', 'starter-ssr'], ssr: true },
    {
      name: 'an Angular default project with nothing added',
      flags: [
        '--architecture',
        'angular-default',
        '--components',
        'none',
        '--app-shell',
        'none',
        '--icons',
        'none',
      ],
    },
  ];

  for (const { name, flags, ssr } of NEW_CASES) {
    it(
      name,
      async () => {
        const files = ssr ? { 'src/app/app.config.ts': SSR_APP_CONFIG } : undefined;
        const create = async (extra: string[]): Promise<string> => {
          const fake = createFakeIo({ cwd });
          const code = await run(
            ['new', 'demo', '--defaults', '--no-install', '--no-git', ...flags, ...extra],
            fake.io,
            { run: createFakeRunner({ files }).run },
          );
          expect(code, fake.err()).toBe(0);
          return fake.out();
        };

        const preview = await create(['--dry-run', '--verbose']);
        const project = join(cwd, 'demo');
        // A dry run creates no folder, not even a temporary one the user could trip on.
        await expect(stat(project)).rejects.toThrow();
        const promised = readTree(preview);

        await create([]);
        const final = await snapshot(project);
        const options = JSON.parse(
          await readFile(join(project, 'starter-angular.config.json'), 'utf8'),
        ).options as Parameters<typeof skeletonFiles>[0];
        const skeleton = new Set(skeletonFiles(options));

        // What the starter adds is all in the tree, and all of it is there.
        const kept = promised.filter((file) => file.action !== 'remove').map((file) => file.path);
        expect(kept.filter((path) => !skeleton.has(path) && !final.has(path))).toEqual([]);
        expect(promised.filter((file) => file.action === 'remove' && final.has(file.path))).toEqual(
          [],
        );
        const promisedPaths = new Set(kept);
        const base = new Set(Object.keys(GENERATED_FILES));
        const unannounced = [...final.keys()].filter(
          (path) => !base.has(path) && !promisedPaths.has(path),
        );
        expect(unannounced).toEqual([]);
      },
      SLOW,
    );
  }
});
