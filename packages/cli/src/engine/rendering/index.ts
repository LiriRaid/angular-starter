import type { StarterOptions } from '../../config/schema.js';
import type { RenderingProfile } from './profile.js';
import { starterSsrProfile } from './starter-ssr.js';

/** Profiles by rendering id. `csr` and `ssr` have none: they keep what `ng new` generated. */
export const RENDERING_PROFILES: Readonly<
  Partial<Record<StarterOptions['rendering'], RenderingProfile>>
> = {
  'starter-ssr': starterSsrProfile,
};
