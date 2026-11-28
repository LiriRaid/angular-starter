import type { ArchitectureProject } from '../architectures/profile.js';
import type { FilePlan } from '../plan.js';

/**
 * What it takes to add a routing system to the workspace after its architecture has been applied:
 * template files from `blueprints/routing/<id>` plus edits to the generated source files.
 */
export interface RoutingProfile {
  /** Project files (forward slashes) that must exist once the profile has been applied. */
  readonly requiredFiles: readonly string[];
  apply(project: ArchitectureProject): Promise<void>;
  /** The files `apply` would create and change, recorded in `files` without writing anything. */
  plan(files: FilePlan): Promise<void>;
}
