import type { ArchitectureProject } from '../architectures/profile.js';

export interface RenderingProject extends ArchitectureProject {
  /** The architecture that was applied; some pieces only exist on some architectures. */
  architecture: string;
}

/**
 * What it takes to turn the Angular SSR setup `ng new --ssr` generates into a starter rendering
 * strategy: edits to the generated configuration plus template files from
 * `blueprints/rendering/<id>`, applied after the architecture and the routing.
 */
export interface RenderingProfile {
  /** Project files (forward slashes) that must exist once the profile has been applied. */
  requiredFilesFor(architecture: string): readonly string[];
  apply(project: RenderingProject): Promise<void>;
}
