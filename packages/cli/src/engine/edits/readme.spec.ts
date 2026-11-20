import { describe, expect, it } from 'vitest';
import { GENERATED_END, GENERATED_START, replaceGeneratedBlock } from './readme.js';

const README = `# Title

Text the developer owns.

${GENERATED_START}
old
${GENERATED_END}

More text of the developer.
`;

describe('replaceGeneratedBlock', () => {
  it('replaces what is between the markers and nothing else', () => {
    const text = replaceGeneratedBlock(README, ['- `a`', '- `b`']);
    expect(text).toBe(`# Title

Text the developer owns.

${GENERATED_START}
- \`a\`
- \`b\`
${GENERATED_END}

More text of the developer.
`);
  });

  it('is idempotent', () => {
    const once = replaceGeneratedBlock(README, ['x']);
    expect(replaceGeneratedBlock(once, ['x'])).toBe(once);
  });

  it('leaves a README without the block alone: the developer removed it', () => {
    expect(replaceGeneratedBlock('# Mine\n', ['x'])).toBe('# Mine\n');
  });

  it('keeps the line endings of the file', () => {
    const text = replaceGeneratedBlock(README.replaceAll('\n', '\r\n'), ['x', 'y']);
    expect(text).toContain(`${GENERATED_START}\r\nx\r\ny\r\n${GENERATED_END}`);
    expect(text.replaceAll('\r\n', '')).not.toContain('\n');
  });

  it('writes an empty block as the empty line between the markers', () => {
    expect(replaceGeneratedBlock(README, [])).toContain(`${GENERATED_START}\n${GENERATED_END}`);
  });
});
