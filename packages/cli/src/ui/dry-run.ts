import { println, type CliIo } from '../io.js';
import { createStyler } from './format.js';
import { renderTree, summarizeEntries, type TreeEntry } from './tree.js';

export interface DryRunPreview {
  /** First line, which says nothing was written: `Dry run: nothing was created.` */
  title: string;
  /** Folder drawn on top of the tree: the project the files belong to. */
  root: string;
  entries: readonly TreeEntry[];
  /** Draw every file, which is what `--verbose` asks for; by default the deep folders are collapsed. */
  verbose?: boolean;
  /** Folders deeper than this are collapsed; commands that touch a few files pass a high one. */
  maxDepth?: number;
}

/**
 * What a command would write, drawn as a tree before anything is: the preview every `--dry-run` shows,
 * so a developer sees the structure that is coming and not only the names of the steps.
 */
export function printDryRun(io: CliIo, preview: DryRunPreview): void {
  const style = createStyler(io.color);
  println(io.stdout, style.bold(preview.title));
  println(io.stdout);
  for (const line of renderTree(preview.entries, {
    root: preview.root,
    color: io.color,
    verbose: preview.verbose,
    maxDepth: preview.maxDepth,
  })) {
    println(io.stdout, line);
  }
  println(io.stdout);
  println(io.stdout, summarizeEntries(preview.entries));
  println(io.stdout, style.dim(`${style.green('+')} created   ${style.yellow('~')} updated`));
}
