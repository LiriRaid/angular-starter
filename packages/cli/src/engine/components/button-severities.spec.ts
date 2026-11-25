import { readFile } from 'node:fs/promises';
import { join } from 'node:path';
import { beforeAll, describe, expect, it } from 'vitest';
import { BLUEPRINTS_ROOT } from '../blueprint.js';

/**
 * The severities of `sa-button` (ADR-0025). The stylesheet cannot be rendered here, so these specs read
 * its rules: a severity is a block of custom properties, and what paints it is written once for all of them.
 */
const SEVERITIES = [
  'primary',
  'secondary',
  'success',
  'info',
  'warn',
  'help',
  'danger',
  'contrast',
] as const;
const COLOURED = SEVERITIES.filter((severity) => severity !== 'primary');
const TOKENS = ['--sa-sev', '--sa-sev-hover', '--sa-sev-active', '--sa-sev-on', '--sa-sev-ink'];

interface Rule {
  readonly selector: string;
  readonly body: string;
}

let rules: Rule[];

/** The rules of the stylesheet, flat: the layers and their nesting do not matter to what is checked. */
function parse(css: string): Rule[] {
  const clean = css.replace(/\/\*[\s\S]*?\*\//g, '');
  const found: Rule[] = [];
  for (const match of clean.matchAll(/([^{}]+)\{([^{}]*)\}/g)) {
    found.push({ selector: match[1]!.trim().replace(/\s+/g, ' '), body: match[2]! });
  }
  return found;
}

const declared = (body: string): string[] =>
  body
    .split(';')
    .map((line) => line.split(':')[0]!.trim())
    .filter(Boolean);

const rulesFor = (selector: string): Rule[] => rules.filter((rule) => rule.selector === selector);

beforeAll(async () => {
  const css = await readFile(
    join(BLUEPRINTS_ROOT, 'components/sa-button/src/styles/components/button-styles.css'),
    'utf8',
  );
  rules = parse(css);
});

describe('the severities of the button stylesheet', () => {
  it('gives each severity its own colours as custom properties', () => {
    for (const severity of SEVERITIES) {
      const own = rulesFor(`.sa-btn-${severity}`);
      expect(own, severity).toHaveLength(1);
      expect(declared(own[0]!.body), severity).toEqual(expect.arrayContaining(TOKENS));
    }
  });

  it('takes the colour of primary from the colour the project has chosen, and no other severity does', () => {
    expect(rulesFor('.sa-btn-primary')[0]!.body).toContain('--sa-primary-color');
    for (const severity of COLOURED) {
      const joined = [...rulesFor(`.sa-btn-${severity}`), ...rulesFor(`.dark .sa-btn-${severity}`)]
        .map((rule) => rule.body)
        .join('\n');
      expect(joined, severity).not.toContain('--sa-primary');
    }
  });

  it('has the eight severities of PrimeNG, none of them left to fall back on the primary colour', () => {
    expect(SEVERITIES).toEqual([
      'primary',
      'secondary',
      'success',
      'info',
      'warn',
      'help',
      'danger',
      'contrast',
    ]);
    for (const severity of COLOURED) {
      expect(rulesFor(`.sa-btn-${severity}`)[0]!.body, severity).toMatch(/--sa-sev:\s*var\(--/);
    }
  });

  it('makes the dark theme change only the custom properties of a severity, never paint it', () => {
    const dark = rules.filter((rule) =>
      new RegExp(`^\\.dark \\.sa-btn-(${COLOURED.join('|')})$`).test(rule.selector),
    );
    expect(dark.length).toBeGreaterThan(0);
    for (const rule of dark) {
      for (const property of declared(rule.body)) {
        expect(property, rule.selector).toMatch(/^--/);
      }
    }
  });

  it('keeps the dark ramp of the solid colours equal to the light one, so hover and active darken in both', () => {
    for (const severity of ['success', 'info', 'warn', 'help', 'danger'] as const) {
      const dark = rulesFor(`.dark .sa-btn-${severity}`);
      const declaredInDark = dark.flatMap((rule) => declared(rule.body));
      expect(declaredInDark, severity).not.toContain('--sa-sev');
      expect(declaredInDark, severity).not.toContain('--sa-sev-hover');
      expect(declaredInDark, severity).not.toContain('--sa-sev-active');
    }
  });

  it('paints the filled button from the custom properties, with the primary colour only as the fallback', () => {
    const base = rulesFor('.sa-btn')[0]!.body;
    expect(base).toMatch(/background:\s*var\(--sa-sev,\s*var\(--sa-primary-color\)\)/);
    const hover = rulesFor('.sa-btn:not(:disabled):hover')[0]!.body;
    expect(hover).toMatch(/background:\s*var\(--sa-sev-hover,\s*var\(--sa-primary-hover-color\)\)/);
    const active = rulesFor('.sa-btn:not(:disabled):active')[0]!.body;
    expect(active).toMatch(
      /background:\s*var\(--sa-sev-active,\s*var\(--sa-primary-active-color\)\)/,
    );
  });

  it('has no rule that paints a single severity: what paints them is written once for all', () => {
    const lone = rules.filter(
      (rule) =>
        new RegExp(
          `^(\\.dark )?\\.sa-btn(-(outlined|text))?(\\.sa-btn-(outlined|text))?\\.sa-btn-(${COLOURED.join('|')})(:|$)`,
        ).test(rule.selector) && declared(rule.body).some((property) => !property.startsWith('--')),
    );
    expect(
      lone.map((rule) => rule.selector),
      'a rule of one severity that paints',
    ).toEqual([]);
  });

  describe('outlined and text', () => {
    const generic = (variant: string, state = ''): Rule[] =>
      rules.filter(
        (rule) =>
          rule.selector.startsWith(`.sa-btn.sa-btn-${variant}:is(`) &&
          rule.selector.endsWith(`)${state}`),
      );

    it.each(['outlined', 'text'])(
      'paints %s from the ink of the severity, at rest, on hover and pressed',
      (variant) => {
        for (const state of ['', ':not(:disabled):hover', ':not(:disabled):active']) {
          const found = generic(variant, state);
          expect(found, `${variant}${state}`).toHaveLength(1);
          expect(found[0]!.body, `${variant}${state}`).toContain('--sa-sev-ink');
          expect(found[0]!.body, `${variant}${state}`).not.toContain('--sa-primary');
        }
      },
    );

    it('applies text to every one of the eight severities', () => {
      const selector = generic('text')[0]!.selector;
      for (const severity of SEVERITIES) {
        expect(selector, severity).toContain(`.sa-btn-${severity}`);
      }
    });

    it('applies outlined to every severity but secondary, which keeps the neutral outlined look', () => {
      const selector = generic('outlined')[0]!.selector;
      for (const severity of SEVERITIES.filter((name) => name !== 'secondary')) {
        expect(selector, severity).toContain(`.sa-btn-${severity}`);
      }
      expect(selector).not.toContain('.sa-btn-secondary');
    });

    it('tints the background on hover and pressed with the ink, not with the primary colour', () => {
      for (const variant of ['outlined', 'text']) {
        expect(generic(variant, ':not(:disabled):hover')[0]!.body).toMatch(
          /background:\s*color-mix\(in srgb,\s*var\(--sa-sev-ink\)/,
        );
        expect(generic(variant, ':not(:disabled):active')[0]!.body).toMatch(
          /background:\s*color-mix\(in srgb,\s*var\(--sa-sev-ink\)/,
        );
      }
    });
  });

  it('draws the focus ring of a severity with its own colour', () => {
    const ring = rules.filter(
      (rule) => rule.selector.startsWith('.sa-btn:is(') && rule.selector.endsWith(':focus-visible'),
    );
    expect(ring).toHaveLength(1);
    expect(ring[0]!.body).toContain('--sa-sev-ink');
    for (const severity of SEVERITIES) {
      expect(ring[0]!.selector, severity).toContain(`.sa-btn-${severity}`);
    }
  });

  it('does not force a white text over every filled button, which hid the colour of the severity', () => {
    const forced = rules.filter(
      (rule) =>
        rule.selector.startsWith('.sa-btn:not(.sa-btn-outlined):not(.sa-btn-text)') &&
        /color:\s*var\(--sa-surface-0\)/.test(rule.body),
    );
    expect(forced).toEqual([]);
  });
});
