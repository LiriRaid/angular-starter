import { PREVIEW_ACCENTS } from '@shared/data/accent-palette';

/**
 * Background of avatars without a photo. The color is derived from an id or a name (`accentFor`) so
 * the same person always gets the same one: keep this the single source of truth, or the same
 * person ends up with a different color depending on the screen.
 */
export const AVATAR_ACCENTS = PREVIEW_ACCENTS;

function hashString(value: string): number {
  let hash = 0;
  for (let i = 0; i < value.length; i++) {
    hash = (hash << 5) - hash + value.charCodeAt(i);
    hash |= 0;
  }
  return Math.abs(hash);
}

export function accentFor(seed: string): string {
  return AVATAR_ACCENTS[hashString(seed) % AVATAR_ACCENTS.length];
}
