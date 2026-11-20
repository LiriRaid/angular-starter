import { describe, expect, it } from 'vitest';
import { DESIGN_STYLE_IMPORTS, addComponentStyles, addDesignStyles } from './styles.js';

const NG_NEW = `/* You can add global styles to this file, and also import other style files */
@import 'tailwindcss';
`;

describe('addDesignStyles', () => {
  it('wires the design files into styles.css the way the reference application does', () => {
    const result = addDesignStyles(NG_NEW);
    const lines = result.split('\n');
    expect(lines[1]).toBe("@import 'tailwindcss';");
    expect(result).toContain('@custom-variant dark (&:where(.dark, .dark *));');
    expect(result).toContain('@layer base, components, legacy-overrides, utilities;');
    for (const file of DESIGN_STYLE_IMPORTS) expect(result).toContain(`@import '${file}';`);
    // @layer comes before the imports it orders, Tailwind CSS first of all.
    expect(result.indexOf('@layer')).toBeLessThan(result.indexOf('theme-styles.css'));
    expect(result.indexOf("'tailwindcss'")).toBeLessThan(result.indexOf('@custom-variant'));
  });

  it('keeps the animations stylesheet of shared/ last', () => {
    const imports = DESIGN_STYLE_IMPORTS;
    expect(imports[0]).toBe('./styles/theme/theme-styles.css');
    expect(imports.at(-1)).toBe('./app/shared/animations/animations.css');
  });

  it('accepts double quotes and no semicolon, as ng new writes them', () => {
    const result = addDesignStyles('@import "tailwindcss"\n');
    expect(result).toContain('@custom-variant dark');
  });

  it('keeps what the developer already wrote after the Tailwind CSS import', () => {
    const result = addDesignStyles(`${NG_NEW}\nbody { margin: 0; }\n`);
    expect(result.endsWith('body { margin: 0; }\n')).toBe(true);
    expect(result.indexOf('animations.css')).toBeLessThan(result.indexOf('body {'));
  });

  it('keeps the CRLF line endings of a Windows stylesheet', () => {
    const crlf = NG_NEW.split('\n').join('\r\n');
    const result = addComponentStyles(addDesignStyles(crlf), ['button-styles']);
    expect(result.split('\r\n').join('')).not.toContain('\n');
    expect(result).toContain('button-styles.css');
  });

  it('adds only the design imports that are missing, without repeating the variant or the layers', () => {
    const partial = `${NG_NEW}\n@custom-variant dark (&:where(.dark, .dark *));\n@layer base, components, legacy-overrides, utilities;\n@import './styles/theme/theme-styles.css';\n`;
    const result = addDesignStyles(partial);
    expect(result.match(/@custom-variant/g)).toHaveLength(1);
    expect(result.match(/@layer base/g)).toHaveLength(1);
    expect(result.match(/theme-styles\.css/g)).toHaveLength(1);
    for (const file of DESIGN_STYLE_IMPORTS) expect(result).toContain(`@import '${file}';`);
  });

  it('does nothing the second time', () => {
    const once = addDesignStyles(NG_NEW);
    expect(addDesignStyles(once)).toBe(once);
  });

  it('refuses a stylesheet that does not import Tailwind CSS', () => {
    expect(() => addDesignStyles('body { margin: 0; }\n')).toThrow(/Tailwind CSS/);
  });
});

describe('addComponentStyles', () => {
  const designed = addDesignStyles(NG_NEW);

  it('imports each component stylesheet before the shared animations', () => {
    const result = addComponentStyles(designed, ['button-styles', 'input-styles']);
    expect(result).toContain("@import './styles/components/button-styles.css';");
    expect(result).toContain("@import './styles/components/input-styles.css';");
    expect(result.indexOf('input-styles.css')).toBeLessThan(result.indexOf('animations.css'));
    expect(result.indexOf('typography-styles.css')).toBeLessThan(result.indexOf('button-styles'));
  });

  it('adds only what is missing, so a bigger collection can follow a smaller one', () => {
    const first = addComponentStyles(designed, ['button-styles']);
    const second = addComponentStyles(first, ['button-styles', 'table-styles']);
    expect(second.match(/button-styles\.css/g)).toHaveLength(1);
    expect(second).toContain('table-styles.css');
    expect(addComponentStyles(second, ['table-styles'])).toBe(second);
  });

  it('refuses a stylesheet without the design base', () => {
    expect(() => addComponentStyles(NG_NEW, ['button-styles'])).toThrow(/design/);
  });
});
