import { join } from 'node:path';
import { blueprintTargets } from './blueprint.js';
import { pathExists } from './fs.js';

export type PlannedAction = 'create' | 'update' | 'remove';

/** A project file (forward slashes) that a command would create, change or delete. */
export interface PlannedFile {
  path: string;
  action: PlannedAction;
}

/**
 * What the steps of a command would do to the files of a project, worked out without writing anything
 * (`--dry-run`). Each step records what it would write, in the order the steps run, and asks what the
 * steps before it left there: a file an earlier step planned to create counts as present, so a project
 * that does not exist yet can be planned too.
 */
export class FilePlan {
  private readonly actions = new Map<string, PlannedAction>();
  private readonly edited = new Set<string>();

  constructor(readonly targetDir: string) {}

  /** Is the file in the project, as it would be after the steps planned so far? */
  async exists(path: string): Promise<boolean> {
    const planned = this.actions.get(path);
    if (planned !== undefined) return planned !== 'remove';
    return pathExists(join(this.targetDir, path));
  }

  /** The step writes the whole file: new when the project does not have it, an overwrite when it does. */
  async write(path: string): Promise<void> {
    const planned = this.actions.get(path);
    if (planned === 'create' || planned === 'update') return;
    const present = planned === 'remove' || (await pathExists(join(this.targetDir, path)));
    this.actions.set(path, present ? 'update' : 'create');
  }

  /** The step changes a file that is there; a file the plan creates stays a created one. */
  async edit(path: string): Promise<void> {
    this.edited.add(path);
    if (!this.actions.has(path)) this.actions.set(path, 'update');
  }

  /** Did a step change the file? A file the plan creates is still as its blueprint has it unless one did. */
  wasEdited(path: string): boolean {
    return this.edited.has(path);
  }

  /** The step deletes a file; one the plan had not created yet and the project lacks is nothing to delete. */
  async remove(path: string): Promise<void> {
    if (this.actions.get(path) === 'create') {
      this.actions.delete(path);
    } else if (await this.exists(path)) {
      this.actions.set(path, 'remove');
    }
  }

  /** Every file of a blueprint folder, as `copyBlueprint` would write it. */
  async blueprint(source: string): Promise<void> {
    for (const path of await blueprintTargets(source)) await this.write(path);
  }

  /** What would change, sorted by path. */
  files(): PlannedFile[] {
    return [...this.actions]
      .map(([path, action]) => ({ path, action }))
      .sort((left, right) => left.path.localeCompare(right.path, 'en'));
  }
}
