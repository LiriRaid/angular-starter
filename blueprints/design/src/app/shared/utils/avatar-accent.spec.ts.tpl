import { AVATAR_ACCENTS, accentFor } from './avatar-accent';

describe('accentFor', () => {
  it('returns one of the palette colors', () => {
    expect(AVATAR_ACCENTS).toContain(accentFor('Ada Lovelace') as (typeof AVATAR_ACCENTS)[number]);
  });

  it('gives the same seed the same color every time', () => {
    expect(accentFor('user-42')).toBe(accentFor('user-42'));
  });

  it('handles an empty seed', () => {
    expect(AVATAR_ACCENTS).toContain(accentFor('') as (typeof AVATAR_ACCENTS)[number]);
  });
});
