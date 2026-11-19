import type { StarterOptions } from '../../config/schema.js';
import type { RoutingProfile } from './profile.js';
import { starterRoutingProfile } from './starter.js';

/** Profiles by routing id. `angular` has none: it keeps the routing `ng new` generated. */
export const ROUTING_PROFILES: Readonly<
  Partial<Record<StarterOptions['routing'], RoutingProfile>>
> = {
  starter: starterRoutingProfile,
};
