import { styleText } from 'node:util';

type Format = Parameters<typeof styleText>[0];

export interface Styler {
  bold(text: string): string;
  dim(text: string): string;
  green(text: string): string;
  red(text: string): string;
  yellow(text: string): string;
  cyan(text: string): string;
}

export function createStyler(enabled: boolean): Styler {
  const paint =
    (format: Format) =>
    (text: string): string =>
      enabled ? styleText(format, text, { validateStream: false }) : text;
  return {
    bold: paint('bold'),
    dim: paint('dim'),
    green: paint('green'),
    red: paint('red'),
    yellow: paint('yellow'),
    cyan: paint('cyan'),
  };
}

/** Aligns `term  description` rows in two columns. */
export function formatRows(rows: ReadonlyArray<readonly [string, string]>, indent = 2): string[] {
  const width = Math.max(0, ...rows.map(([term]) => term.length));
  return rows.map(([term, description]) =>
    `${' '.repeat(indent)}${term.padEnd(width)}  ${description}`.trimEnd(),
  );
}
