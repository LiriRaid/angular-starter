import { describe, expect, it } from 'vitest';
import { SUPPORTED_NODE_RANGE, compareVersions, isSupportedNode } from './compat.js';

describe('Node.js range', () => {
  it.each(['../package.json', '../../../package.json'])(
    'matches the engines of %s',
    async (path) => {
      const { readFile } = await import('node:fs/promises');
      const manifest = JSON.parse(await readFile(new URL(path, import.meta.url), 'utf8'));
      expect(manifest.engines.node).toBe(SUPPORTED_NODE_RANGE);
    },
  );
});

describe('compareVersions', () => {
  it.each([
    ['22.3.0', '22.3.0', 0],
    ['22.10.0', '22.3.0', 1],
    ['22.3.0', '22.10.0', -1],
    ['23.0.0', '22.99.99', 1],
    ['22.3.1', '22.3.0', 1],
  ])('%s vs %s -> %i', (a, b, expected) => {
    expect(Math.sign(compareVersions(a, b))).toBe(expected);
  });
});

describe('isSupportedNode', () => {
  it.each([
    ['22.22.3', true],
    ['22.22.2', false],
    ['22.23.0', true],
    ['22.9.0', false],
    ['24.15.0', true],
    ['24.14.9', false],
    ['24.20.1', true],
    ['25.0.0', false],
    ['26.0.0', true],
    ['27.1.0', true],
    ['20.19.0', false],
  ])('%s -> %s', (version, expected) => {
    expect(isSupportedNode(version)).toBe(expected);
  });

  it('rejects malformed versions', () => {
    expect(isSupportedNode('not-a-version')).toBe(false);
  });
});
