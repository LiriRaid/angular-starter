export interface ArchitectureProject {
  /** The generated Angular workspace. */
  targetDir: string;
  /** The project name, as typed by the user. */
  name: string;
  /** Selector prefix of the generated components. */
  prefix: string;
}

/** What adopting an architecture did to a project that already existed (ADR-0022). */
export interface AdoptionReport {
  /** Files of the project adapted to the architecture, or created for it. */
  adapted: string[];
  /** Files of Angular's welcome page that the architecture no longer uses and that were still as `ng new` left them. */
  removed: string[];
  /** Files the architecture would change that were left as the developer has them, and what to do about each. */
  review: { file: string; reason: string }[];
}

/**
 * What it takes to turn the workspace `ng new` generated into a given architecture: template files
 * from `blueprints/architectures/<id>` plus edits to the generated configuration and source files.
 */
export interface ArchitectureProfile {
  /** Project files (forward slashes) that must exist once the profile has been applied. */
  readonly requiredFiles: readonly string[];
  /** A new project: the whole architecture, with its starting page. */
  apply(project: ArchitectureProject): Promise<void>;
  /**
   * A project that already exists: the structure only, added to what the project has. It creates what
   * is missing, adapts the files of the Angular skeleton that are still as `ng new` leaves them and
   * leaves every other file alone, naming what the developer should review.
   */
  adopt(project: ArchitectureProject): Promise<AdoptionReport>;
}
