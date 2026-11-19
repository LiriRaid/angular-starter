export interface ArchitectureProject {
  /** The generated Angular workspace. */
  targetDir: string;
  /** The project name, as typed by the user. */
  name: string;
  /** Selector prefix of the generated components. */
  prefix: string;
}

/**
 * What it takes to turn the workspace `ng new` generated into a given architecture: template files
 * from `blueprints/architectures/<id>` plus edits to the generated configuration and source files.
 */
export interface ArchitectureProfile {
  /** Project files (forward slashes) that must exist once the profile has been applied. */
  readonly requiredFiles: readonly string[];
  apply(project: ArchitectureProject): Promise<void>;
}
