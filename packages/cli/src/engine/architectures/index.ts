import type { StarterOptions } from '../../config/schema.js';
import type { ArchitectureProfile } from './profile.js';
import { screamingProfile } from './screaming.js';

/** Profiles by architecture id. `angular-default` has none: it keeps what `ng new` generated. */
export const ARCHITECTURE_PROFILES: Readonly<
  Partial<Record<StarterOptions['architecture'], ArchitectureProfile>>
> = {
  screaming: screamingProfile,
};
