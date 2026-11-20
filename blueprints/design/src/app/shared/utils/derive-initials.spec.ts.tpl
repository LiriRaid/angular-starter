import { deriveInitials } from './derive-initials';

describe('deriveInitials', () => {
  it('takes the first letter of the first two words', () => {
    expect(deriveInitials('Ada Lovelace')).toBe('AL');
    expect(deriveInitials('grace brewster murray hopper')).toBe('GB');
  });

  it('takes the first two letters of a single word', () => {
    expect(deriveInitials('Plato')).toBe('PL');
    expect(deriveInitials('x')).toBe('X');
  });

  it('ignores extra spaces and returns an empty string for an empty name', () => {
    expect(deriveInitials('  Ada    Lovelace ')).toBe('AL');
    expect(deriveInitials('   ')).toBe('');
  });
});
