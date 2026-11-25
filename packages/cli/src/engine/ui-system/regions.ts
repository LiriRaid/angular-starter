/**
 * The UI System is written once, for every component, and generated for the ones a project has
 * (ADR-0024): its templates mark what belongs to a component and `selectRegions` drops the rest.
 *
 * Two forms, in TypeScript (`//`) and in templates (`<!-- -->`):
 *
 *   // uis:begin(modal,button)   ...lines...   // uis:end      a block, kept when every id is installed
 *   SaAvatar, // uis(avatar)                                     one line, kept when its ids are installed
 *
 * An id list is "all of them" (`a,b`); ids joined with a bar are "any of them" (`a|b`).
 */

const BEGIN = /^\s*(?:\/\/|<!--)\s*uis:begin\(([^)]*)\)\s*(?:-->)?\s*$/;
const END = /^\s*(?:\/\/|<!--)\s*uis:end\s*(?:-->)?\s*$/;
const TRAILING = /\s*(?:\/\/|<!--)\s*uis\(([^)]*)\)\s*(?:-->)?\s*$/;

const wanted = (spec: string, installed: ReadonlySet<string>): boolean =>
  spec
    .split(',')
    .map((term) => term.trim())
    .filter(Boolean)
    .every((term) =>
      term
        .split('|')
        .map((id) => id.trim())
        .some((id) => installed.has(id)),
    );

/** The text with the blocks and lines of the components that are not in `installed` removed. */
export function selectRegions(text: string, installed: ReadonlySet<string>): string {
  const eol = text.includes('\r\n') ? '\r\n' : '\n';
  const kept: string[] = [];
  // One entry per open block: whether the lines inside it are kept.
  const open: boolean[] = [];
  const lines = text.split(/\r?\n/);

  lines.forEach((line, index) => {
    const inside = open.every(Boolean);
    const begin = BEGIN.exec(line);
    if (begin) {
      open.push(wanted(begin[1] ?? '', installed));
      return;
    }
    if (END.test(line)) {
      if (open.length === 0) {
        throw new Error(`A "uis:end" closes nothing (line ${index + 1}).`);
      }
      open.pop();
      return;
    }
    if (!inside) return;
    const trailing = TRAILING.exec(line);
    if (!trailing) {
      kept.push(line);
      return;
    }
    if (wanted(trailing[1] ?? '', installed)) kept.push(line.slice(0, trailing.index));
  });

  if (open.length > 0) throw new Error('A "uis:begin" block is never closed.');
  return kept.join(eol);
}
