import { readFile, readdir, writeFile } from 'node:fs/promises';
import { join, relative, sep } from 'node:path';
import { COMPONENT_DESCRIPTIONS } from './components/descriptions.js';
import { replaceGeneratedBlock } from './edits/readme.js';

const COMPONENTS_README = 'src/app/shared/components/README.md';
const COMPONENTS_FOLDER = 'src/app/shared/components';
const STYLES_README = 'src/styles/README.md';
const STYLES_FOLDER = 'src/styles';

/** The folders of `src/styles` in the order the README lists them; the files of the root come first. */
const STYLE_FOLDERS = ['', 'theme', 'typography', 'components', 'features'];

const directories = async (folder: string): Promise<string[]> =>
  (await readdir(folder, { withFileTypes: true }).catch(() => []))
    .filter((entry) => entry.isDirectory())
    .map((entry) => entry.name);

async function componentLines(targetDir: string): Promise<string[]> {
  const found = (await directories(join(targetDir, COMPONENTS_FOLDER)))
    .filter((name) => name.startsWith('sa-'))
    .sort();
  if (found.length === 0) {
    return ['No components have been generated yet. Add them with `sa add components`.'];
  }
  return found.map((name) => {
    const description = COMPONENT_DESCRIPTIONS[name.slice('sa-'.length)];
    return `- \`${name}\`${description === undefined ? '' : `: ${description}`}`;
  });
}

async function styleLines(targetDir: string): Promise<string[]> {
  const entries = await readdir(join(targetDir, STYLES_FOLDER), {
    recursive: true,
    withFileTypes: true,
  }).catch(() => []);
  const files = entries
    .filter((entry) => entry.isFile() && entry.name.endsWith('.css'))
    .map((entry) =>
      relative(join(targetDir, STYLES_FOLDER), join(entry.parentPath, entry.name))
        .split(sep)
        .join('/'),
    );
  const rank = (file: string): number => {
    const folder = file.includes('/') ? file.slice(0, file.indexOf('/')) : '';
    const index = STYLE_FOLDERS.indexOf(folder);
    return index < 0 ? STYLE_FOLDERS.length : index;
  };
  return files
    .sort((a, b) => rank(a) - rank(b) || a.localeCompare(b))
    .map((file) => `- \`${file}\``);
}

async function refresh(targetDir: string, readme: string, lines: string[]): Promise<void> {
  const path = join(targetDir, readme);
  const current = await readFile(path, 'utf8').catch(() => undefined);
  if (current === undefined) return;
  const updated = replaceGeneratedBlock(current, lines);
  if (updated !== current) await writeFile(path, updated);
}

/**
 * Rewrites the generated block of the READMEs that list what the project has (the components, the
 * stylesheets) from the files that are really there. A README that is missing, or whose block the
 * developer removed, is left as it is.
 */
export async function refreshGeneratedReadmes(targetDir: string): Promise<void> {
  await refresh(targetDir, COMPONENTS_README, await componentLines(targetDir));
  await refresh(targetDir, STYLES_README, await styleLines(targetDir));
}
