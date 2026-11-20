import { describe, expect, it } from 'vitest';
import { addWelcomeCard } from './welcome.js';

const DATA = `import type { WelcomeCard } from './home.types';

export const WELCOME_CARDS: readonly WelcomeCard[] = [
  { id: 'design', title: 'Design', description: 'Tokens.', icon: 'Palette' },
];

export const SOCIAL_LINKS = [];
`;

const CARD = {
  id: 'presence',
  title: 'Presence',
  description: "User's status in real time.",
  icon: 'Users',
  docs: 'docs/presence.md',
};

describe('addWelcomeCard', () => {
  it('appends the card to the list of the welcome page', () => {
    const edited = addWelcomeCard(DATA, CARD);
    expect(edited).toContain("id: 'presence'");
    expect(edited).toContain("title: 'Presence'");
    expect(edited).toContain("description: 'User\\'s status in real time.'");
    expect(edited).toContain("docs: 'docs/presence.md'");
    expect(edited.indexOf("id: 'presence'")).toBeGreaterThan(edited.indexOf("id: 'design'"));
    expect(edited.indexOf("id: 'presence'")).toBeLessThan(edited.indexOf('SOCIAL_LINKS'));
  });

  it('is idempotent', () => {
    const once = addWelcomeCard(DATA, CARD);
    expect(addWelcomeCard(once, CARD)).toBe(once);
  });

  it('fails naming the list when the file does not have it', () => {
    expect(() => addWelcomeCard('export const A = 1;\n', CARD)).toThrow(/WELCOME_CARDS/);
  });
});
