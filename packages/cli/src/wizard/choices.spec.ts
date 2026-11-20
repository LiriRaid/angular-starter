import { describe, expect, it } from 'vitest';
import type { CapabilityOption } from '../config/capabilities.js';
import { formatChoices } from './choices.js';

const OPTIONS: readonly CapabilityOption[] = [
  {
    id: 'css',
    label: 'CSS',
    description: 'Plain stylesheets.',
    docs: 'https://developer.mozilla.org/docs/Web/CSS',
    available: true,
  },
  {
    id: 'tailwind',
    label: 'Tailwind CSS',
    description: 'Utility classes.',
    docs: 'https://tailwindcss.com',
    available: true,
    recommended: true,
  },
  { id: 'none', label: 'None', description: 'Nothing is installed.', available: true },
];

describe('formatChoices', () => {
  it('keeps the id as value and the description for the highlighted line', () => {
    const choices = formatChoices(OPTIONS);
    expect(choices.map((choice) => choice.value)).toEqual(['css', 'tailwind', 'none']);
    expect(choices.map((choice) => choice.description)).toEqual([
      'Plain stylesheets.',
      'Utility classes.',
      'Nothing is installed.',
    ]);
  });

  it('marks the recommended option', () => {
    const [, tailwind] = formatChoices(OPTIONS);
    expect(tailwind?.name).toContain('Tailwind CSS (Recommended)');
  });

  it('shows the official documentation in a bracket, like ng new', () => {
    const [css, tailwind] = formatChoices(OPTIONS);
    expect(css?.name).toContain('[ https://developer.mozilla.org/docs/Web/CSS ]');
    expect(tailwind?.name).toMatch(/\[ https:\/\/tailwindcss\.com +\]$/);
  });

  it('aligns the labels and the brackets in columns', () => {
    const named = formatChoices(OPTIONS).filter((choice) => choice.name.includes('['));
    expect(named).toHaveLength(2);
    const opening = named.map((choice) => choice.name.indexOf('['));
    const closing = named.map((choice) => choice.name.lastIndexOf(']'));
    expect(new Set(opening).size).toBe(1);
    expect(new Set(closing).size).toBe(1);
  });

  it('leaves out the bracket of an option with no documentation', () => {
    const none = formatChoices(OPTIONS)[2];
    expect(none?.name).toBe('None');
  });

  it('lets the caller add its own badge', () => {
    const [css] = formatChoices(OPTIONS, (option) => (option.id === 'css' ? 'Default' : undefined));
    expect(css?.name).toContain('CSS (Default)');
  });
});
